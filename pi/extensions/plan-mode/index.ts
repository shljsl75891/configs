import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";

const MUTATING_TOOLS = new Set(["edit", "write"]);

const PLAN_REMINDER_TYPE = "plan-mode-context";
const PLAN_REMINDER = `[PLAN MODE ACTIVE]
You are in plan mode: read-only exploration and planning.

- edit and write tools are disabled
- do not run bash commands that perform write operations in the current working directory (eg. rm, mv, cp, mkdir, touch, redirects, git add/commit/push, npm install, etc.) — this overrides any earlier instruction to make changes directly
- if you need to test something with a write command, run it only against a path under /tmp, never against the current working directory
- interrogate the user and explore the codebase until the facts and decisions are settled — do not propose a plan on a guess 
- at the end of plan, ask all unresolved questions using the \`question\` tool
- only the user can end plan mode, by pressing Tab — you cannot end it yourself; when the plan is ready, tell the user it's ready and ask them to press Tab`;

const BUILD_SWITCH_TYPE = "plan-mode-build-switch";
const BUILD_SWITCH_REMINDER = `[PLAN MODE OFF]
The user just turned plan mode off. You may now edit, write, and run any command. Implement the plan you proposed.`;

interface PlanModeEntry {
  enabled: boolean;
  toolsBeforePlanMode?: string[];
}

export default function planMode(pi: ExtensionAPI) {
  let enabled = false;
  let toolsBeforePlanMode: string[] | undefined;
  let pendingBuildSwitch = false;

  pi.registerFlag("plan", {
    description: "Start in plan mode (read-only exploration)",
    type: "boolean",
    default: false,
  });

  function updateStatus(ctx: ExtensionContext): void {
    ctx.ui.setStatus(
      "plan-mode",
      enabled ? ctx.ui.theme.fg("warning", "[plan]") : undefined,
    );
  }

  function persist(): void {
    pi.appendEntry<PlanModeEntry>("plan-mode", {
      enabled,
      toolsBeforePlanMode,
    });
  }

  function gate(tools: string[]): void {
    pi.setActiveTools(tools.filter((name) => !MUTATING_TOOLS.has(name)));
  }

  function enter(): void {
    toolsBeforePlanMode = pi.getActiveTools();
    gate(toolsBeforePlanMode);
  }

  function exit(): void {
    pi.setActiveTools(toolsBeforePlanMode ?? pi.getActiveTools());
    toolsBeforePlanMode = undefined;
  }

  // Turning plan mode off is the only way out, and only the user can trigger
  // it (Tab) — the model has no tool that ends plan mode itself.
  function toggle(ctx: ExtensionContext): void {
    enabled = !enabled;
    if (enabled) {
      enter();
      ctx.ui.notify(
        "Plan mode on — edit/write disabled, no write commands in cwd.",
      );
    } else {
      exit();
      pendingBuildSwitch = true;
      ctx.ui.notify("Plan mode off — full access restored.");
    }
    updateStatus(ctx);
    persist();
  }

  pi.registerShortcut(Key.tab, {
    description: "Toggle plan mode",
    handler: async (ctx) => toggle(ctx),
  });

  pi.on("before_agent_start", async () => {
    if (pendingBuildSwitch && !enabled) {
      pendingBuildSwitch = false;
      return {
        message: {
          customType: BUILD_SWITCH_TYPE,
          content: BUILD_SWITCH_REMINDER,
          display: false,
        },
      };
    }
    pendingBuildSwitch = false;
    if (!enabled) return;
    return {
      message: {
        customType: PLAN_REMINDER_TYPE,
        content: PLAN_REMINDER,
        display: false,
      },
    };
  });

  pi.on("session_start", async (_event, ctx) => {
    const flagEnabled = pi.getFlag("plan") === true;
    if (flagEnabled) enabled = true;

    const last = [...ctx.sessionManager.getEntries()]
      .reverse()
      .find((e) => e.type === "custom" && e.customType === "plan-mode") as
      { data?: PlanModeEntry } | undefined;
    const hadPersistedEntry = Boolean(last?.data);
    if (last?.data) {
      enabled = last.data.enabled;
      toolsBeforePlanMode = last.data.toolsBeforePlanMode;
    }

    // A persisted baseline is the tool set from when plan mode was first
    // turned on; re-filter that rather than re-capturing today's (already
    // gated, at session start) active tools as a new, wrong baseline.
    if (enabled) {
      if (toolsBeforePlanMode === undefined) enter();
      else gate(toolsBeforePlanMode);
    }
    updateStatus(ctx);

    // --plan started this session in plan mode but no toggle() ran, so no
    // "plan-mode" entry was ever appended — other extensions (prompt-box)
    // that read session entries to detect plan mode would otherwise miss it.
    if (flagEnabled && !hadPersistedEntry) persist();
  });
}
