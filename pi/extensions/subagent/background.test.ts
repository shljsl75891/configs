import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { awaitForeground, createRunHandle, isActive } from "./background.ts";
import type { RunResult } from "./run-result.ts";

const ok = (agent: string): RunResult => ({ agent, agentSource: "user", task: "t", status: "ok", output: "out" });

function manual(agent: string) {
	let finish!: (r: RunResult) => void;
	const delivered: RunResult[] = [];
	const handle = createRunHandle(agent, "t", () => new Promise<RunResult>((r) => (finish = r)), (r) => delivered.push(r));
	return { handle, finish: () => finish(ok(agent)), delivered };
}

describe("run handle", () => {
	it("returns a backgrounded placeholder as soon as the run moves", async () => {
		const { handle } = manual("a");
		assert.equal(handle.moveToBackground(), true);
		assert.equal((await awaitForeground(handle)).status, "backgrounded");
		assert.equal(isActive(handle), false);
	});

	it("delivers a background result exactly once", async () => {
		const { handle, finish, delivered } = manual("a");
		handle.moveToBackground();
		handle.moveToBackground();
		finish();
		await handle.done;
		assert.equal(delivered.length, 1);
		assert.equal(delivered[0].output, "out");
	});

	it("does not deliver a foreground result", async () => {
		const { handle, finish, delivered } = manual("a");
		finish();
		assert.equal((await awaitForeground(handle)).status, "ok");
		assert.equal(handle.moveToBackground(), false);
		assert.equal(delivered.length, 0);
	});

	it("keeps waiting for runs that did not move", async () => {
		const a = manual("a");
		const b = manual("b");
		a.handle.moveToBackground();
		let settled = false;
		const all = Promise.all([a.handle, b.handle].map(awaitForeground)).then((r) => ((settled = true), r));
		await new Promise((r) => setTimeout(r, 20));
		assert.equal(settled, false);
		b.finish();
		const results = await all;
		assert.deepEqual(results.map((r) => r.status), ["backgrounded", "ok"]);
	});
});

describe("background delivery failure", () => {
	it("raises no unhandled rejection when the delivery callback throws", async () => {
		const rejections: unknown[] = [];
		const listener = (reason: unknown) => rejections.push(reason);
		process.on("unhandledRejection", listener);
		try {
			const handle = createRunHandle("a", "t", async () => ok("a"), () => {
				throw new Error("stale session");
			});
			handle.moveToBackground();
			await handle.done;
			await new Promise((r) => setImmediate(r));
			assert.deepEqual(rejections, []);
		} finally {
			process.off("unhandledRejection", listener);
		}
	});
});
