import type { Plugin } from "@opencode-ai/plugin";

export const NotifyAndFocusPlugin: Plugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type !== "session.idle") return;

      const pane = process.env.TMUX_PANE;
      if (pane) {
        await $`osascript -e 'display notification "Chat completed!" with title "OpenCode"'`;
        await $`osascript -e 'tell application "Ghostty" to activate'`;
        await $`tmux select-pane -t ${pane}`;
        await $`tmux switch-client -t ${pane}`;
      }
    },
  };
};
