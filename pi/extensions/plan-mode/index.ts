import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
} from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";
import { isBlockedBashCommand } from "./classify.ts";

const MUTATING_TOOLS = new Set(["edit", "write"]);

const PLAN_SECTION = "plan_mode";
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

/**
 * Session-entry customType (persistence format) — private. Kept separate
 * from the status-bar key below even though both currently read
 * "plan-mode": renaming one is a serialization-format change, the other a
 * UI-contract change, and they shouldn't silently move together.
 */
const PLAN_MODE_ENTRY = "plan-mode";
/**
 * ctx.ui.setStatus key: the public contract other extensions (context-bar)
 * read via the live footer status map to detect plan-mode state.
 */
export const PLAN_MODE_STATUS_KEY = "plan-mode";

interface PlanModeEntry {
  enabled: boolean;
  toolsBeforePlanMode?: string[];
}

function readPlanModeEntry(
  entries: readonly SessionEntry[],
): PlanModeEntry | undefined {
  for (let i = entries.length - 1; i >= 0; i--) {
    const entry = entries[i];
    if (entry.type === "custom" && entry.customType === PLAN_MODE_ENTRY) {
      /**
       * Data crosses a serialization boundary (a session file, possibly
       * written by an older version of this extension) — narrow instead
       * of trusting the cast.
       */
      const data = entry.data as Partial<PlanModeEntry> | undefined;
      if (typeof data?.enabled !== "boolean") {
        // Malformed entry: fail closed into plan mode with no baseline,
        // rather than silently resuming in build mode with the gate off.
        return { enabled: true, toolsBeforePlanMode: undefined };
      }
      const tools = data.toolsBeforePlanMode;
      return {
        enabled: data.enabled,
        toolsBeforePlanMode: Array.isArray(tools) ? tools : undefined,
      };
    }
  }
  return undefined;
}

export default function planMode(pi: ExtensionAPI) {
  let enabled = false;
  /**
   * Snapshot, not derive-on-exit: this must restore whatever active-tool
   * set existed before plan mode — including tools already disabled by
   * eg. --exclude-tools/-nbt at startup — not just re-enable edit/write.
   */
  let toolsBeforePlanMode: string[] | undefined;
  // Best-effort, per-process only: enabled is persisted across resume,
  // this one-shot notice isn't. Not worth persisting for a one-liner.
  let pendingBuildSwitch = false;

  pi.registerFlag("plan", {
    description: "Start in plan mode (read-only exploration)",
    type: "boolean",
    default: false,
  });

  function updateStatus(ctx: ExtensionContext): void {
    ctx.ui.setStatus(
      PLAN_MODE_STATUS_KEY,
      enabled ? ctx.ui.theme.fg("warning", "[plan]") : undefined,
    );
  }

  function persist(): void {
    pi.appendEntry<PlanModeEntry>(PLAN_MODE_ENTRY, {
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
    // enabled only flips off inside toggle(), which only ever turns it on
    // by calling enter() first — a baseline is always captured by here.
    pi.setActiveTools(toolsBeforePlanMode!);
    toolsBeforePlanMode = undefined;
  }

  // Only the user can end plan mode (Tab) — the model has no tool that does.
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
    handler: (ctx) => toggle(ctx),
  });

  pi.on("tool_call", (event) => {
    if (!enabled) return;
    /**
     * The bash classifier is bash-shaped and can't parse PowerShell
     * syntax, so a powershell tool would otherwise bypass the write-
     * gating backstop entirely — block it outright, same treatment as
     * sudo (plan mode has no reason to need either).
     */
    if (isToolCallEventType("powershell", event)) {
      return {
        block: true,
        reason:
          "Plan mode: powershell is blocked outright (no write classifier for it). Press Tab to leave plan mode.",
      };
    }
    // subagent spawns a separate `pi` process (see extensions/subagent)
    // with no --plan flag, so it isn't gated by this session's plan mode
    // at all. Left unblocked intentionally: delegating to it is part of
    // the normal plan-mode workflow here.
    if (!isToolCallEventType("bash", event)) return;
    const { command } = event.input;
    if (!isBlockedBashCommand(command)) return;
    return {
      block: true,
      reason: `Plan mode: write command blocked. Press Tab to leave plan mode, or target a path under /tmp.\nCommand: ${command}`,
    };
  });

  pi.on("before_agent_start", (event) => {
    if (enabled) {
      event.systemPromptOptions.sections[PLAN_SECTION] = PLAN_REMINDER;
    } else {
      delete event.systemPromptOptions.sections[PLAN_SECTION];
    }

    const switched = pendingBuildSwitch;
    pendingBuildSwitch = false;
    if (switched && !enabled) {
      return {
        message: {
          customType: BUILD_SWITCH_TYPE,
          content: BUILD_SWITCH_REMINDER,
          display: false,
        },
      };
    }
  });

  pi.on("session_start", async (_event, ctx) => {
    const flagEnabled = pi.getFlag("plan") === true;
    if (flagEnabled) enabled = true;

    // getBranch(), not getEntries(): after a rewind/fork, getEntries()
    // can still carry a plan-mode entry from an abandoned branch.
    const persisted = readPlanModeEntry(ctx.sessionManager.getBranch());
    // Resumed state wins over --plan: the flag only seeds a fresh session.
    if (persisted) {
      enabled = persisted.enabled;
      toolsBeforePlanMode = persisted.toolsBeforePlanMode;
    }

    if (enabled) {
      // No persisted baseline: nothing has gated tools yet this process,
      // so the current active-tool set is a correct baseline to capture.
      if (toolsBeforePlanMode === undefined) enter();
      // Persisted baseline exists: re-filter it, rather than re-capturing
      // today's already-gated active tools as a new, wrong baseline.
      else gate(toolsBeforePlanMode);
    }
    updateStatus(ctx);

    // --plan started this session with no toggle(), so no entry was ever
    // appended — a later resume of this session would come back in build
    // mode without it.
    if (flagEnabled && !persisted) persist();
  });
}
