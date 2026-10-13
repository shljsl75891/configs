import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { blockReason, shouldRemind } from "./gate.ts";
import type { Todo } from "./state.ts";

const none: Todo[] = [];
const active: Todo[] = [{ content: "a", status: "in_progress" }];
const readOnly = async (command: string) => command.startsWith("rg ");

describe("blockReason", () => {
	it("blocks edit and write without an in_progress item", async () => {
		assert.match((await blockReason(none, "edit", {}, readOnly)) ?? "", /todo/);
		assert.match((await blockReason([{ content: "a", status: "pending" }], "write", {}, readOnly)) ?? "", /todo/);
		assert.match((await blockReason([{ content: "a", status: "completed" }], "edit", {}, readOnly)) ?? "", /todo/);
	});

	it("lets edit and write pass with an in_progress item", async () => {
		assert.equal(await blockReason(active, "edit", {}, readOnly), undefined);
	});

	it("blocks a writing bash command but not a read-only one", async () => {
		assert.match((await blockReason(none, "bash", { command: "sed -i s/a/b/ f" }, readOnly)) ?? "", /todo/);
		assert.equal(await blockReason(none, "bash", { command: "rg foo" }, readOnly), undefined);
	});

	it("never blocks other tools", async () => {
		assert.equal(await blockReason(none, "read", {}, readOnly), undefined);
		assert.equal(await blockReason(none, "todo", {}, readOnly), undefined);
	});
});

describe("shouldRemind", () => {
	const open: Todo[] = [{ content: "a", status: "pending" }];

	it("waits for 5 turns without a todo call", () => {
		assert.equal(shouldRemind(open, 4), false);
		assert.equal(shouldRemind(open, 5), true);
	});

	it("stays quiet with no open items", () => {
		assert.equal(shouldRemind([{ content: "a", status: "completed" }], 9), false);
		assert.equal(shouldRemind([], 9), false);
	});
});
