import type { Plugin } from "@opencode-ai/plugin";

export const NotifyAndFocusPlugin: Plugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      const eventsToWatch = [
        "session.idle",
        "permission.asked",
        "question.asked",
      ];
      if (!eventsToWatch.includes(event.type)) return;
      await $`osascript -e 'tell application "Ghostty" to activate'`;
      if (process.env.TMUX_PANE) {
        await $`tmux select-pane -t ${process.env.TMUX_PANE}`;
        await $`tmux switch-client -t ${process.env.TMUX_PANE}`;
      }
    },
  };
};
