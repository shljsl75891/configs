/**
 * Single owner of the tmux window-name format used by both the orchestrator
 * (index.ts) and the child process (marker-extension.ts). Changing the naming
 * scheme here updates both sides simultaneously.
 */

export type WindowState = "running" | "waiting" | "ok" | "error" | "unreported";

/** tmux window-name length budget; also used in tests to assert no truncation bugs. */
export const MAX_WINDOW_NAME_LENGTH = 30;

const MARKERS: Record<WindowState, string> = {
	running: "⋯",
	waiting: "!",
	ok: "✓",
	error: "✗",
	unreported: "✗ unreported",
};

/** Returns a tmux window name ≤30 chars, with optional depth prefix for nested agents. */
export function formatWindowName(state: WindowState, agent: string, depth: number): string {
	const prefix = depth >= 2 ? `L${depth} ` : "";
	const name = `${prefix}${MARKERS[state]} ${agent}`;
	// Slice by code points to avoid splitting a UTF-16 surrogate pair (emoji etc).
	return [...name].slice(0, MAX_WINDOW_NAME_LENGTH).join("");
}
