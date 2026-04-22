import type { Plugin } from "@opencode-ai/plugin";

export const NotifyAndFocusPlugin: Plugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type !== "session.idle") return;
      await $`osascript -e 'tell application "Ghostty" to activate'`;
      await $`tmux select-pane -t ${process.env.TMUX_PANE}`;
      await $`tmux switch-client -t ${process.env.TMUX_PANE}`;
    },
  };
};
