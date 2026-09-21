/**
 * Loaded via `pi -e` into every subagent process spawned by ./index.ts, which
 * polls for the result file this writes.
 *
 * Also owns the tmux window name for the child's whole life, since only this
 * process knows whether the agent is working, waiting on the user, or done.
 *
 * With review enabled the result is shown to the user first: they can send it,
 * or reply with a follow-up that goes straight back to the agent — Esc leaves
 * it for the user to take over by hand. The parent stops its clock while the
 * `.review` marker file exists.
 */

import * as fs from "node:fs";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
/**
 * Static, not dynamic: only pi's extension loader can resolve pi-tui for a
 * sibling extension, so an `import()` at runtime would always fail.
 */
import { askQuestions } from "../question-tool/prompt.ts";
import { childDepth, ENV, reviewMarkerFor } from "./protocol.ts";
import type { SubagentResult } from "./result.ts";
import { errorText } from "./errors.ts";
import { formatWindowName, type WindowState } from "./window-name.ts";

const REVIEW_TIMEOUT_MS = 2 * 60 * 1000;
const SEND = "Send as-is";
const FOLLOW_UP_LABEL = "Reply with a follow-up";

type FollowUpContent = { type: "text"; text: string } | { type: "image"; data: string; mimeType: string };

/**
 * What review() decided: deliver the result, forward a follow-up to the
 * agent, or (null) leave it for the user to take over by hand.
 */
type ReviewDecision = { send: SubagentResult } | { followUp: FollowUpContent[] } | null;

async function renameWindow(pi: ExtensionAPI, state: WindowState): Promise<void> {
	const label = process.env[ENV.label];
	const pane = process.env.TMUX_PANE;
	// Without -t tmux renames whatever window the user is looking at, not this one.
	if (!label || !pane) return;
	const depth = childDepth();
	await pi.exec("tmux", ["rename-window", "-t", pane, formatWindowName(state, label, depth)]);
}

function collectResult(ctx: ExtensionContext): SubagentResult {
	const entry = ctx.sessionManager
		.getEntries()
		.findLast((e) => e.type === "message" && e.message.role === "assistant");
	if (!entry || entry.type !== "message") {
		return { status: "error", output: "(no output)", errorMessage: "Agent produced no assistant message." };
	}
	const message = entry.message;
	const output = message.content
		.filter((part): part is { type: "text"; text: string } => part.type === "text")
		.map((part) => part.text)
		.join("\n");
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

async function review(ctx: ExtensionContext, result: SubagentResult): Promise<ReviewDecision> {
	/**
	 * Any stdin byte counts as engagement, including focus/mouse reports — deliberately
	 * lenient: a false positive only costs a longer wait, a false negative steals the
	 * user's half-written edit.
	 */
	const controller = new AbortController();
	const timer = setTimeout(() => controller.abort(), REVIEW_TIMEOUT_MS);
	const unsubscribe = ctx.ui.onTerminalInput(() => {
		clearTimeout(timer);
		return undefined;
	});

	try {
		const choice = await askQuestions(
			ctx.ui,
			[
				{
					question: `${result.status === "ok" ? "Agent finished" : "Agent failed"}. Send this to the caller?`,
					header: "Review",
					options: [{ label: SEND, description: "Report the result above, unchanged." }],
				},
			],
			{ signal: controller.signal, customLabel: FOLLOW_UP_LABEL },
		);

		if (controller.signal.aborted) return { send: result };
		if (!choice) return null; // Esc / dismissed: leave it for the user to take over by hand
		const answer = choice.answers[0]?.[0];
		if (!answer) return null;
		if (answer === SEND) return { send: result };
		const images = choice.images.map(({ data, mimeType }): FollowUpContent => ({ type: "image", data, mimeType }));
		return { followUp: [{ type: "text", text: answer }, ...images] };
	} catch (error) {
		return { send: { ...result, output: `${result.output}\n\n[review UI failed, sent unreviewed: ${errorText(error)}]` } };
	} finally {
		clearTimeout(timer);
		unsubscribe();
	}
}

export default function markerExtension(pi: ExtensionAPI) {
	const resultFile = process.env[ENV.resultFile];
	if (!resultFile) return;
	const reviewFile = reviewMarkerFor(resultFile);
	const reviewEnabled = process.env[ENV.review] === "1";

	/**
	 * pending: no result delivered yet. delivered: the parent has the result and
	 * stopped polling. manual: the user is continuing by hand after delivery.
	 */
	let phase: "pending" | "delivered" | "manual" = "pending";
	/**
	 * Delivery is known broken (e.g. disk full) — stop advertising review, since
	 * pausing the parent's clock for a result that can no longer arrive buys nothing.
	 */
	let deliveryBroken = false;

	const settle = async (result: SubagentResult): Promise<void> => {
		const written = await writeResult(resultFile, result).then(() => true, () => false);
		if (written) phase = "delivered";
		deliveryBroken = !written; // clears on a later successful retry, not just sets on failure
		await renameWindow(pi, written ? (result.status === "ok" ? "ok" : "error") : "unreported");
	};

	pi.on("agent_start", async () => {
		if (phase === "delivered") phase = "manual"; // a manual run reopens the outcome display
		await renameWindow(pi, "running");
	});

	/**
	 * pi emits ui_prompt_start only for extension-raised prompts (ui.select/confirm/
	 * input/editor/custom) — not for the child's own idle editor prompt. So this pauses
	 * the parent's clock for the review prompt and any extension prompt the child raises,
	 * but a child merely sitting idle after a turn does not pause it.
	 */
	pi.on("ui_prompt_start", async () => {
		/**
		 * After delivery the parent is no longer polling this child; keeping the marker
		 * up would reset a clock that belongs to nobody and stall the parent for hours.
		 */
		if (phase === "pending" && !deliveryBroken) await fs.promises.writeFile(reviewFile, "", "utf-8").catch(() => {});
		if (phase === "delivered") return; // terminal outcome wins over the transient prompt state
		await renameWindow(pi, "waiting");
	});

	pi.on("ui_prompt_end", async (_event, ctx) => {
		await fs.promises.rm(reviewFile, { force: true }).catch(() => {});
		if (phase === "delivered") return;
		await renameWindow(pi, ctx.isIdle() ? "waiting" : "running");
	});

	pi.on("agent_settled", async (_event, ctx) => {
		/**
		 * After the first delivery the parent's tool call is complete; further turns
		 * are manual follow-ups in the kept-open window and produce no new result.
		 */
		if (phase !== "pending") { await renameWindow(pi, "waiting"); return; }

		const result = collectResult(ctx);

		// A broken pipe means no answer can reach the caller; retry silently instead of re-asking.
		if (!reviewEnabled || deliveryBroken || ctx.mode !== "tui") {
			await settle(result);
			return;
		}

		/**
		 * review() calls askQuestions, which fires ui_prompt_start/end — those
		 * handlers own the marker file and window rename for the review prompt.
		 */
		const decision = await review(ctx, result);
		if (!decision) {
			await renameWindow(pi, "waiting");
			return;
		}
		if ("followUp" in decision) {
			/* phase stays "pending": the follow-up turn still owes the caller a result,
			   so the next agent_settled runs review() again instead of skipping it. */
			pi.sendUserMessage(decision.followUp);
			return;
		}
		await settle(decision.send);
	});
}
