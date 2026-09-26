import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, it } from "node:test";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import permission from "./index.ts";

/** Settings read by the extension via readAgentSetting("permission"). */
function useSettings(permissionConfig: unknown): void {
  const dir = mkdtempSync(join(tmpdir(), "permission-test-"));
  writeFileSync(join(dir, "settings.json"), JSON.stringify({ permission: permissionConfig }));
  process.env.PI_CODING_AGENT_DIR = dir;
}

type Handler = (event: object, ctx: object) => unknown;
type BlockResult = { block?: boolean } | undefined;

/** Fake of the pi runtime: captures the tool_call handler and drives plan mode via events. */
function fakePi(argv: string[] = []) {
  const prevArgv = process.argv;
  process.argv = ["node", "pi", ...argv];
  const handlers = new Map<string, Handler>();
  const planHandlers: ((data: { enabled: boolean }) => void)[] = [];
  const pi = {
    registerCommand() {},
    events: { on: (_channel: string, handler: (data: { enabled: boolean }) => void) => planHandlers.push(handler) },
    on: (event: string, handler: Handler) => handlers.set(event, handler),
  };
  permission(pi as unknown as ExtensionAPI);
  process.argv = prevArgv;
  const ctx = (hasUI: boolean) => ({ ui: { setStatus() {}, notify() {} }, hasUI, cwd: "/proj", signal: undefined });
  return {
    setPlanMode: (enabled: boolean) => planHandlers.forEach((h) => h({ enabled })),
    call: (toolName: string, input: object, hasUI = true) =>
      handlers.get("tool_call")!({ toolName, input }, ctx(hasUI)) as Promise<BlockResult>,
  };
}

describe("permission tool_call", () => {
  it("allows an unmatched tool with no settings", async () => {
    useSettings(undefined);
    const pi = fakePi();
    assert.equal(await pi.call("read", { path: "src/a.ts" }), undefined);
  });

  it("denies edit in plan mode even with no permission.plan configured", async () => {
    useSettings(undefined);
    const pi = fakePi();
    pi.setPlanMode(true);
    assert.equal((await pi.call("edit", { path: "src/a.ts" }))?.block, true);
  });

  it("denies common bash writes in plan mode even with no permission.plan configured", async () => {
    useSettings(undefined);
    const pi = fakePi();
    pi.setPlanMode(true);
    assert.equal((await pi.call("bash", { command: "rm -rf x" }))?.block, true);
  });

  it("keeps denying other paths when permission.plan.edit is a partial rules object", async () => {
    useSettings({ plan: { edit: { "*.md": "allow" } } });
    const pi = fakePi();
    pi.setPlanMode(true);
    assert.equal((await pi.call("edit", { path: "src/a.ts" }))?.block, true);
    assert.equal(await pi.call("edit", { path: "notes.md" }), undefined);
  });

  it("--approve allows an ask action even without a UI", async () => {
    useSettings({ bash: { "*": "ask" } });
    const pi = fakePi(["--approve"]);
    assert.equal(await pi.call("bash", { command: "ls" }, false), undefined);
  });

  it("blocks an ask action with no UI and no --approve", async () => {
    useSettings({ bash: { "*": "ask" } });
    const pi = fakePi();
    assert.equal((await pi.call("bash", { command: "ls" }, false))?.block, true);
  });

  it("does not deny mkdir via the code fallback (that's settings.json's job)", async () => {
    useSettings(undefined);
    const pi = fakePi();
    pi.setPlanMode(true);
    assert.equal(await pi.call("bash", { command: "mkdir x" }), undefined);
  });

  it("permission.plan.bash, when present, fully replaces the code fallback instead of merging", async () => {
    useSettings({ plan: { bash: { "*": "allow" } } });
    const pi = fakePi();
    pi.setPlanMode(true);
    // The fallback's "rm *": "deny" would apply if bash were merged like edit/write are.
    assert.equal(await pi.call("bash", { command: "rm -rf x" }), undefined);
  });

  it("defaults everything to ask when settings.json contains invalid JSON", async () => {
    const dir = mkdtempSync(join(tmpdir(), "permission-test-"));
    writeFileSync(join(dir, "settings.json"), "{ not valid json");
    process.env.PI_CODING_AGENT_DIR = dir;
    const pi = fakePi();
    assert.equal((await pi.call("bash", { command: "ls" }, false))?.block, true);
  });
});
