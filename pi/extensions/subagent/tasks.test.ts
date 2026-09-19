import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
	clampTimeout,
	DEFAULT_TIMEOUT_MS,
	MAX_CONCURRENT,
	MAX_TIMEOUT_MS,
	MIN_TIMEOUT_MS,
	normalizeTasks,
} from "./tasks.ts";

describe("normalizeTasks", () => {
	it("converts {agent, task} to a one-element array", () => {
		assert.deepEqual(normalizeTasks({ agent: "explore", task: "find main.ts" }), [
			{ agent: "explore", task: "find main.ts" },
		]);
	});

	it("passes a tasks array through unchanged", () => {
		const tasks = [
			{ agent: "a", task: "t1" },
			{ agent: "b", task: "t2" },
		];
		assert.deepEqual(normalizeTasks({ tasks }), tasks);
	});

	it("throws when neither form is supplied", () => {
		assert.throws(() => normalizeTasks({}), /Invalid parameters/);
	});

	it("throws when agent is supplied without task", () => {
		assert.throws(() => normalizeTasks({ agent: "a" }), /Invalid parameters/);
	});

	it("throws when both forms are supplied simultaneously", () => {
		assert.throws(
			() => normalizeTasks({ agent: "a", task: "t", tasks: [{ agent: "b", task: "t2" }] }),
			/Invalid parameters/,
		);
	});

	it("throws when tasks is empty array but agent/task are also supplied", () => {
		// An empty tasks array still signals the batch mode; mixing both modes must be rejected.
		assert.throws(
			() => normalizeTasks({ agent: "a", task: "t", tasks: [] }),
			/Invalid parameters/,
		);
	});

	it("throws when tasks array exceeds MAX_CONCURRENT", () => {
		const tasks = Array.from({ length: MAX_CONCURRENT + 1 }, (_, i) => ({ agent: "a", task: `t${i}` }));
		assert.throws(() => normalizeTasks({ tasks }), /Too many parallel tasks/);
	});
});

describe("clampTimeout", () => {
	it("returns DEFAULT_TIMEOUT_MS for undefined", () => {
		assert.equal(clampTimeout(undefined), DEFAULT_TIMEOUT_MS);
	});

	it("returns DEFAULT_TIMEOUT_MS for NaN", () => {
		assert.equal(clampTimeout(NaN), DEFAULT_TIMEOUT_MS);
	});

	it("clamps a value below MIN_TIMEOUT_MS up to MIN_TIMEOUT_MS", () => {
		assert.equal(clampTimeout(1), MIN_TIMEOUT_MS);
	});

	it("clamps a value above MAX_TIMEOUT_MS down to MAX_TIMEOUT_MS", () => {
		assert.equal(clampTimeout(MAX_TIMEOUT_MS * 2), MAX_TIMEOUT_MS);
	});

	it("passes a value within range through unchanged", () => {
		const mid = Math.floor((MIN_TIMEOUT_MS + MAX_TIMEOUT_MS) / 2);
		assert.equal(clampTimeout(mid), mid);
	});
});
