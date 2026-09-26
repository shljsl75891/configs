import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
} from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";
import { modelKey, parseModelKey } from "../lib/model.ts";
import { readAgentSetting } from "../lib/settings.ts";
import { PLAN_MODE_STATUS_KEY } from "../lib/status-keys.ts";

const PLAN_SECTION = "plan_mode";
const PLAN_REMINDER = `[PLAN MODE ACTIVE]
You are in plan mode: read-only exploration and planning.

- edit and write tools are denied
- run only read-only bash commands; never ones that perform write operations. This overrides any earlier instruction to make changes directly
- if a command is denied, do not retry with a different command or path — stop, tell the user, or ask via the \`question\` tool
- interrogate the user and explore the codebase until the facts and decisions are settled — do not propose a plan on a guess 
- at the end of plan, ask all unresolved questions using the \`question\` tool
- only the user can end plan mode, by pressing Tab — you cannot end it yourself; when the plan is ready, tell the user it's ready and ask them to press Tab`;

const BUILD_SWITCH_TYPE = "plan-mode-build-switch";
const BUILD_SWITCH_REMINDER = `[PLAN MODE OFF]
The user just turned plan mode off. You may now edit, write, and run any command. Implement the plan you proposed.`;

const PLAN_SWITCH_TYPE = "plan-mode-plan-switch";
const PLAN_SWITCH_REMINDER = `[PLAN MODE ON]
The user just turned plan mode on. Edit and write tools are denied, and bash write commands are denied. Switch to read-only exploration and planning — see the plan-mode instructions above.`;

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
 * Session-entry customType (persistence format) — private. Kept separate
 * from the status-bar key even though both currently read "plan-mode":
 * renaming one is a serialization-format change, the other a UI-contract
 * change, and they shouldn't silently move together.
 */
const PLAN_MODE_ENTRY = "plan-mode";
/** pi.events channel carrying `{ enabled: boolean }` on every mode change and session start. */
export const PLAN_MODE_EVENT = "plan-mode";
/** Payload for PLAN_MODE_EVENT. */
interface PlanModePayload {
  enabled: boolean;
}

/** Subscribes to PLAN_MODE_EVENT with the payload already narrowed. */
export function onPlanModeChange(
  pi: ExtensionAPI,
  handler: (enabled: boolean) => void,
): void {
  pi.events.on(PLAN_MODE_EVENT, (data) =>
    handler((data as PlanModePayload).enabled),
  );
}

type Mode = "plan" | "build";
/** Last model ("provider/id") used in each mode; restored on Tab. */
type ModeModels = Partial<Record<Mode, string>>;

interface PlanModeEntry {
  enabled: boolean;
  models?: ModeModels;
}

/** Narrows an untrusted `models` value (session file or settings.json modeModels): only string entries under known mode keys survive. */
function readModels(raw: unknown): ModeModels {
  const models: ModeModels = {};
  if (typeof raw !== "object" || raw === null) return models;
  for (const m of ["plan", "build"] as const) {
    const v = (raw as Record<string, unknown>)[m];
    if (typeof v === "string") models[m] = v;
  }
  return models;
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
      return {
        enabled: typeof data?.enabled === "boolean" ? data.enabled : true,
        models: readModels(data?.models),
      };
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
   * Turns since the last plan-mode reminder (switch notice or periodic)
   * was injected into the transcript. See PLAN_REMINDER_INTERVAL_TURNS.
   */
  let turnsSincePlanReminder = 0;
  let models: ModeModels = {};
  const mode = (): Mode => (enabled ? "plan" : "build");
  /* Read once at extension init, not per-session: argv doesn't change mid-process. */
  const explicitModel = process.argv.includes("--model");

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
    pi.appendEntry<PlanModeEntry>(PLAN_MODE_ENTRY, { enabled, models });
  }

  /** Switches to the current mode's remembered model, else its settings default. */
  async function applyModeModel(ctx: ExtensionContext): Promise<void> {
    try {
      const target =
        models[mode()] ?? readModels(readAgentSetting("modeModels"))[mode()];
      if (!target || target === modelKey(ctx.model)) return;
      const parsed = parseModelKey(target);
      if (!parsed) {
        ctx.ui.notify(
          `Plan mode: invalid model "${target}" in modeModels (expected "provider/id")`,
          "warning",
        );
        return;
      }
      const model = ctx.modelRegistry.find(parsed.provider, parsed.id);
      if (!(model && (await pi.setModel(model)))) {
        ctx.ui.notify(
          `Plan mode: cannot switch to ${target}; keeping current model`,
          "warning",
        );
      }
    } catch (err) {
      // Also catches a bad settings.json (readAgentSetting throws on invalid JSON).
      ctx.ui.notify(
        `Plan mode: cannot switch ${mode()}'s model: ${String(err)}`,
        "warning",
      );
    }
  }

  /** permission extension (and subagent) read the mode from this event. */
  function announce(): void {
    pi.events.emit(PLAN_MODE_EVENT, { enabled } satisfies PlanModePayload);
  }

  // Only the user can end plan mode (Tab) — the model has no tool that does.
  async function doToggle(ctx: ExtensionContext): Promise<void> {
    enabled = !enabled;
    announce();
    pendingSwitchNotice = true;
    turnsSincePlanReminder = 0;
    updateStatus(ctx);
    await applyModeModel(ctx);
    persist();
  }

  /**
   * Serialized: a toggle's `enabled`/`models[mode()]` reads must stay stable
   * across its own `await applyModeModel`. Without this queue, a second Tab
   * before the first's model switch resolves would flip `enabled` mid-flight
   * and both switches would race the model_select event, corrupting
   * per-mode model memory.
   */
  let switching: Promise<void> = Promise.resolve();
  function toggle(ctx: ExtensionContext): Promise<void> {
    // .catch, not letting a rejection propagate: an uncaught rejection here
    // would poison `switching` forever, the same failure-mode the queue
    // itself exists to prevent (see the comment above doToggle).
    switching = switching
      .then(() => doToggle(ctx))
      .catch((err) => {
        ctx.ui.notify(`Plan mode: toggle failed: ${String(err)}`, "warning");
      });
    return switching;
  }

  pi.registerShortcut(Key.tab, {
    description: "Toggle plan mode",
    handler: (ctx) => toggle(ctx),
  });

  // Every model change (/model, cycling, our own switch) is remembered for the current mode.
  pi.on("model_select", (event) => {
    models[mode()] = modelKey(event.model);
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
     * that anything changed, just a permission-denied error later if
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

    /* getBranch(), not getEntries(): after a rewind/fork, getEntries() can
       still carry a plan-mode entry from an abandoned branch. */
    const persisted = readPlanModeEntry(ctx.sessionManager.getBranch());
    // Resumed state wins over --plan: the flag only seeds a fresh session.
    if (persisted) enabled = persisted.enabled;
    models = { ...persisted?.models };

    announce();
    updateStatus(ctx);

    /* "startup" also fires for --continue, so it can't tell a fresh session
       from a resumed one - a branch with no message entries yet can. */
    const branch = ctx.sessionManager.getBranch();
    const fresh =
      !persisted && !branch.some((entry) => entry.type === "message");
    const startupModel = modelKey(ctx.model);
    if (fresh && !explicitModel) {
      /* No --model given: modeModels[mode] (falling back to whatever pi
         itself started on) is this mode's default, not an override to
         remember - just switch to it. */
      await applyModeModel(ctx);
    } else if (startupModel) {
      /* Resumed, or --model was a deliberate choice (eg. a plan-mode
         subagent keeping its agent's own model) - keep it. */
      models[mode()] = startupModel;
    }
    if (flagEnabled && !persisted) persist();
  });

  /**
   * /tree keeps the mode the user last chose. Persist when the target
   * branch records a different mode, so a later resume of it matches.
   */
  pi.on("session_tree", (_event, ctx) => {
    const persisted = readPlanModeEntry(ctx.sessionManager.getBranch());
    if (!enabled && persisted === undefined) return;
    if (persisted?.enabled !== enabled) persist();
  });
}
