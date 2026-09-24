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
- if a write command is blocked, do not retry with a different command or path — stop, tell the user, or ask via the \`question\` tool
- interrogate the user and explore the codebase until the facts and decisions are settled — do not propose a plan on a guess 
- at the end of plan, ask all unresolved questions using the \`question\` tool
- only the user can end plan mode, by pressing Tab — you cannot end it yourself; when the plan is ready, tell the user it's ready and ask them to press Tab`;

const BUILD_SWITCH_TYPE = "plan-mode-build-switch";
const BUILD_SWITCH_REMINDER = `[PLAN MODE OFF]
The user just turned plan mode off. You may now edit, write, and run any command. Implement the plan you proposed.`;

const PLAN_SWITCH_TYPE = "plan-mode-plan-switch";
const PLAN_SWITCH_REMINDER = `[PLAN MODE ON]
The user just turned plan mode on. Edit and write tools are disabled, and bash write commands in the current working directory are blocked. Switch to read-only exploration and planning — see the plan-mode instructions above.`;

const PLAN_PERIODIC_TYPE = "plan-mode-periodic-reminder";
const PLAN_PERIODIC_REMINDER = `[PLAN MODE REMINDER] Still in plan mode: no edits, no writes, no working around it via bash. Keep exploring/planning, or ask via the \`question\` tool.`;

/**
 * Recency decays: the plan-mode system-prompt section sits at the top of
 * context and doesn't move, so on a long plan-mode stretch it gets buried
 * under turns of exploration transcript. Re-injecting a short reminder
 * near the tail every few turns keeps the rule salient without repeating
 * the full PLAN_REMINDER text each time.
 */
const PLAN_REMINDER_INTERVAL_TURNS = 4;

/**
 * After this many consecutive blocked write attempts, the block reason
 * escalates instead of repeating verbatim — the model should stop trying
 * variations, not keep guessing a path around the gate.
 */
const ESCALATE_AFTER_CONSECUTIVE_BLOCKS = 2;

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
      /* Malformed entry: fail closed into plan mode, not resume in build mode with the gate off. */
      return { enabled: typeof data?.enabled === "boolean" ? data.enabled : true };
    }
  }
  return undefined;
}

export default function planMode(pi: ExtensionAPI) {
  let enabled = false;
  /**
   * One-shot, per-process only: `enabled` is persisted across resume,
   * this notice is not. Direction is read from `enabled` at fire-time —
   * see before_agent_start for why an injected message is needed, not a
   * toast.
   */
  let pendingSwitchNotice = false;
  /**
   * Consecutive blocked write attempts (bash denials + the outright
   * powershell block) while enabled. Resets on any allowed tool call.
   * Past ESCALATE_AFTER_CONSECUTIVE_BLOCKS, the block reason escalates
   * instead of repeating — see buildBlockReason.
   */
  let consecutiveBlocks = 0;
  /**
   * Turns since the last plan-mode reminder (switch notice or periodic)
   * was injected into the transcript. See PLAN_REMINDER_INTERVAL_TURNS.
   */
  let turnsSincePlanReminder = 0;

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
    pi.appendEntry<PlanModeEntry>(PLAN_MODE_ENTRY, { enabled });
  }

  /**
   * Derive from the live active set, not from a snapshot: pi itself
   * replaces the active set on /tree navigation (it restores the tools
   * recorded at the target entry), so any snapshot can be stale.
   * --exclude-tools and --tools remove tools from the registry, so ungate
   * cannot bring them back. -nbt only clears the initial active set, so
   * ungate adds edit and write back under -nbt.
   */
  function applyGate(): void {
    const active = pi.getActiveTools();
    if (enabled) {
      pi.setActiveTools(active.filter((name) => !MUTATING_TOOLS.has(name)));
      return;
    }
    const mutating = pi
      .getAllTools()
      .map((tool) => tool.name)
      .filter((name) => MUTATING_TOOLS.has(name));
    pi.setActiveTools([...new Set([...active, ...mutating])]);
  }

  function buildBlockReason(command: string): string {
    if (consecutiveBlocks >= ESCALATE_AFTER_CONSECUTIVE_BLOCKS) {
      return `Plan mode: another write command blocked (${consecutiveBlocks} in a row). This cannot be worked around by trying a different command or path — stop, tell the user plan mode is blocking this, and ask via the \`question\` tool.\nCommand: ${command}`;
    }
    return `Plan mode: write command blocked. Do not retry with a different command or path — tell the user, or ask via the \`question\` tool. Only the user can press Tab to leave plan mode.\nCommand: ${command}`;
  }

  // Only the user can end plan mode (Tab) — the model has no tool that does.
  function toggle(ctx: ExtensionContext): void {
    enabled = !enabled;
    applyGate();
    pendingSwitchNotice = true;
    consecutiveBlocks = 0;
    turnsSincePlanReminder = 0;
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
      consecutiveBlocks++;
      return {
        block: true,
        reason:
          "Plan mode: powershell is blocked outright (no write classifier for it). Press Tab to leave plan mode.",
      };
    }
    // subagent spawns a separate `pi` process (see extensions/subagent).
    // Left unblocked here intentionally: delegating to it is part of the
    // normal plan-mode workflow, and command.ts/index.ts in that
    // extension propagate --plan to the child based on this session's
    // live getActiveTools() state, so it can't be used to bypass the
    // write restriction.
    if (!isToolCallEventType("bash", event)) {
      consecutiveBlocks = 0;
      return;
    }
    const { command } = event.input;
    if (!isBlockedBashCommand(command)) {
      consecutiveBlocks = 0;
      return;
    }
    consecutiveBlocks++;
    return {
      block: true,
      reason: buildBlockReason(command),
    };
  });

  pi.on("before_agent_start", (event) => {
    if (enabled) {
      event.systemPromptOptions.sections[PLAN_SECTION] = PLAN_REMINDER;
    } else {
      delete event.systemPromptOptions.sections[PLAN_SECTION];
    }

    /**
     * A toast (ctx.ui.notify) never reaches the model's context — only
     * the system-prompt section above does, and only on the *next* turn.
     * If the toggle lands mid-turn, that's silent: no in-transcript signal
     * that anything changed, just a generic tool-removal error later if
     * the model tries edit/write. Both directions get a real injected
     * message here so it's unmissable either way, symmetric on/off.
     */
    if (pendingSwitchNotice) {
      pendingSwitchNotice = false;
      turnsSincePlanReminder = 0;
      return {
        message: {
          customType: enabled ? PLAN_SWITCH_TYPE : BUILD_SWITCH_TYPE,
          content: enabled ? PLAN_SWITCH_REMINDER : BUILD_SWITCH_REMINDER,
          display: false,
        },
      };
    }

    // The system-prompt section above is static and cache-frozen; on a
    // long plan-mode stretch it loses salience under turns of exploration
    // transcript. Re-inject a short reminder near the tail periodically so
    // the rule stays live, not just present.
    if (enabled) {
      turnsSincePlanReminder++;
      if (turnsSincePlanReminder >= PLAN_REMINDER_INTERVAL_TURNS) {
        turnsSincePlanReminder = 0;
        return {
          message: {
            customType: PLAN_PERIODIC_TYPE,
            content: PLAN_PERIODIC_REMINDER,
            display: false,
          },
        };
      }
    }
  });

  pi.on("session_start", async (_event, ctx) => {
    const flagEnabled = pi.getFlag("plan") === true;
    if (flagEnabled) enabled = true;

    // getBranch(), not getEntries(): after a rewind/fork, getEntries()
    // can still carry a plan-mode entry from an abandoned branch.
    const persisted = readPlanModeEntry(ctx.sessionManager.getBranch());
    // Resumed state wins over --plan: the flag only seeds a fresh session.
    if (persisted) enabled = persisted.enabled;

    if (enabled) applyGate();
    updateStatus(ctx);

    // --plan started this session with no toggle(), so no entry was ever
    // appended — a later resume of this session would come back in build
    // mode without it.
    if (flagEnabled && !persisted) persist();
  });

  /**
   * /tree keeps the mode the user last chose, but pi has just restored
   * the tools of the target entry, which can be from the other mode.
   * Persist when the target branch records a different mode. A build-mode
   * branch with no plan-mode entry never had tools gated, so leave it as
   * is (this keeps edit and write off under -nbt).
   */
  pi.on("session_tree", (_event, ctx) => {
    const persisted = readPlanModeEntry(ctx.sessionManager.getBranch());
    if (!enabled && persisted === undefined) return;
    applyGate();
    if (persisted?.enabled !== enabled) persist();
  });
}
