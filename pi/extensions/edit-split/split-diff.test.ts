import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { visibleWidth } from "@earendil-works/pi-tui";
import { SplitDiff, changedSpans, chunks, parseRows, type DiffTheme } from "./split-diff.ts";

const COLORS: Record<string, string> = {
	toolDiffRemoved: "251;73;52",
	toolDiffAdded: "184;187;38",
	toolDiffContext: "146;131;116",
	dim: "168;153;132",
	borderMuted: "102;92;84",
};
const theme: DiffTheme = {
	getFgAnsi: (key) => `\x1b[38;2;${COLORS[key]}m`,
	fg: (key, text) => `\x1b[38;2;${COLORS[key]}m${text}\x1b[39m`,
};
const strip = (line: string) => line.replace(/\x1b\[[0-9;]*m/g, "");
const view = (diff: string, minWidth?: number) =>
	new SplitDiff({ diff, theme, fallback: { render: () => ["FALLBACK"] }, baseBg: "\x1b[48;2;37;41;38m", minWidth });

describe("parseRows", () => {
	it("pairs removed and added lines and numbers context rows on both sides", () => {
		const rows = parseRows([" 1 a", "-2 b", "-3 c", "+2 B", " 4 d"].join("\n"));
		assert.deepEqual(rows[0], { kind: "context", left: { num: "1", text: "a" }, right: { num: "1", text: "a" } });
		assert.deepEqual(rows[1], { kind: "change", left: { num: "2", text: "b" }, right: { num: "2", text: "B" } });
		assert.deepEqual(rows[2], { kind: "change", left: { num: "3", text: "c" }, right: undefined });
		assert.deepEqual(rows[3], { kind: "context", left: { num: "4", text: "d" }, right: { num: "3", text: "d" } });
	});

	it("handles a pure insertion and a reversed block order", () => {
		const rows = parseRows(["+1 new", " 1 keep"].join("\n"));
		assert.deepEqual(rows[0], { kind: "change", left: undefined, right: { num: "1", text: "new" } });
		assert.equal(rows[1]?.kind === "context" && rows[1].right?.num, "2");
	});

	it("marks a skipped block", () => {
		const rows = parseRows([" 1 a", "    ...", " 9 b"].join("\n"));
		assert.deepEqual(rows.map((row) => row.kind), ["context", "skip", "context"]);
	});

	it("keeps lines with Unicode line separators and empty text", () => {
		const rows = parseRows(["-1 a\u2028b", "+1 "].join("\n"));
		assert.deepEqual(rows[0], { kind: "change", left: { num: "1", text: "a\u2028b" }, right: { num: "1", text: "" } });
	});
});

describe("changedSpans", () => {
	it("finds the middle that differs", () => {
		assert.deepEqual(changedSpans("abcXYZdef", "abc12def"), [[3, 6], [3, 5]]);
	});

	it("never cuts a surrogate pair", () => {
		const [oldSpan] = changedSpans("x😀y", "x😁y");
		assert.deepEqual(oldSpan, [1, 3]);
	});

	it("gives an empty span for equal text", () => {
		const [oldSpan, newSpan] = changedSpans("same", "same");
		assert.equal(oldSpan[0], oldSpan[1]);
		assert.equal(newSpan[0], newSpan[1]);
	});
});

describe("chunks", () => {
	it("keeps short text whole", () => {
		assert.deepEqual(chunks("abc", 10), [{ text: "abc", offset: 0, width: 3 }]);
	});

	it("splits long text with right offsets and widths", () => {
		const parts = chunks("abcdefghij", 4);
		assert.deepEqual(parts.map((p) => p.text), ["abcd", "efgh", "ij"]);
		assert.deepEqual(parts.map((p) => p.offset), [0, 4, 8]);
		assert.deepEqual(parts.map((p) => p.width), [4, 4, 2]);
	});

	it("does not split wide characters", () => {
		const parts = chunks("日本語日本語", 5);
		assert.ok(parts.every((p) => p.width <= 5 && visibleWidth(p.text) === p.width));
		assert.equal(parts.map((p) => p.text).join(""), "日本語日本語");
	});

	it("handles a very long line in linear time", () => {
		// The old quadratic version took seconds here, so a hang is the failure mode.
		assert.equal(chunks("x".repeat(200_000), 40).length, 5000);
	});
});

describe("SplitDiff", () => {
	const diff = [" 1 keep", "-2 old text", "+2 new text", "    ...", " 9 end"].join("\n");

	it("falls back below the minimum width", () => {
		assert.deepEqual(view(diff).render(60), ["FALLBACK"]);
	});

	for (const width of [100, 101, 120, 133]) {
		it(`fills every row to exactly ${width} columns`, () => {
			const lines = view(diff).render(width);
			assert.equal(lines.length, 4);
			for (const line of lines) assert.equal(visibleWidth(line), width);
		});
	}

	it("wraps a long line, repeats no number and keeps both sides aligned", () => {
		const long = "word ".repeat(60);
		const lines = view([`-7 ${long}`, `+7 ${long}more`].join("\n")).render(100).map(strip);
		assert.ok(lines.length > 2);
		assert.equal(lines.filter((line) => line.includes("7 -")).length, 1);
		for (const line of lines) assert.equal(line.split("│").length, 2);
	});

	it("never resets the background to the terminal default", () => {
		const lines = view(diff).render(120);
		assert.ok(lines.every((line) => !line.includes("\x1b[0m") && !line.includes("\x1b[49m")));
	});

	it("returns the same array for the same width until invalidated", () => {
		const v = view(diff);
		const first = v.render(120);
		assert.equal(v.render(120), first);
		assert.notEqual(v.render(121), first);
		v.invalidate();
		assert.notEqual(v.render(121), first);
	});

	it("draws wide characters and emoji without overflow", () => {
		const lines = view([`-1 ${"日本語😀テキスト".repeat(10)}`, `+1 ${"日本語😁テキスト".repeat(10)}`].join("\n")).render(101);
		for (const line of lines) assert.equal(visibleWidth(line), 101);
	});
});
