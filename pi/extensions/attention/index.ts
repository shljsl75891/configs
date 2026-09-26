/**
 * Grabs the user's attention when the primary session needs it: focuses the
 * terminal tag (awesome/rc.lua's focus_terminal_tag()) and the tmux pane, and
 * plays a short sound, when the agent goes idle or a blocking UI prompt opens.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

/**
 * Collapses a settle event and the prompt that immediately follows it (e.g. the
 * subagent review prompt right after agent_settled) into one alert instead of two.
 */
const SIGNAL_DEBOUNCE_MS = 200;
const SOUND_VOLUME = "0.40";
const ASSETS_DIR = join(dirname(fileURLToPath(import.meta.url)), "assets");
const DONE_SOUND = join(ASSETS_DIR, "done.wav");
const PROMPT_SOUND = join(ASSETS_DIR, "prompt.wav");

export default function attention(pi: ExtensionAPI) {
  const tmuxPane = process.env.TMUX_PANE;
  let lastSignalAt = 0;

  async function signalAttention({
    sound,
    preselectFirstOption = false,
  }: {
    sound: string;
    preselectFirstOption?: boolean;
  }) {
    const now = Date.now();
    if (now - lastSignalAt < SIGNAL_DEBOUNCE_MS) return;
    lastSignalAt = now;

    // Fire-and-forget: pi.exec never rejects, and a missing pw-play only costs the sound.
    void pi.exec("pw-play", ["--volume", SOUND_VOLUME, sound]);

    if (!tmuxPane) return;

    await pi.exec("awesome-client", ["focus_terminal_tag()"]);
    await pi.exec("tmux", ["select-pane", "-t", tmuxPane]);
    await pi.exec("tmux", ["switch-client", "-t", tmuxPane]);
    if (preselectFirstOption) {
      await pi.exec("tmux", ["send-keys", "-t", tmuxPane, "Up"]);
    }
  }

  pi.on("agent_settled", () => signalAttention({ sound: DONE_SOUND }));

  pi.on("ui_prompt_start", (event, ctx) => {
    // Idle = user-opened UI (e.g. /mcp); only prompts raised mid-run need attention.
    if (ctx.isIdle()) return;
    /**
     * "Up" pre-selects the first option. This repo's only custom UI
     * (question-tool) renders a list, so it qualifies.
     */
    const preselectFirstOption =
      event.kind === "select" || event.kind === "custom";
    return signalAttention({ sound: PROMPT_SOUND, preselectFirstOption });
  });
}
