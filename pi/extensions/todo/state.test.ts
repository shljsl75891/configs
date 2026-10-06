import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { addTodo, EMPTY, ENTRY_TYPE, formatTodos, moveTodo, removeTodo, restoreState, TOOL_NAME, updateTodo } from "./state.ts";

const three = ["a", "b", "c"].reduce(addTodo, EMPTY);

describe("addTodo", () => {
	it("adds pending items with rising ids", () => {
		assert.deepEqual(three.todos, [
			{ id: 1, text: "a", status: "pending" },
			{ id: 2, text: "b", status: "pending" },
			{ id: 3, text: "c", status: "pending" },
		]);
	});

	it("does not reuse the id of a deleted item", () => {
		const next = addTodo(removeTodo(three, 3), "d");
		assert.equal(next.todos.at(-1)?.id, 4);
	});
});

describe("updateTodo", () => {
	it("changes text and status", () => {
		const next = updateTodo(three, 2, { text: "B", status: "in_progress" });
		assert.deepEqual(next.todos[1], { id: 2, text: "B", status: "in_progress" });
	});

	it("keeps fields that are undefined in the change", () => {
		const next = updateTodo(three, 2, { text: undefined, status: "done" });
		assert.deepEqual(next.todos[1], { id: 2, text: "b", status: "done" });
	});

	it("rejects a text change unless the item is pending", () => {
		const done = updateTodo(three, 1, { status: "done" });
		const active = updateTodo(three, 1, { status: "in_progress" });
		assert.throws(() => updateTodo(done, 1, { text: "x" }), /#1 is done/);
		assert.throws(() => updateTodo(active, 1, { text: "x" }), /#1 is in_progress/);
		assert.deepEqual(updateTodo(updateTodo(done, 1, { status: "pending" }), 1, { text: "x" }).todos[0].text, "x");
	});

	it("throws for an unknown id", () => {
		assert.throws(() => updateTodo(three, 9, { status: "done" }), /#9 not found/);
	});
});

describe("removeTodo", () => {
	it("removes the item", () => {
		assert.deepEqual(removeTodo(three, 2).todos.map((t) => t.id), [1, 3]);
	});

	it("throws for an unknown id", () => {
		assert.throws(() => removeTodo(three, 9), /#9 not found/);
	});
});

describe("moveTodo", () => {
	it("moves an item down", () => {
		assert.deepEqual(moveTodo(three, 1, 1).todos.map((t) => t.id), [2, 1, 3]);
	});

	it("moves an item up", () => {
		assert.deepEqual(moveTodo(three, 3, -1).todos.map((t) => t.id), [1, 3, 2]);
	});

	it("stops at the list ends", () => {
		assert.deepEqual(moveTodo(three, 1, -1).todos.map((t) => t.id), [1, 2, 3]);
		assert.deepEqual(moveTodo(three, 3, 1).todos.map((t) => t.id), [1, 2, 3]);
	});
});

describe("formatTodos", () => {
	it("says so when empty", () => {
		assert.equal(formatTodos(EMPTY), "No todos");
	});

	it("lists items with status marks", () => {
		const state = updateTodo(updateTodo(three, 1, { status: "done" }), 2, { status: "in_progress" });
		assert.equal(formatTodos(state), "[x] #1 a\n[~] #2 b\n[ ] #3 c");
	});
});

describe("empty text", () => {
	it("rejects blank text on add and update", () => {
		assert.throws(() => addTodo(EMPTY, "   "), /must not be empty/);
		assert.throws(() => updateTodo(three, 1, { text: "" }), /must not be empty/);
	});

	it("trims text", () => {
		assert.equal(addTodo(EMPTY, "  a  ").todos[0].text, "a");
	});
});

describe("rev", () => {
	it("rises with every change", () => {
		assert.equal(three.rev, 3);
		assert.equal(updateTodo(three, 1, { status: "done" }).rev, 4);
		assert.equal(moveTodo(three, 1, 1).rev, 4);
		assert.equal(removeTodo(three, 1).rev, 4);
	});

	it("does not rise for a no-op", () => {
		assert.equal(moveTodo(three, 1, -1).rev, 3);
	});
});

describe("no-op changes", () => {
	it("return the same state", () => {
		assert.equal(updateTodo(three, 1, { status: "pending" }), three);
	});
});

describe("restoreState", () => {
	const tool = (state: unknown) => ({ type: "message", message: { role: "toolResult", toolName: TOOL_NAME, details: state } });
	const saved = (state: unknown) => ({ type: "custom", customType: ENTRY_TYPE, data: state });
	const other = addTodo(EMPTY, "x");

	it("is empty for an empty branch", () => {
		assert.deepEqual(restoreState([]), EMPTY);
	});

	it("reads a tool result", () => {
		assert.deepEqual(restoreState([tool(three)]), three);
	});

	it("takes the highest rev, not the last entry", () => {
		const newer = updateTodo(three, 1, { status: "done" });
		assert.deepEqual(restoreState([tool(three), saved(newer)]), newer);
		assert.deepEqual(restoreState([saved(newer), tool(three)]), newer);
	});

	it("skips failed tool results", () => {
		assert.deepEqual(restoreState([tool(three), tool({})]), three);
	});

	it("skips state with a malformed item", () => {
		const bad = { ...other, todos: [{ id: 1, text: "x", status: "bogus" }] };
		assert.deepEqual(restoreState([tool(three), tool(bad), saved({ ...other, todos: [null] })]), three);
	});

	it("ignores other tools and entries", () => {
		const noise = [{ type: "message", message: { role: "toolResult", toolName: "bash", details: other } }, { type: "custom", customType: "x", data: other }];
		assert.deepEqual(restoreState([tool(three), ...noise]), three);
	});
});
