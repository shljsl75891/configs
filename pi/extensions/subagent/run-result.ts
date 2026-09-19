/**
 * Maps a wait outcome to the final RunResult returned to the subagent tool's
 * caller. Extracted so it is testable without tmux or pi's extension runtime:
 * all imports here are type-only except `windowHint`, which is a pure string
 * formatter with no runtime dependency of its own.
 */
import type { AgentConfig } from "./agents.ts";
import type { SubagentResult } from "./result.ts";
import { windowHint } from "./tmux.ts";
import type { WaitOutcome } from "./wait.ts";

// RunResult extends the wire type: output, usage, stopReason, errorMessage are inherited.
// Two extra status values (timeout, aborted) cover outcomes that never reach the child.
export interface RunResult extends Omit<SubagentResult, "status"> {
	agent: string;
	agentSource: AgentConfig["source"] | "unknown";
	task: string;
	windowId?: string;
	status: SubagentResult["status"] | "timeout" | "aborted";
}

/**
 * Maps a wait outcome to a RunResult. The caller handles the `aborted`
 * side-effect (`killTmuxWindow`) and the `finally` block (`rm tmpDir`).
 */
export function toRunResult(
	outcome: WaitOutcome,
	base: { agent: string; agentSource: RunResult["agentSource"]; task: string; windowId: string },
	ctx: { resultFile: string; timeoutMs: number },
): RunResult {
	switch (outcome.kind) {
		case "aborted":
			return { ...base, status: "aborted", output: "", errorMessage: "Aborted." };

		case "windowGone": {
			// Omit windowId: the window is provably dead and the hint would mislead.
			const { windowId: _dead, ...withoutWindow } = base;
			return {
				...withoutWindow,
				status: "error",
				output: "",
				errorMessage: "Subagent exited without writing a result (its tmux window closed). Likely a startup failure - check the agent's model and tools, and that `pi` is on PATH.",
			};
		}

		case "corrupt":
			return { ...base, status: "error", output: "", errorMessage: `Unreadable result file ${ctx.resultFile}: ${outcome.detail}.` };

		case "timeout":
			return { ...base, status: "timeout", output: "", errorMessage: `Timed out after ${ctx.timeoutMs}ms.` };

		case "result": {
			const { status, output, usage, stopReason, errorMessage } = outcome.result;
			return {
				...base,
				status,
				output,
				usage,
				stopReason,
				...(status === "error" && { errorMessage: errorMessage ?? "Agent failed." }),
			};
		}
	}
}

export function formatResult(r: RunResult): string {
	const body = r.status === "ok" ? r.output : (r.errorMessage ?? r.output);
	const sourceTag = r.agentSource === "project" ? " (project)" : "";
	const hint = r.windowId && r.status !== "aborted" ? `\n\n${windowHint(r.windowId)}` : "";
	return `[${r.agent}${sourceTag}] ${r.status}\n\n${body}${hint}`;
}
