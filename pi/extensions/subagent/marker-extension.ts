/**
 * Loaded via `pi -e` into every subagent process spawned by ./index.ts, which
 * polls for the result file this writes.
 *
 * Also owns the tmux window name for the child's whole life, since only this
 * process knows whether the agent is working, waiting on the user, or done.
 *
 * With review enabled the result is shown to the user first: they can send it,
 * replace its text, or send the agent back to work. The parent stops its clock
 * while the `.review` marker file exists.
 */

import * as fs from "node:fs";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
// Static, not dynamic: only pi's extension loader can resolve pi-tui for a
// sibling extension, so an `import()` at runtime would always fail.
import { askQuestions } from "../question-tool/prompt.ts";

const REVIEW_TIMEOUT_MS = 2 * 60 * 1000;
const SEND = "Send as-is";
const KEEP_WORKING = "Keep working";

interface Result {
	status: "ok" | "error";
	output: string;
	usage?: unknown;
	stopReason?: string;
	errorMessage?: string;
}

async function renameWindow(pi: ExtensionAPI, marker: string): Promise<void> {
	const label = process.env.PI_SUBAGENT_LABEL;
	const pane = process.env.TMUX_PANE;
	// Without -t tmux renames whatever window the user is looking at, not this one.
	if (!label || !pane) return;
	const depth = Number(process.env.PI_SUBAGENT_DEPTH) || 0;
	const prefix = depth >= 2 ? `L${depth} ` : "";
	await pi.exec("tmux", ["rename-window", "-t", pane, `${prefix}${marker} ${label}`]).catch(() => {});
}

function collectResult(ctx: ExtensionContext): Result {
	for (const entry of [...ctx.sessionManager.getEntries()].reverse()) {
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;
		const message = entry.message;
		const output = message.content
			.filter((part): part is { type: "text"; text: string } => part.type === "text")
			.map((part) => part.text)
			.join("\n");
		const isError =
			Boolean(message.errorMessage) || message.stopReason === "error" || message.stopReason === "aborted";
		return {
			status: isError ? "error" : "ok",
			output: output || "(no output)",
			usage: message.usage,
			stopReason: message.stopReason,
			errorMessage: message.errorMessage,
		};
	}
	return { status: "error", output: "(no output)", errorMessage: "Agent produced no assistant message." };
}

async function writeResult(resultFile: string, result: Result): Promise<void> {
	// tmp + rename so the poller never reads a torn file. The directory is
	// orchestrator-owned, so a missing one means nobody is reading anymore.
	const tmpPath = `${resultFile}.tmp`;
	await fs.promises.writeFile(tmpPath, JSON.stringify(result), "utf-8");
	await fs.promises.rename(tmpPath, resultFile);
}

/** Resolves to the result to send, or null to keep the agent working. */
async function review(ctx: ExtensionContext, result: Result): Promise<Result | null> {
	// Only an untouched prompt times out; once the user engages, their editing
	// time is their own.
	const controller = new AbortController();
	const timer = setTimeout(() => controller.abort(), REVIEW_TIMEOUT_MS);
	let touched = false;
	const stopTimer = () => {
		if (touched) return;
		touched = true;
		clearTimeout(timer);
	};
	const unsubscribe = ctx.ui.onTerminalInput(() => {
		stopTimer();
		return undefined;
	});

	try {
		const answers = await askQuestions(
			ctx.ui,
			[
				{
					question: `${result.status === "ok" ? "Agent finished" : "Agent failed"}. Send this to the caller?\n\n${result.output}`,
					header: "Review",
					options: [
						{ label: SEND, description: "Report the result above, unchanged." },
						{ label: KEEP_WORKING, description: "Report nothing yet and keep talking to the agent." },
					],
				},
			],
			{ signal: controller.signal },
		);

		const answer = answers?.[0]?.[0];
		if (controller.signal.aborted) return result;
		if (!answer || answer === KEEP_WORKING) return null;
		if (answer === SEND) return result;
		return { ...result, output: answer };
	} catch {
		return result;
	} finally {
		clearTimeout(timer);
		unsubscribe();
	}
}

export default function markerExtension(pi: ExtensionAPI) {
	const resultFile = process.env.PI_SUBAGENT_RESULT_FILE;
	if (!resultFile) return;
	const reviewFile = `${resultFile}.review`;
	const reviewEnabled = process.env.PI_SUBAGENT_REVIEW === "1";

	pi.on("agent_start", async () => {
		await renameWindow(pi, "⋯");
	});

	pi.on("ui_prompt_start", async () => {
		await renameWindow(pi, "!");
	});

	pi.on("ui_prompt_end", async (_event, ctx) => {
		await renameWindow(pi, ctx.isIdle() ? "!" : "⋯");
	});

	pi.on("agent_settled", async (_event, ctx) => {
		const result = collectResult(ctx);

		if (!reviewEnabled || ctx.mode !== "tui") {
			await renameWindow(pi, result.status === "ok" ? "✓" : "✗");
			await writeResult(resultFile, result).catch(() => {});
			return;
		}

		await fs.promises.writeFile(reviewFile, "", "utf-8").catch(() => {});
		const approved = await review(ctx, result);
		await fs.promises.rm(reviewFile, { force: true }).catch(() => {});

		if (!approved) {
			await renameWindow(pi, "!");
			return;
		}
		await renameWindow(pi, approved.status === "ok" ? "✓" : "✗");
		await writeResult(resultFile, approved).catch(() => {});
	});
}
