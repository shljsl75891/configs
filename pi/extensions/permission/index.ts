/**
 * OpenCode-style permissions: `permission` in ~/.pi/agent/settings.json maps a
 * tool name to an action or to `{ pattern: action }` rules (last match wins).
 * Unmatched calls are allowed. While plan mode is on (pi.events PLAN_MODE_EVENT),
 * `permission.plan` rules layer on top of PLAN_FALLBACK for edit/write/
 * powershell (a partial override still denies every other path). bash is
 * different: `permission.plan.bash`, when present, replaces
 * PLAN_FALLBACK.bash outright, since it's meant to be the full intended
 * list; PLAN_FALLBACK.bash is only a small backup used when settings.json
 * has no plan.bash at all. Either way any unrecognized action string is
 * treated as "ask", never "allow", so plan mode's core promise never
 * depends on settings.json being present, complete, or free of typos.
 * Auto-approve (`--approve`/`-a`, toggled by `/approve`) passes every `ask`;
 * `deny` still blocks. Without UI and auto-approve, `ask` blocks. `-a` is
 * pi's own flag too (it also trusts project-local files for this run) -
 * shared on purpose, since a headless run needs both decisions made without
 * a UI.
 */
import { homedir } from "node:os";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { askQuestions } from "../question-tool/prompt.ts";
import { APPROVE_STATUS_KEY } from "../lib/status-keys.ts";
import { onPlanModeChange } from "../plan-mode/index.ts";
import { readAgentSetting } from "../lib/settings.ts";
import { type Action, type Rules, decideBash, matchRule, pathSubjects, strictest } from "./match.ts";

type Config = Record<string, Action | Rules>;

const ALLOW = "Allow";
const DENY = "Deny";
const ACTIONS = new Set(["allow", "ask", "deny"]);
const isAction = (v: unknown): v is Action => typeof v === "string" && ACTIONS.has(v);
const toAction = (v: unknown): Action => (isAction(v) ? v : "ask");

/**
 * Plan-mode baseline. edit/write/powershell merge with `permission.plan`
 * (a partial rules-object override still denies every other path). bash
 * is a backup only: `permission.plan.bash`, when present, replaces this
 * list outright (see planConfig), so it's deliberately small - just
 * enough to deny writes if settings.json is ever missing or unreadable.
 * The real bash list lives in settings.json's permission.plan.bash.
 */
const PLAN_FALLBACK: Config = {
  edit: "deny",
  write: "deny",
  powershell: "deny",
  bash: {
    "> *": "deny",
    "rm *": "deny",
    "mv *": "deny",
    "git commit *": "deny",
    "git push *": "deny",
  },
};

/**
 * Narrows a raw JSON value into a Config: non-object input drops out, and
 * any action string that isn't allow/ask/deny becomes "ask" instead of
 * silently falling through to allow.
 */
function sanitizeConfig(raw: unknown): Config {
  const config: Config = {};
  if (typeof raw !== "object" || raw === null) return config;
  for (const [tool, value] of Object.entries(raw as Record<string, unknown>)) {
    if (typeof value === "object" && value !== null) {
      const rules: Rules = {};
      for (const [pattern, action] of Object.entries(value)) rules[pattern] = toAction(action);
      config[tool] = rules;
    } else {
      config[tool] = toAction(value);
    }
  }
  return config;
}

/**
 * Merges permission.plan under PLAN_FALLBACK, one exception: bash.
 * edit/write/powershell: a string override (eg. `edit: "ask"`) replaces the
 * fallback outright; a rules-object override keeps the fallback as that
 * tool's own default (`"*"`, first so later entries still win), so a
 * partial override (eg. `{ edit: { "*.md": "allow" } }`) still denies
 * every other path instead of falling through to config["*"] (allow).
 * bash: `permission.plan.bash`, when present, replaces PLAN_FALLBACK.bash
 * outright (the spread below already does this) - it's meant to be the
 * full intended list, not an overlay, so removing a rule there actually
 * removes it.
 */
function planConfig(raw: unknown): Config {
  const plan = sanitizeConfig(raw);
  const merged: Config = { ...PLAN_FALLBACK, ...plan };
  for (const [tool, fallback] of Object.entries(PLAN_FALLBACK)) {
    if (tool === "bash") continue;
    const rules = plan[tool];
    if (typeof rules !== "object") continue;
    const base = typeof fallback === "object" ? fallback : { "*": fallback };
    merged[tool] = { ...base, ...rules };
  }
  return merged;
}

async function decide(config: Config, toolName: string, input: Record<string, unknown>, cwd: string, ctx: ExtensionContext): Promise<Action> {
  const fallback = typeof config["*"] === "string" ? config["*"] : "allow";
  const rules = config[toolName];
  if (rules === undefined) return fallback;
  if (typeof rules === "string") return rules;
  const home = homedir();
  const byRule = (subject: string) => matchRule(rules, subject, home) ?? fallback;
  if (toolName === "bash") {
    return decideBash(String(input.command ?? ""), byRule).catch((err): Action => {
      ctx.ui.notify(`permission: could not parse bash command, defaulting to ask: ${String(err)}`, "warning");
      return "ask";
    });
  }
  if (typeof input.path !== "string") return fallback;
  return strictest(pathSubjects(input.path, cwd, home).map(byRule));
}

function describeCall(toolName: string, input: Record<string, unknown>): string {
  if (toolName === "bash") return `bash: ${String(input.command ?? "")}`;
  return typeof input.path === "string" ? `${toolName}: ${input.path}` : toolName;
}

export default function (pi: ExtensionAPI) {
  // Raw argv, not registerFlag: registerFlag has no short-alias support (needed for -a).
  let autoApprove = process.argv.some((a) => a === "--approve" || a === "-a");
  const showApprove = (ctx: ExtensionContext) => ctx.ui.setStatus(APPROVE_STATUS_KEY, autoApprove ? "(auto)" : undefined);
  pi.registerCommand("approve", {
    description: "Toggle auto-approve of permission prompts (deny rules still apply)",
    handler: async (_args, ctx) => {
      autoApprove = !autoApprove;
      showApprove(ctx);
      ctx.ui.notify(`Auto-approve ${autoApprove ? "on" : "off"}`, "info");
    },
  });
  let planMode = false;
  /* Enforcement depends on this firing: if plan-mode fails to load, its own
     status badge (read by context-bar) won't show either, since both come
     from that same extension - so the failure is visible, not silent. */
  onPlanModeChange(pi, (enabled) => {
    planMode = enabled;
  });
  pi.on("session_start", (_event, ctx) => showApprove(ctx));

  pi.on("tool_call", async (event, ctx) => {
    let raw: unknown;
    try {
      raw = readAgentSetting("permission");
    } catch (err) {
      // Bad JSON, not a missing file (lib/settings.ts only swallows ENOENT):
      // fail toward "ask" for the normal rules, not "allow everything".
      // Plan mode is unaffected - planConfig(undefined) still applies PLAN_FALLBACK.
      ctx.ui.notify(`permission: settings.json unreadable, defaulting to ask: ${String(err)}`, "warning");
      raw = { "*": "ask" };
    }
    const { plan, ...base } = (typeof raw === "object" && raw ? raw : {}) as Record<string, unknown>;
    const input = event.input as Record<string, unknown>;
    const checks = [decide(sanitizeConfig(base), event.toolName, input, ctx.cwd, ctx)];
    if (planMode) checks.push(decide(planConfig(plan), event.toolName, input, ctx.cwd, ctx));
    const action = strictest(await Promise.all(checks));
    if (action === "allow") return undefined;

    const label = describeCall(event.toolName, input);
    const where = planMode ? " in plan mode" : "";
    if (action === "deny") return { block: true, reason: `Denied by permission rule${where}: ${label}` };

    if (autoApprove) return undefined;
    if (!ctx.hasUI) return { block: true, reason: `Needs approval (no UI, no --approve): ${label}` };

    const result = await askQuestions(
      ctx.ui,
      [{ header: "Permission", question: `Permission required${where}\n\n${label}`, options: [ALLOW, DENY].map((l) => ({ label: l })) }],
      { signal: ctx.signal, customLabel: "Deny with reason…" },
    );
    const answer = result?.answers[0]?.[0];
    if (answer === ALLOW) return undefined;
    const reason = answer && answer !== DENY ? `: ${answer}` : "";
    return { block: true, reason: `Denied by user${where}${reason}` };
  });
}
