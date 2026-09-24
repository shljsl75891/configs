import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import planMode from "./index.ts";

type Handler = (event: object, ctx: object) => unknown;
type Entry = { type: "custom"; customType: string; data: unknown };

const REGISTERED = ["read", "bash", "edit", "write", "question"];
const WITHOUT_MUTATING = ["read", "bash", "question"];

/** Fake of the pi runtime: owns the active-tool set and the session branch, as pi does. */
function fakePi({ active: initialActive = REGISTERED, branch: initialBranch = [] as Entry[] } = {}) {
  const handlers = new Map<string, Handler>();
  let tab: ((ctx: object) => void) | undefined;
  let active = [...initialActive];
  let branch = [...initialBranch];
  const pi = {
    registerFlag() {},
    getFlag: () => false,
    registerShortcut: (_key: unknown, opts: { handler: (ctx: object) => void }) => {
      tab = opts.handler;
    },
    on: (event: string, handler: Handler) => handlers.set(event, handler),
    appendEntry: (customType: string, data: unknown) => {
      branch.push({ type: "custom", customType, data });
    },
    getActiveTools: () => [...active],
    getAllTools: () => REGISTERED.map((name) => ({ name })),
    setActiveTools: (names: string[]) => {
      active = names;
    },
  };
  const ctx = {
    ui: { setStatus() {}, theme: { fg: (_c: string, s: string) => s } },
    sessionManager: { getBranch: () => branch },
  };
  planMode(pi as unknown as ExtensionAPI);
  return {
    get active() {
      return [...active].sort();
    },
    get branch() {
      return branch;
    },
    start: () => handlers.get("session_start")!({}, ctx),
    tab: () => tab!(ctx),
    /** Pi moves to the target branch, restores its recorded tools, then emits session_tree. */
    navigateTree: (target: { tools: string[]; branch: Entry[] }) => {
      active = target.tools;
      branch = [...target.branch];
      handlers.get("session_tree")!({}, ctx);
    },
  };
}

const planEntry = (enabled: boolean): Entry => ({ type: "custom", customType: "plan-mode", data: { enabled } });

describe("plan mode on session start", () => {
  it("keeps edit and write off in build mode when they start inactive (-nbt)", () => {
    const pi = fakePi({ active: WITHOUT_MUTATING });
    pi.start();
    assert.deepEqual(pi.active, ["bash", "question", "read"]);
  });

  it("removes edit and write on resume of a session in plan mode", () => {
    const pi = fakePi({ branch: [planEntry(true)] });
    pi.start();
    assert.deepEqual(pi.active, ["bash", "question", "read"]);
  });

  it("resumes in plan mode when the recorded entry is malformed", () => {
    const pi = fakePi({ branch: [{ type: "custom", customType: "plan-mode", data: {} }] });
    pi.start();
    assert.deepEqual(pi.active, ["bash", "question", "read"]);
  });
});

describe("plan mode after /tree navigation", () => {
  it("restores edit and write in build mode when the target entry was in plan mode", () => {
    const pi = fakePi();
    pi.start();
    pi.navigateTree({ tools: WITHOUT_MUTATING, branch: [planEntry(true)] });
    assert.deepEqual(pi.active, ["bash", "edit", "question", "read", "write"]);
    assert.deepEqual(pi.branch.at(-1), planEntry(false));
  });

  it("removes edit and write in plan mode when the target entry was in build mode", () => {
    const pi = fakePi();
    pi.start();
    pi.tab();
    pi.navigateTree({ tools: [...REGISTERED], branch: [planEntry(false)] });
    assert.deepEqual(pi.active, ["bash", "question", "read"]);
    assert.deepEqual(pi.branch.at(-1), planEntry(true));
  });

  it("does not record the mode again when the target branch has the same mode", () => {
    const pi = fakePi();
    pi.start();
    pi.tab();
    pi.navigateTree({ tools: WITHOUT_MUTATING, branch: [planEntry(true)] });
    assert.equal(pi.branch.length, 1);
  });

  it("keeps edit and write off in build mode when plan mode was never used (-nbt)", () => {
    const pi = fakePi({ active: WITHOUT_MUTATING });
    pi.start();
    pi.navigateTree({ tools: WITHOUT_MUTATING, branch: [] });
    assert.deepEqual(pi.active, ["bash", "question", "read"]);
  });

  it("restores edit and write on Tab off after /tree left them out", () => {
    const pi = fakePi();
    pi.start();
    pi.navigateTree({ tools: WITHOUT_MUTATING, branch: [] });
    pi.tab();
    pi.tab();
    assert.deepEqual(pi.active, ["bash", "edit", "question", "read", "write"]);
  });
});
