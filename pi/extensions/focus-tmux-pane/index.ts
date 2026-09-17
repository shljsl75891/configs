/**
 * Focuses the terminal tag (awesome/rc.lua's focus_terminal_tag()) and the tmux
 * pane when the primary session goes idle or a blocking UI prompt opens.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const FOCUS_DEBOUNCE_MS = 200;

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
		} catch {}
	}

	pi.on("agent_settled", async () => {
		await focusPane(false);
	});

	pi.on("ui_prompt_start", async (event) => {
		// "Up" pre-selects the first option, so send it only where a list exists.
		const isArrowNavigable = event.kind === "select" || event.kind === "custom";
		await focusPane(isArrowNavigable);
	});
}
