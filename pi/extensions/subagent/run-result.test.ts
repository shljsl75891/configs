import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { formatResult, toRunResult } from "./run-result.ts";

const base = { agent: "explore", agentSource: "user" as const, task: "find main.ts", windowId: "@3" };
const ctx = { resultFile: "/tmp/pi-tmux-subagent-x/result.json", timeoutMs: 60_000 };

describe("toRunResult", () => {
	it("maps aborted to status aborted, keeping windowId", () => {
		const r = toRunResult({ kind: "aborted" }, base, ctx);
		assert.equal(r.status, "aborted");
		assert.equal(r.errorMessage, "Aborted.");
		assert.equal(r.windowId, "@3", "an aborted window was just killed but is still identifiable");
	});

	it("maps windowGone to an error and omits windowId", () => {
		const r = toRunResult({ kind: "windowGone" }, base, ctx);
		assert.equal(r.status, "error");
		assert.ok(r.errorMessage?.includes("closed"));
		assert.equal(r.windowId, undefined, "the window is provably dead; a hint pointing at it would mislead");
	});

	it("maps corrupt to an error naming the unreadable file", () => {
		const r = toRunResult({ kind: "corrupt", detail: "not json" }, base, ctx);
		assert.equal(r.status, "error");
		assert.ok(r.errorMessage?.includes(ctx.resultFile));
		assert.ok(r.errorMessage?.includes("not json"));
		assert.equal(r.windowId, "@3");
	});

	it("maps timeout to status timeout with the requested duration", () => {
		const r = toRunResult({ kind: "timeout" }, base, ctx);
		assert.equal(r.status, "timeout");
		assert.ok(r.errorMessage?.includes("60000ms"));
	});

	it("passes through a successful child result", () => {
		const r = toRunResult(
			{ kind: "result", result: { status: "ok", output: "done", stopReason: "end_turn" } },
			base,
			ctx,
		);
		assert.equal(r.status, "ok");
		assert.equal(r.output, "done");
		assert.equal(r.stopReason, "end_turn");
		assert.equal(r.errorMessage, undefined);
	});

	it("falls back to a generic message when a failed child result has no errorMessage", () => {
		const r = toRunResult({ kind: "result", result: { status: "error", output: "" } }, base, ctx);
		assert.equal(r.status, "error");
		assert.equal(r.errorMessage, "Agent failed.");
	});

	it("keeps the child's own errorMessage when present", () => {
		const r = toRunResult(
			{ kind: "result", result: { status: "error", output: "", errorMessage: "disk full" } },
			base,
			ctx,
		);
		assert.equal(r.errorMessage, "disk full");
	});
});

describe("formatResult", () => {
	it("includes the window hint for a result with a window that stayed open", () => {
		const r = toRunResult({ kind: "timeout" }, base, ctx);
		const text = formatResult(r);
		assert.ok(text.includes("tmux select-window -t @3"));
	});

	it("omits the window hint once the window is gone (aborted or windowGone)", () => {
		const aborted = toRunResult({ kind: "aborted" }, base, ctx);
		assert.ok(!formatResult(aborted).includes("select-window"));

		const gone = toRunResult({ kind: "windowGone" }, base, ctx);
		assert.ok(!formatResult(gone).includes("select-window"), "windowGone has no windowId to hint at");
	});

	it("tags project-sourced agents in the header", () => {
		const r = toRunResult({ kind: "timeout" }, { ...base, agentSource: "project" }, ctx);
		assert.ok(formatResult(r).startsWith("[explore (project)] timeout"));
	});

	it("uses the error message as the body for a failed result", () => {
		const r = toRunResult(
			{ kind: "result", result: { status: "error", output: "partial output", errorMessage: "boom" } },
			base,
			ctx,
		);
		assert.ok(formatResult(r).includes("boom"));
		assert.ok(!formatResult(r).includes("partial output"), "error body prefers errorMessage over raw output");
	});
});
