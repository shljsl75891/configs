/** Tmux helpers used by the subagent orchestrator. Extracted for clarity. */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export async function getCurrentTmuxSession(pi: ExtensionAPI): Promise<string> {
	const pane = process.env.TMUX_PANE;
	if (!pane) throw new Error("Not running inside tmux (TMUX_PANE is unset). The subagent tool requires tmux.");
	const result = await pi.exec("tmux", ["display-message", "-p", "-t", pane, "#{session_id}"]);
	if (result.code !== 0) throw new Error(`Failed to resolve current tmux session: ${result.stderr || result.stdout}`);
	return result.stdout.trim();
}

export async function createTmuxWindow(
	pi: ExtensionAPI,
	session: string,
	windowName: string,
	cwd: string,
	env: Record<string, string>,
	command: string,
): Promise<string> {
	const args = ["new-window", "-t", session, "-n", windowName, "-c", cwd, "-P", "-F", "#{window_id}"];
	for (const [key, value] of Object.entries(env)) args.push("-e", `${key}=${value}`);
	args.push(command);
	const result = await pi.exec("tmux", args);
	if (result.code !== 0) throw new Error(`Failed to create tmux window: ${result.stderr || result.stdout}`);
	return result.stdout.trim();
}

export async function killTmuxWindow(pi: ExtensionAPI, windowId: string): Promise<void> {
	await pi.exec("tmux", ["kill-window", "-t", windowId]).catch(() => {});
}

export function windowHint(windowId: string): string {
	return `Window kept for follow-ups: tmux select-window -t ${windowId}`;
}

export async function isWindowAlive(pi: ExtensionAPI, windowId: string): Promise<boolean> {
	// By id, not by listing the origin session: a window moved to another session
	// is still alive and must not be reported as gone.
	const result = await pi.exec("tmux", ["display-message", "-p", "-t", windowId, "#{window_id}"]).catch(() => null);
	// A rejected exec says nothing about the window, so assume alive and let the
	// timeout decide. A non-zero exit is a real answer.
	if (!result) return true;
	return result.code === 0 && result.stdout.trim() === windowId;
}
