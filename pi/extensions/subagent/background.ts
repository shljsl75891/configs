/**
 * Lets a running subagent call hand individual runs over to the background:
 * the tool call returns without them, and each one reports back on its own.
 * Pure logic so it is testable without tmux or pi's runtime.
 */
import type { RunResult } from "./run-result.ts";

export interface Detach {
	readonly detached: boolean;
	/** Resolves once the run moved to the background. */
	readonly whenDetached: Promise<void>;
}

export interface RunHandle {
	readonly agent: string;
	readonly task: string;
	readonly detach: Detach;
	/** The real outcome, even after the run moved to the background. */
	readonly done: Promise<RunResult>;
	readonly finished: boolean;
	/** Returns false when the run already ended, so there is nothing to move. */
	moveToBackground(): boolean;
}

/**
 * `start` gets the Detach so the run can stop following the caller's abort signal.
 * `onBackgroundResult` fires once, only for runs that moved to the background.
 */
export function createRunHandle(
	agent: string,
	task: string,
	start: (detach: Detach) => Promise<RunResult>,
	onBackgroundResult: (result: RunResult) => void,
): RunHandle {
	let detached = false;
	let finished = false;
	let resolveDetached!: () => void;
	const whenDetached = new Promise<void>((resolve) => (resolveDetached = resolve));
	const detach: Detach = {
		get detached() {
			return detached;
		},
		whenDetached,
	};
	const done = start(detach).finally(() => {
		finished = true;
	});
	return {
		agent,
		task,
		detach,
		done,
		get finished() {
			return finished;
		},
		moveToBackground() {
			if (finished || detached) return false;
			detached = true;
			resolveDetached();
			void done.then(onBackgroundResult).catch(() => {});
			return true;
		},
	};
}

export const isActive = (h: RunHandle): boolean => !h.finished && !h.detach.detached;

/** Settles when the run ends or moves to the background, whichever comes first. */
export function awaitForeground(h: RunHandle): Promise<RunResult> {
	const placeholder = (): RunResult => ({
		agent: h.agent,
		agentSource: "unknown",
		task: h.task,
		status: "backgrounded",
		output: "",
	});
	return Promise.race([h.done, h.detach.whenDetached.then(placeholder)]);
}
