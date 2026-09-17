import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";
import { describe, it } from "node:test";
import { findPiRoot } from "./prompt.ts";

describe("findPiRoot", () => {
	it("finds the package root that holds the clipboard internals", () => {
		const cli = execFileSync("which", ["pi"], { encoding: "utf-8" }).trim();
		const root = findPiRoot(cli);
		assert.ok(root, "expected a root");
		assert.ok(fs.existsSync(path.join(root, "dist/utils/clipboard-image.js")));
		assert.ok(fs.existsSync(path.join(root, "dist/utils/clipboard.js")));
	});

	it("gives up on a path that is nowhere near pi", () => {
		assert.equal(findPiRoot("/usr/bin/env"), null);
	});
});
