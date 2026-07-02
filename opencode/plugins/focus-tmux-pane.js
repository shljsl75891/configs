async function checkIfPrimaryAgent(client, sessionID) {
  try {
    const session = await client.session.get({ path: { id: sessionID } });
    return !session.data?.parentID;
  } catch {
    return true;
  }
}

export const FocusPane = async ({ $, client }) => {
  return {
    event: async ({ event }) => {
      const eventsToWatch = [
        "session.idle",
        "permission.asked",
        "question.asked",
      ];
      if (!eventsToWatch.includes(event.type)) return;
      if (event.type === "session.idle") {
        const { sessionID } = event.properties;
        const isPrimaryAgent = await checkIfPrimaryAgent(client, sessionID);
        if (!isPrimaryAgent) return;
      }

      if (process.env.TMUX_PANE) {
        const TERMINAL_WORKSPACE = 2;
        await $`swaymsg workspace ${TERMINAL_WORKSPACE} 1>/dev/null 2>&1`;
        await $`tmux select-pane -t ${process.env.TMUX_PANE}`;
        await $`tmux switch-client -t ${process.env.TMUX_PANE}`;
        if (event.type.includes("asked")) {
          await $`tmux send-keys -t ${process.env.TMUX_PANE} Up`;
        }
      }
    },
  };
};
