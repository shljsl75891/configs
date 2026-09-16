import { Plugin } from "@opencode/plugin/tui";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { PluginContext } from "@opencode/plugin/tui";

const run = promisify(execFile);

async function isPrimaryAgent(
  context: PluginContext,
  sessionID: string,
): Promise<boolean> {
  try {
    await context.data.session.sync(sessionID);
    return !context.data.session.get(sessionID)?.parentID;
  } catch {
    return true;
  }
}

export default Plugin.define({
  id: "sahiljassal.focus-tmux-pane",
  setup(context) {
    const pane = process.env.TMUX_PANE;
    if (!pane) return;

    const focus = async (moveUp: boolean) => {
      try {
        // Tag 2 = terminal tag, defined in awesome/rc.lua's focus_terminal_tag()
        await run("awesome-client", ["focus_terminal_tag()"]);
        await run("tmux", ["select-pane", "-t", pane]);
        await run("tmux", ["switch-client", "-t", pane]);
        if (moveUp) await run("tmux", ["send-keys", "-t", pane, "Up"]);
      } catch {}
    };

    const stopIdle = context.data.on("session.idle", async (event) => {
      if (await isPrimaryAgent(context, event.data.sessionID)) await focus(false);
    });
    const stopPermission = context.data.on("permission.asked", () => focus(true));
    const stopQuestion = context.data.on("question.asked", () => focus(true));

    return () => {
      stopIdle();
      stopPermission();
      stopQuestion();
    };
  },
});
