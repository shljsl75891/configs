import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { describe, it } from "node:test";
import { waitForResult } from "./wait.ts";

// ─── waitForResult ────────────────────────────────────────────────────────────

describe("waitForResult", () => {
	it("returns result when the file appears", async () => {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-wait-test-"));
		try {
			const resultFile = path.join(dir, "result.json");
			setTimeout(() => fs.writeFileSync(resultFile, JSON.stringify({ status: "ok", output: "hello" })), 30);
			const outcome = await waitForResult({
				windowId: "@1",
				resultFile,
				timeoutMs: 2000,
				checkWindowAlive: async () => true,
				pollIntervalMs: 10,
			});
			assert.equal(outcome.kind, "result");
			assert.ok(outcome.kind === "result" && outcome.result.output === "hello");
		} finally {
			fs.rmSync(dir, { recursive: true, force: true });
		}
	});

	it("returns corrupt after 3 consecutive invalid files", async () => {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-wait-test-"));
		try {
			const resultFile = path.join(dir, "result.json");
			fs.writeFileSync(resultFile, "broken-json");
			const outcome = await waitForResult({
				windowId: "@1",
				resultFile,
				timeoutMs: 5000,
				checkWindowAlive: async () => true,
				pollIntervalMs: 10,
			});
			assert.equal(outcome.kind, "corrupt");
		} finally {
			fs.rmSync(dir, { recursive: true, force: true });
		}
	});

	it("returns windowGone when window exits without writing", async () => {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-wait-test-"));
		try {
			const resultFile = path.join(dir, "result.json");
			// No result file; liveness check fires after every 4th poll.
			const outcome = await waitForResult({
				windowId: "@1",
				resultFile,
				timeoutMs: 5000,
				checkWindowAlive: async () => false,
				pollIntervalMs: 10,
			});
			assert.equal(outcome.kind, "windowGone");
		} finally {
			fs.rmSync(dir, { recursive: true, force: true });
		}
	});

	it("returns aborted when signal fires mid-run", async () => {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-wait-test-"));
		try {
			const resultFile = path.join(dir, "result.json");
			const controller = new AbortController();
			setTimeout(() => controller.abort(), 30);
			const outcome = await waitForResult({
				windowId: "@1",
				resultFile,
				timeoutMs: 5000,
				signal: controller.signal,
				checkWindowAlive: async () => true,
				pollIntervalMs: 10,
			});
			assert.equal(outcome.kind, "aborted");
		} finally {
			fs.rmSync(dir, { recursive: true, force: true });
		}
	});

	it("returns aborted for a pre-aborted signal", async () => {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-wait-test-"));
		try {
			const resultFile = path.join(dir, "result.json");
			const controller = new AbortController();
			controller.abort();
			const outcome = await waitForResult({
				windowId: "@1",
				resultFile,
				timeoutMs: 5000,
				signal: controller.signal,
				checkWindowAlive: async () => true,
				pollIntervalMs: 10,
			});
			assert.equal(outcome.kind, "aborted");
		} finally {
			fs.rmSync(dir, { recursive: true, force: true });
		}
	});

	it("returns timeout when deadline passes", async () => {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-wait-test-"));
		try {
			const resultFile = path.join(dir, "result.json");
			const outcome = await waitForResult({
				windowId: "@1",
				resultFile,
				timeoutMs: 50,
				checkWindowAlive: async () => true,
				pollIntervalMs: 10,
			});
			assert.equal(outcome.kind, "timeout");
		} finally {
			fs.rmSync(dir, { recursive: true, force: true });
		}
	});

	it("fires onReview(true/false) and clears review when result lands before marker is removed", async () => {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-wait-test-"));
		try {
			const resultFile = path.join(dir, "result.json");
			// Marker present from the start; result written 40ms later but marker left in place.
			fs.writeFileSync(`${resultFile}.review`, "");
			const seen: boolean[] = [];
			setTimeout(() => fs.writeFileSync(resultFile, JSON.stringify({ status: "ok", output: "x" })), 40);
			const outcome = await waitForResult({
				windowId: "@1",
				resultFile,
				timeoutMs: 2000,
				checkWindowAlive: async () => true,
				pollIntervalMs: 10,
				onReview: (r) => seen.push(r),
			});
			assert.equal(outcome.kind, "result");
			// The finally block must emit false even though the marker was never removed.
			assert.deepEqual(seen, [true, false]);
		} finally {
			fs.rmSync(dir, { recursive: true, force: true });
		}
	});

	it("does not time out while the review marker is present", async () => {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-wait-test-"));
		try {
			const resultFile = path.join(dir, "result.json");
			fs.writeFileSync(`${resultFile}.review`, "");
			// Remove the marker after 120ms; budget is 40ms, so without the marker the wait would expire immediately.
			setTimeout(() => fs.rmSync(`${resultFile}.review`, { force: true }), 120);
			const started = Date.now();
			const outcome = await waitForResult({
				windowId: "@1",
				resultFile,
				timeoutMs: 40,
				checkWindowAlive: async () => true,
				pollIntervalMs: 10,
			});
			const elapsed = Date.now() - started;
			assert.equal(outcome.kind, "timeout");
			// Budget is 40ms; marker removed at 120ms. If the clock ran during review it would finish at ~40ms.
			assert.ok(elapsed >= 100, `timed out after ${elapsed}ms — review did not pause the clock`);
		} finally {
			fs.rmSync(dir, { recursive: true, force: true });
		}
	});

	it("returns corrupt for valid JSON missing required fields", async () => {
		const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-wait-test-"));
		try {
			const resultFile = path.join(dir, "result.json");
			// Parses as JSON but fails the SubagentResult shape check (missing output).
			fs.writeFileSync(resultFile, JSON.stringify({ status: "ok" }));
			const outcome = await waitForResult({
				windowId: "@1",
				resultFile,
				timeoutMs: 5000,
				checkWindowAlive: async () => true,
				pollIntervalMs: 10,
			});
			assert.equal(outcome.kind, "corrupt");
		} finally {
			fs.rmSync(dir, { recursive: true, force: true });
		}
	});
});
