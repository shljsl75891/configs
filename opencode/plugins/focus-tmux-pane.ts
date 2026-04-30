import type { Plugin } from "@opencode-ai/plugin";
import type { createOpencodeClient } from "@opencode-ai/sdk";

type Client = ReturnType<typeof createOpencodeClient>;

async function checkIfPrimayAgent(
  client: Client,
  sessionID: string,
): Promise<boolean> {
  try {
    const session = await client.session.get({ path: { id: sessionID } });
    return !session.data?.parentID;
  } catch {
    return true; // assume parent on error
  }
}

export const FocusPane: Plugin = async ({ $, client }) => {
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
        const isPrimaryAgent = await checkIfPrimayAgent(client, sessionID);
        if (!isPrimaryAgent) return;
      }

      await $`osascript -e 'tell application "Ghostty" to activate'`;
      if (process.env.TMUX_PANE) {
        await $`tmux select-pane -t ${process.env.TMUX_PANE}`;
        await $`tmux switch-client -t ${process.env.TMUX_PANE}`;
      }
    },
  };
};
