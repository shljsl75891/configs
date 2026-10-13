import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { checkTodos, formatTodos, hasInProgress, openTodos, restoreTodos, TOOL_NAME, type Todo } from "./state.ts";

const list: Todo[] = [
	{ content: "a", status: "completed" },
	{ content: "b", status: "in_progress" },
	{ content: "c", status: "pending" },
	{ content: "d", status: "cancelled" },
];

describe("checkTodos", () => {
	it("accepts a valid list and trims content", () => {
		assert.deepEqual(checkTodos([{ content: "  a ", status: "pending" }]), [{ content: "a", status: "pending" }]);
	});

	it("accepts an empty list", () => {
		assert.deepEqual(checkTodos([]), []);
	});

	it("rejects empty content", () => {
		assert.throws(() => checkTodos([{ content: "  ", status: "pending" }]), /empty/);
	});

	it("rejects two in_progress items", () => {
		assert.throws(
			() =>
				checkTodos([
					{ content: "a", status: "in_progress" },
					{ content: "b", status: "in_progress" },
				]),
			/one in_progress/,
		);
	});
});

describe("hasInProgress / openTodos", () => {
	it("finds an in_progress item", () => {
		assert.equal(hasInProgress(list), true);
		assert.equal(hasInProgress([list[0], list[2]]), false);
		assert.equal(hasInProgress([]), false);
	});

	it("lists pending and in_progress items only", () => {
		assert.deepEqual(openTodos(list), [list[1], list[2]]);
	});
});

describe("formatTodos", () => {
	it("marks each status", () => {
		assert.equal(formatTodos(list), "[x] a\n[~] b\n[ ] c\n[-] d");
	});

	it("says when the list is empty", () => {
		assert.equal(formatTodos([]), "No todos");
	});
});

describe("restoreTodos", () => {
	const result = (todos: unknown, toolName = TOOL_NAME) => ({ type: "message", message: { role: "toolResult", toolName, details: { todos } } });

	it("is empty for an empty branch", () => {
		assert.deepEqual(restoreTodos([]), []);
	});

	it("takes the last todo result", () => {
		assert.deepEqual(restoreTodos([result([list[2]]), result(list)]), list);
	});

	it("restores an emptied list", () => {
		assert.deepEqual(restoreTodos([result(list), result([])]), []);
	});

	it("skips malformed and old-format results", () => {
		const old = { type: "message", message: { role: "toolResult", toolName: TOOL_NAME, details: { todos: [{ id: 1, text: "x", status: "done" }], nextId: 2, rev: 1 } } };
		assert.deepEqual(restoreTodos([result(list), old, result([{ content: "x", status: "bogus" }]), result([null])]), list);
	});

	it("ignores other tools", () => {
		assert.deepEqual(restoreTodos([result(list), result([list[2]], "bash")]), list);
	});
});
