/**
 * Focus Tmux Pane
 *
 * Ported from opencode/plugins/focus-tmux-pane.js. Focuses the terminal tag
 * (awesome/rc.lua's focus_terminal_tag()) + tmux pane/client when:
 *  - the primary (top-level, non-subagent) session goes idle
 *  - a permission-system UI prompt is about to show (hotkey dialog — no arrow nav)
 *  - a built-in blocking UI prompt (select/confirm/input/editor/custom) starts,
 *    e.g. the `question` tool's picker — arrow-navigable, so also nudges "Up"
 *    to pre-select the first option like the original did.
 *
 * Differences from the opencode original:
 *  - opencode's `session.idle` + `client.session.get()` parentID check ->
 *    `agent_settled` + a check on the session file path. `@gotgenes/pi-subagents`
 *    child sessions write transcripts under `.pi/output/agent-*.jsonl`; the
 *    primary session's file lives under `~/.pi/agent/sessions/...` (or is
 *    ephemeral/undefined).
 *  - opencode's `permission.asked` / `question.asked` split into two distinct
 *    pi signals with different UI shapes (see above) instead of one generic
 *    "asked" event, so "Up" is only sent where an arrow-navigable list exists.
 *  - opencode's `$` shell tag -> `pi.exec(command, args)`.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const FOCUS_DEBOUNCE_MS = 200;

function isSubagentChildSession(sessionFile: string | undefined): boolean {
	if (!sessionFile) return false;
	return /[/\\]output[/\\]agent-/.test(sessionFile);
}

export default function focusTmuxPane(pi: ExtensionAPI) {
	let lastFocusAt = 0;

	async function focusPane(pressUp: boolean) {
		const tmuxPane = process.env.TMUX_PANE;
		if (!tmuxPane) return;

		const now = Date.now();
		if (now - lastFocusAt < FOCUS_DEBOUNCE_MS) return;
		lastFocusAt = now;

		try {
			await pi.exec("awesome-client", ["focus_terminal_tag()"]);
			await pi.exec("tmux", ["select-pane", "-t", tmuxPane]);
			await pi.exec("tmux", ["switch-client", "-t", tmuxPane]);
			if (pressUp) {
				await pi.exec("tmux", ["send-keys", "-t", tmuxPane, "Up"]);
			}
		} catch {
			// Best-effort focus nudge; swallow errors (e.g. no awesome/tmux available).
		}
	}

	// Primary-session idle -> focus, no keypress (mirrors opencode's session.idle).
	pi.on("agent_settled", async (_event, ctx) => {
		const sessionFile = ctx.sessionManager?.getSessionFile();
		if (isSubagentChildSession(sessionFile)) return;
		await focusPane(false);
	});

	// Permission-system ask: hotkey dialog (y/s/n/r), not arrow-navigable.
	// Best-effort: only fires if @gotgenes/pi-permission-system emits this
	// event on its shared event bus before showing its prompt.
	pi.events.on("permissions:ui_prompt", async () => {
		await focusPane(false);
	});

	// Built-in blocking UI prompts: covers the `question` tool's ctx.ui.custom()
	// picker plus any select/confirm/input/editor dialog from any extension.
	pi.on("ui_prompt_start", async (event) => {
		const isArrowNavigable = event.kind === "select" || event.kind === "custom";
		await focusPane(isArrowNavigable);
	});
}
