import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { answersOf, createState, type QuestionSpec, reduce } from "./state.ts";

const one: QuestionSpec[] = [{ question: "Pick one?", header: "Pick", options: [{ label: "A" }, { label: "B" }] }];

const many: QuestionSpec[] = [
	{ question: "Pick one?", header: "Pick", options: [{ label: "A" }, { label: "B" }] },
	{ question: "Pick some?", header: "Some", options: [{ label: "C" }, { label: "D" }], multiple: true },
];

describe("answers", () => {
	it("reports an unanswered question as an empty list", () => {
		assert.deepEqual(answersOf(createState(many), many), [[], []]);
	});

	it("reports selected labels, in option order", () => {
		let state = { ...createState(many), tab: 1 };
		state = reduce(state, { type: "choose", index: 1 }, many);
		state = reduce(state, { type: "choose", index: 0 }, many);
		assert.deepEqual(answersOf(state, many), [[], ["C", "D"]]);
	});

	it("reports a custom answer as its own text", () => {
		let state = reduce(createState(many), { type: "choose", index: 2 }, many);
		state = reduce(state, { type: "custom", text: "something else" }, many);
		assert.deepEqual(answersOf(state, many), [["something else"], []]);
	});
});

describe("choosing", () => {
	it("submits immediately when a lone single-select question is answered", () => {
		const state = reduce(createState(one), { type: "choose", index: 1 }, one);
		assert.deepEqual([...state.selected[0]], [1]);
		assert.equal(state.submitted, true);
	});

	it("replaces the previous choice in a single-select question", () => {
		let state = reduce(createState(many), { type: "choose", index: 0 }, many);
		state = reduce({ ...state, tab: 0 }, { type: "choose", index: 1 }, many);
		assert.deepEqual([...state.selected[0]], [1]);
	});

	it("advances to the next question instead of submitting when more remain", () => {
		const state = reduce(createState(many), { type: "choose", index: 0 }, many);
		assert.equal(state.tab, 1);
		assert.equal(state.submitted, false);
	});

	it("clears a custom answer when a checkbox is toggled", () => {
		let state = { ...createState(many), tab: 1 };
		state = reduce(state, { type: "choose", index: 2 }, many); // open editor on multi-select
		state = reduce(state, { type: "custom", text: "typed" }, many); // store custom
		assert.equal(state.custom[1], "typed");
		// Ticking a checkbox should evict the custom answer.
		state = reduce({ ...state, tab: 1, submitted: false }, { type: "choose", index: 0 }, many);
		assert.equal(state.custom[1], null, "custom cleared by toggle");
		assert.deepEqual(answersOf(state, many), [[], ["C"]]);
	});

	it("advances to next tab when a custom answer is submitted on a multi-select question", () => {
		let state = { ...createState(many), tab: 1 };
		state = reduce(state, { type: "custom", text: "my answer" }, many);
		assert.equal(state.tab, 2, "custom on multi-select must advance like single-select");
		assert.equal(state.custom[1], "my answer");
	});

	it("toggles without advancing in a multi-select question", () => {
		let state = { ...createState(many), tab: 1 };
		state = reduce(state, { type: "choose", index: 0 }, many);
		state = reduce(state, { type: "choose", index: 1 }, many);
		assert.deepEqual([...state.selected[1]], [0, 1]);
		assert.equal(state.tab, 1);

		state = reduce(state, { type: "choose", index: 0 }, many);
		assert.deepEqual([...state.selected[1]], [1]);
	});

	it("opens the editor when the custom row is chosen", () => {
		const state = reduce(createState(one), { type: "choose", index: 2 }, one);
		assert.equal(state.editing, true);
		assert.equal(state.submitted, false);
	});

	it("submits from the confirm tab", () => {
		const state = reduce({ ...createState(many), tab: 2 }, { type: "choose" }, many);
		assert.equal(state.submitted, true);
	});

	it("chooses whatever is under the cursor when no index is given", () => {
		let state = reduce(createState(one), { type: "cursor", delta: 1 }, one);
		state = reduce(state, { type: "choose" }, one);
		assert.deepEqual([...state.selected[0]], [1]);
	});
});

describe("custom answers", () => {
	it("stores the text, closes the editor and advances", () => {
		let state = reduce(createState(many), { type: "choose", index: 2 }, many);
		state = reduce(state, { type: "custom", text: "my own answer" }, many);
		assert.equal(state.custom[0], "my own answer");
		assert.equal(state.editing, false);
		assert.equal(state.tab, 1);
	});

	it("drops a fixed choice when a custom answer replaces it", () => {
		let state = reduce(createState(one), { type: "choose", index: 0 }, one);
		state = reduce({ ...state, submitted: false }, { type: "custom", text: "typed" }, one);
		assert.deepEqual([...state.selected[0]], []);
		assert.equal(state.custom[0], "typed");
	});

	it("returns to the option list without cancelling the batch", () => {
		let state = reduce(createState(one), { type: "choose", index: 2 }, one);
		state = reduce(state, { type: "cancelEdit" }, one);
		assert.equal(state.editing, false);
		assert.equal(state.submitted, false);
	});
});

describe("navigation", () => {
	it("starts on the first tab with the first option under the cursor", () => {
		const state = createState(one);
		assert.equal(state.tab, 0);
		assert.equal(state.cursor, 0);
	});

	it("moves the cursor down to the custom answer row and stops there", () => {
		let state = createState(one);
		state = reduce(state, { type: "cursor", delta: 1 }, one);
		state = reduce(state, { type: "cursor", delta: 1 }, one);
		assert.equal(state.cursor, 2);
		state = reduce(state, { type: "cursor", delta: 1 }, one);
		assert.equal(state.cursor, 2);
	});

	it("stops at the first option moving up", () => {
		const state = reduce(createState(one), { type: "cursor", delta: -1 }, one);
		assert.equal(state.cursor, 0);
	});

	it("moves between questions and the confirm tab, resetting the cursor", () => {
		let state = reduce(createState(many), { type: "cursor", delta: 1 }, many);
		state = reduce(state, { type: "tab", delta: 1 }, many);
		assert.equal(state.tab, 1);
		assert.equal(state.cursor, 0);
		state = reduce(state, { type: "tab", delta: 1 }, many);
		assert.equal(state.tab, 2, "confirm tab");
		state = reduce(state, { type: "tab", delta: 1 }, many);
		assert.equal(state.tab, 2, "clamped at the confirm tab");
	});

	it("jumps straight to a question by index", () => {
		let state = reduce({ ...createState(many), tab: 2 }, { type: "tabTo", index: 0 }, many);
		assert.equal(state.tab, 0);
		state = reduce(state, { type: "tabTo", index: 9 }, many);
		assert.equal(state.tab, 2, "clamped at the confirm tab");
	});

	it("has no confirm tab for a single question", () => {
		const state = reduce(createState(one), { type: "tab", delta: 1 }, one);
		assert.equal(state.tab, 0);
	});
});
