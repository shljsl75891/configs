import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { describe, it } from "node:test";
import { buildPiCommand, shellQuote } from "./command.ts";
import { formatWindowName, MAX_WINDOW_NAME_LENGTH } from "./window-name.ts";

describe("shellQuote", () => {
	it("wraps a plain value in single quotes", () => {
		assert.equal(shellQuote("hello"), "'hello'");
	});

	it("escapes embedded single quotes so the result is a single shell word", () => {
		// ' → '"'"' keeps the entire value as one $IFS-split token.
		assert.equal(shellQuote("it's"), `'it'"'"'s'`);
	});

	it("survives a round trip through sh as exactly one argument", () => {
		const malicious = `rm -rf /'; echo pwned; '$(id)`;
		const out = execFileSync("sh", ["-c", `printf %s ${shellQuote(malicious)}`], { encoding: "utf-8" });
		assert.equal(out, malicious);
	});
});

describe("buildPiCommand", () => {
	it("omits --tools when the agent inherits every tool", () => {
		assert.ok(!buildPiCommand({ task: "x" }).includes("--tools"));
	});

	it("includes --tools when tools are specified", () => {
		assert.ok(buildPiCommand({ task: "x", tools: ["bash", "read"] }).includes("--tools"));
	});

	it("includes --model when specified", () => {
		assert.ok(buildPiCommand({ task: "x", model: "anthropic/claude-3" }).includes("--model"));
	});

	it("shell-quotes the task so injection is impossible", () => {
		const malicious = `rm -rf /'; echo pwned; '$(id)`;
		const cmd = buildPiCommand({ task: malicious });
		const out = execFileSync("sh", ["-c", `printf '%s\n' ${cmd}`], { encoding: "utf-8" });
		assert.ok(out.includes(malicious), "task must survive shell round-trip unchanged");
	});
});

describe("formatWindowName", () => {
	it("uses ⋯ for running, ✓ for ok, ✗ for error", () => {
		assert.ok(formatWindowName("running", "explore", 1).includes("⋯"));
		assert.ok(formatWindowName("ok", "explore", 1).includes("✓"));
		assert.ok(formatWindowName("error", "explore", 1).includes("✗"));
	});

	it("prefixes nested agents with L<depth>", () => {
		assert.ok(formatWindowName("running", "x", 2).startsWith("L2 "));
		assert.ok(!formatWindowName("running", "x", 1).startsWith("L"));
	});

	it("truncates to the window-name budget without splitting surrogates", () => {
		const name = formatWindowName("running", "a".repeat(40), 2);
		// Code-point length, not UTF-16 unit length (relevant for emoji/CJK).
		assert.equal([...name].length, MAX_WINDOW_NAME_LENGTH);
	});

	it("truncates a name containing emoji without splitting a surrogate pair", () => {
		// 🐙 is U+1F419 — two UTF-16 units. With depth=2 the prefix is "L2 ⋯ "
		// (5 UTF-16 units); old String.prototype.slice(0,30) would cut at offset 30
		// inside a surrogate pair, producing a broken string. Code-point slicing avoids this.
		const name = formatWindowName("running", "🐙".repeat(30), 2);
		assert.equal([...name].length, MAX_WINDOW_NAME_LENGTH);
	});
});
