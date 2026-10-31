/**
 * Loaded via `pi -e` into every subagent process spawned by ./index.ts, which
 * polls for the result file this writes.
 *
 * Also owns the tmux window name for the child's whole life, since only this
 * process knows whether the agent is working, waiting on the user, or done.
 *
 * The result goes to the parent as soon as the agent settles. While the child
 * waits on a prompt (for example the question tool), the parent stops its clock
 * as long as the `.review` marker file exists.
 */

import * as fs from "node:fs";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { AssistantMessage, UserMessage } from "@earendil-works/pi-ai";
/**
 * Static, not dynamic: only pi's extension loader can resolve pi-tui for a
 * sibling extension, so an `import()` at runtime would always fail.
 */
import { childDepth, ENV, heartbeatFor, reviewMarkerFor } from "./protocol.ts";
import type { SubagentResult } from "./result.ts";
import { formatWindowName, type WindowState } from "./window-name.ts";

const HEARTBEAT_EVERY_MS = 5_000;

type AssistantOrUser = AssistantMessage | UserMessage;

async function renameWindow(pi: ExtensionAPI, state: WindowState): Promise<void> {
	const label = process.env[ENV.label];
	const pane = process.env.TMUX_PANE;
	// Without -t tmux renames whatever window the user is looking at, not this one.
	if (!label || !pane) return;
	const depth = childDepth();
	await pi.exec("tmux", ["rename-window", "-t", pane, formatWindowName(state, label, depth)]);
}

const SEGMENT_SEPARATOR = "\n\n--- after user input ---\n\n";

function textOf(content: readonly { type: string }[]): string {
	return content
		.filter((part): part is { type: "text"; text: string } => part.type === "text")
		.map((part) => part.text)
		.join("\n");
}

/**
 * The user may answer a question or send a follow-up after the findings were
 * shown, so the last message alone can hold only the changes. Keep the text the
 * user saw as output: messages that asked a question, the last message before
 * each follow-up, and the final message.
 */
function collectOutput(messages: readonly AssistantOrUser[], final: AssistantMessage): string {
	const kept: AssistantMessage[] = [];
	const keep = (m: AssistantMessage): void => {
		if (kept.at(-1) !== m) kept.push(m);
	};
	let lastWithText: AssistantMessage | undefined;
	let seenTask = false;
	for (const message of messages) {
		if (message.role === "assistant") {
			if (!textOf(message.content)) continue;
			lastWithText = message;
			if (message.content.some((part) => part.type === "toolCall" && part.name === "question")) keep(message);
		} else {
			if (seenTask && lastWithText) keep(lastWithText);
			seenTask = true;
		}
	}
	keep(final);
	return kept.map((m) => textOf(m.content)).filter(Boolean).join(SEGMENT_SEPARATOR);
}

function collectResult(ctx: ExtensionContext): SubagentResult {
	const messages = ctx.sessionManager
		.getEntries()
		.flatMap((e) => (e.type === "message" && (e.message.role === "assistant" || e.message.role === "user") ? [e.message] : []));
	const message = messages.findLast((m): m is AssistantMessage => m.role === "assistant");
	if (!message) {
		return { status: "error", output: "(no output)", errorMessage: "Agent produced no assistant message." };
	}
	const output = collectOutput(messages, message);
	const isError = Boolean(message.errorMessage) || message.stopReason === "error" || message.stopReason === "aborted";
	return {
		status: isError ? "error" : "ok",
		output: output || "(no output)",
		usage: message.usage,
		stopReason: message.stopReason,
		errorMessage: message.errorMessage,
	};
}

async function writeResult(resultFile: string, result: SubagentResult): Promise<void> {
	/**
	 * tmp + rename so the poller never reads a torn file. The directory is
	 * orchestrator-owned, so a missing one means nobody is reading anymore.
	 */
	const tmpPath = `${resultFile}.tmp`;
	await fs.promises.writeFile(tmpPath, JSON.stringify(result), "utf-8");
	await fs.promises.rename(tmpPath, resultFile);
}

export default function markerExtension(pi: ExtensionAPI) {
	const resultFile = process.env[ENV.resultFile];
	if (!resultFile) return;
	const reviewFile = reviewMarkerFor(resultFile);

	/**
	 * Limits only the active set, not the registry: --tools would also drop the
	 * mcp__* tools, so Alt+M could never turn a server on. codemode stays active
	 * because it is the only way to call MCP tools. subagent stays active so any
	 * agent can nest; at the depth cap the tool is unregistered and pi ignores the name.
	 */
	const tools = process.env[ENV.tools];
	if (tools) {
		pi.on("session_start", () => {
			pi.setActiveTools([...tools.split(","), "codemode", "subagent"]);
		});
	}

	/** Throttled touch so a long but active run is not mistaken for a stuck one. */
	const heartbeatFile = heartbeatFor(resultFile);
	let lastBeat = 0;
	const beat = (): void => {
		const now = Date.now();
		if (now - HEARTBEAT_EVERY_MS < lastBeat) return;
		lastBeat = now;
		void fs.promises.writeFile(heartbeatFile, String(now), "utf-8").catch(() => {});
	};
	for (const event of ["turn_start", "turn_end", "tool_execution_start", "tool_execution_end", "message_update"] as const) {
		pi.on(event, () => { beat(); });
	}

	/** The parent has the result and stopped polling; an ok result's window is about to close. */
	let delivered = false;
	/**
	 * Delivery is known broken (e.g. disk full) — stop writing the prompt marker, since
	 * pausing the parent's clock for a result that can no longer arrive buys nothing.
	 */
	let deliveryBroken = false;

	const settle = async (result: SubagentResult): Promise<void> => {
		const written = await writeResult(resultFile, result).then(() => true, () => false);
		if (written) delivered = true;
		deliveryBroken = !written; // clears on a later successful retry, not just sets on failure
		await renameWindow(pi, written ? (result.status === "ok" ? "ok" : "error") : "unreported");
	};

	pi.on("agent_start", async () => {
		await renameWindow(pi, "running");
	});

	/**
	 * pi emits ui_prompt_start only for extension-raised prompts (ui.select/confirm/
	 * input/editor/custom) — not for the child's own idle editor prompt. So this pauses
	 * the parent's clock for any extension prompt the child raises,
	 * but a child merely sitting idle after a turn does not pause it.
	 */
	pi.on("ui_prompt_start", async () => {
		/**
		 * After delivery the parent is no longer polling this child; keeping the marker
		 * up would reset a clock that belongs to nobody and stall the parent for hours.
		 */
		if (!delivered && !deliveryBroken) await fs.promises.writeFile(reviewFile, "", "utf-8").catch(() => {});
		if (delivered) return; // terminal outcome wins over the transient prompt state
		await renameWindow(pi, "waiting");
	});

	pi.on("ui_prompt_end", async (_event, ctx) => {
		await fs.promises.rm(reviewFile, { force: true }).catch(() => {});
		if (delivered) return;
		await renameWindow(pi, ctx.isIdle() ? "waiting" : "running");
	});

	pi.on("agent_settled", async (_event, ctx) => {
		/**
		 * After the first delivery the parent's tool call is complete; further turns
		 * are manual follow-ups in the kept-open window and produce no new result.
		 */
		if (delivered) { await renameWindow(pi, "waiting"); return; }

		await settle(collectResult(ctx));
	});
}
