import assert from "node:assert/strict";
import { describe, it } from "node:test";
import Value from "typebox/value";
import { QuestionParams } from "./index.ts";
import { questionLineBudget } from "./prompt.ts";

const withOption = (option: object) => ({ questions: [{ question: "Q?", header: "Q", options: [option] }] });

describe("question schema", () => {
	it("accepts an option that has a description", () => {
		assert.equal(Value.Check(QuestionParams, withOption({ label: "A", description: "Does A" })), true);
	});

	it("rejects an option without a description", () => {
		assert.equal(Value.Check(QuestionParams, withOption({ label: "A" })), false);
	});
});

describe("questionLineBudget", () => {
	it("grows with terminal rows", () => {
		assert.equal(questionLineBudget(30), 18);
	});

	it("caps at 26 lines on tall terminals", () => {
		assert.equal(questionLineBudget(200), 26);
	});

	it("keeps at least 3 lines on short terminals", () => {
		assert.equal(questionLineBudget(5), 3);
	});
});
