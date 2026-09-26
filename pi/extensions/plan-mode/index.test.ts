import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import planMode, { PLAN_MODE_EVENT } from "./index.ts";
import { modelKey, parseModelKey } from "../lib/model.ts";

const OPUS = "anthropic/claude-opus-5-5";
const SONNET = "anthropic/claude-sonnet-5";
const HAIKU = "anthropic/claude-haiku-5";

// Settings defaults read by the extension (modeModels).
process.env.PI_CODING_AGENT_DIR = mkdtempSync(join(tmpdir(), "plan-mode-test-"));
writeFileSync(
  join(process.env.PI_CODING_AGENT_DIR, "settings.json"),
  JSON.stringify({ modeModels: { plan: OPUS, build: SONNET } }),
);

type Model = { provider: string; id: string };
const toModel = (key: string): Model => parseModelKey(key)!;

type Handler = (event: object, ctx: object) => unknown;
type Entry = { type: "custom"; customType: string; data: unknown };

/** Fake of the pi runtime: owns the session branch and records plan-mode events. */
function fakePi({
  branch: initialBranch = [] as Entry[],
  model: initialModel = SONNET as string | undefined,
  flag = false,
  argv = [] as string[],
} = {}) {
  const handlers = new Map<string, Handler>();
  let tab: ((ctx: object) => void) | undefined;
  let branch = [...initialBranch];
  const announced: boolean[] = [];
  let model = initialModel ? toModel(initialModel) : undefined;
  /** Pi's /model: sets the model and emits model_select. Delayed a tick, like a real
   *  network/tmux call, so concurrent Tab presses actually race without the queue. */
  const selectModel = async (next: Model) => {
    await new Promise((resolve) => setTimeout(resolve, 0));
    model = next;
    await handlers.get("model_select")!({ model: next }, ctx);
    return true;
  };
  const pi = {
    registerFlag() {},
    getFlag: () => flag,
    setModel: selectModel,
    registerShortcut: (_key: unknown, opts: { handler: (ctx: object) => void }) => {
      tab = opts.handler;
    },
    on: (event: string, handler: Handler) => handlers.set(event, handler),
    appendEntry: (customType: string, data: unknown) => {
      branch.push({ type: "custom", customType, data });
    },
    events: {
      emit: (channel: string, data: { enabled: boolean }) => {
        if (channel === PLAN_MODE_EVENT) announced.push(data.enabled);
      },
    },
  };
  const ctx = {
    ui: { setStatus() {}, notify() {}, theme: { fg: (_c: string, s: string) => s } },
    sessionManager: { getBranch: () => branch },
    modelRegistry: { find: (provider: string, id: string) => ({ provider, id }) },
    get model() {
      return model;
    },
  };
  const prevArgv = process.argv;
  process.argv = ["node", "pi", ...argv];
  planMode(pi as unknown as ExtensionAPI);
  process.argv = prevArgv;
  return {
    announced,
    get model() {
      return modelKey(model);
    },
    pickModel: (key: string) => selectModel(toModel(key)),
    get branch() {
      return branch;
    },
    start: () => handlers.get("session_start")!({}, ctx),
    tab: async () => tab!(ctx),
    navigateTree: (target: Entry[]) => {
      branch = [...target];
      handlers.get("session_tree")!({}, ctx);
    },
  };
}

const planEntry = (enabled: boolean, models?: object): Entry => ({ type: "custom", customType: "plan-mode", data: { enabled, models } });
const persisted = (e: Entry | undefined) => (e?.data as { enabled: boolean }).enabled;

describe("plan mode events", () => {
  it("announces build mode on a fresh session start", async () => {
    const pi = fakePi();
    await pi.start();
    assert.deepEqual(pi.announced, [false]);
  });

  it("announces plan mode on resume of a session in plan mode", async () => {
    const pi = fakePi({ branch: [planEntry(true)] });
    await pi.start();
    assert.deepEqual(pi.announced, [true]);
  });

  it("resumes in plan mode when the recorded entry is malformed", async () => {
    const pi = fakePi({ branch: [{ type: "custom", customType: "plan-mode", data: {} }] });
    await pi.start();
    assert.deepEqual(pi.announced, [true]);
  });

  it("announces and persists every Tab toggle", async () => {
    const pi = fakePi();
    await pi.start();
    await pi.tab();
    await pi.tab();
    assert.deepEqual(pi.announced, [false, true, false]);
    assert.deepEqual(pi.branch.map(persisted), [true, false]);
  });
});

describe("plan mode after /tree navigation", () => {
  it("records build mode when the target entry was in plan mode", async () => {
    const pi = fakePi();
    await pi.start();
    pi.navigateTree([planEntry(true)]);
    assert.equal(persisted(pi.branch.at(-1)), false);
  });

  it("records plan mode when the target entry was in build mode", async () => {
    const pi = fakePi();
    await pi.start();
    await pi.tab();
    pi.navigateTree([planEntry(false)]);
    assert.equal(persisted(pi.branch.at(-1)), true);
  });

  it("does not record the mode again when the target branch has the same mode", async () => {
    const pi = fakePi();
    await pi.start();
    await pi.tab();
    pi.navigateTree([planEntry(true)]);
    assert.equal(pi.branch.length, 1);
  });

  it("records nothing in build mode when plan mode was never used", async () => {
    const pi = fakePi();
    await pi.start();
    pi.navigateTree([]);
    assert.equal(pi.branch.length, 0);
  });
});

describe("per-mode models", () => {
  it("switches to the plan default on Tab and back to the build model", async () => {
    const pi = fakePi();
    await pi.start();
    await pi.tab();
    assert.equal(pi.model, OPUS);
    await pi.tab();
    assert.equal(pi.model, SONNET);
  });

  it("remembers a model picked in plan mode across toggles", async () => {
    const pi = fakePi();
    await pi.start();
    await pi.tab();
    await pi.pickModel(HAIKU);
    await pi.tab();
    assert.equal(pi.model, SONNET);
    await pi.tab();
    assert.equal(pi.model, HAIKU);
  });

  it("keeps an explicit --model as the build model instead of switching to modeModels.build", async () => {
    const pi = fakePi({ model: HAIKU, argv: ["--model", "claude-haiku-5"] });
    await pi.start();
    assert.equal(pi.model, HAIKU);
    await pi.tab();
    await pi.tab();
    assert.equal(pi.model, HAIKU);
  });

  it("switches to modeModels.build on the first Tab back, when --plan started fresh with no --model", async () => {
    const pi = fakePi({ model: HAIKU, flag: true });
    await pi.start();
    assert.equal(pi.model, OPUS);
    await pi.tab();
    assert.equal(pi.model, SONNET);
  });

  it("restores remembered models on resume", async () => {
    const pi = fakePi({ model: OPUS, branch: [planEntry(true, { plan: OPUS, build: HAIKU })] });
    await pi.start();
    await pi.tab();
    assert.equal(pi.model, HAIKU);
  });

  it("ignores a malformed models entry instead of crashing on Tab", async () => {
    const pi = fakePi({ model: SONNET, branch: [planEntry(false, { plan: 123, build: SONNET })] });
    await pi.start();
    await pi.tab();
    assert.equal(pi.model, OPUS);
  });

  it("keeps an explicit --model in plan mode instead of switching to the plan default", async () => {
    const pi = fakePi({ model: HAIKU, flag: true, argv: ["--model", "claude-haiku-5"] });
    await pi.start();
    assert.equal(pi.model, HAIKU);
    await pi.tab();
    assert.equal(pi.model, SONNET);
  });

  it("serializes rapid Tab presses instead of racing on a stale mode", async () => {
    const pi = fakePi();
    await pi.start();
    await Promise.all([pi.tab(), pi.tab()]);
    assert.equal(pi.model, SONNET);
  });
});
