import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, describe, it } from "node:test";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import promptModel from "./index.ts";

const dir = mkdtempSync(join(tmpdir(), "prompt-model-test-"));
after(() => rmSync(dir, { recursive: true }));
let count = 0;

function template(frontmatter: string): string {
	const path = join(dir, `t${count++}.md`);
	writeFileSync(path, `---\ndescription: x\n${frontmatter}\n---\nbody`);
	return path;
}

/** Runs the extension's input handler against a fake pi runtime. */
async function run(
	text: string,
	path: string,
	opts: { current?: string; auth?: boolean; streaming?: boolean; source?: string } = {},
) {
	const calls: string[] = [];
	const notes: string[] = [];
	let handler: (event: object, ctx: object) => Promise<unknown> = async () => undefined;
	const pi = {
		on: (_: string, h: typeof handler) => (handler = h),
		getCommands: () => [{ name: "go", source: opts.source ?? "prompt", sourceInfo: { path } }],
		setModel: async (m: { provider: string; id: string }) => {
			calls.push(`model:${m.provider}/${m.id}`);
			return opts.auth ?? true;
		},
		setThinkingLevel: (l: string) => calls.push(`thinking:${l}`),
	};
	const ctx = {
		model: opts.current && { provider: opts.current.split("/")[0], id: opts.current.split("/")[1] },
		modelRegistry: {
			find: (provider: string, id: string) => (id === "missing" ? undefined : { provider, id }),
		},
		ui: { notify: (m: string) => notes.push(m) },
	};
	promptModel(pi as unknown as ExtensionAPI);
	await handler({ text, streamingBehavior: opts.streaming ? "steer" : undefined }, ctx);
	return { calls, notes };
}

describe("prompt-model", () => {
	it("switches model and thinking level", async () => {
		const { calls } = await run("/go arg", template("model: anthropic/claude-opus-5-5:high"));
		assert.deepEqual(calls, ["model:anthropic/claude-opus-5-5", "thinking:high"]);
	});

	it("keeps a colon in the model id when the suffix is not a level", async () => {
		const { calls } = await run("/go", template("model: ollama/qwen:7b"));
		assert.deepEqual(calls, ["model:ollama/qwen:7b"]);
	});

	it("skips setModel when the model is current but still sets thinking", async () => {
		const { calls } = await run("/go", template("model: a/b:low"), { current: "a/b" });
		assert.deepEqual(calls, ["thinking:low"]);
	});

	it("does nothing for a blank model key", async () => {
		const { calls, notes } = await run("/go", template("model:"));
		assert.deepEqual([calls, notes], [[], []]);
	});

	it("does nothing without a model key", async () => {
		const { calls, notes } = await run("/go", template(""));
		assert.deepEqual([calls, notes], [[], []]);
	});

	it("does nothing for streaming input", async () => {
		const { calls } = await run("/go", template("model: a/b"), { streaming: true });
		assert.deepEqual(calls, []);
	});

	it("warns when the model is not found", async () => {
		const { calls, notes } = await run("/go", template("model: a/missing"));
		assert.deepEqual([calls, notes], [[], ['/go: model "a/missing" not found']]);
	});

	it("warns when auth is missing", async () => {
		const { notes } = await run("/go", template("model: a/b"), { auth: false });
		assert.deepEqual(notes, ["/go: no auth for a"]);
	});

	it("treats ':constructor' as part of the model id", async () => {
		const { calls } = await run("/go", template("model: a/b:constructor"));
		assert.deepEqual(calls, ["model:a/b:constructor"]);
	});

	it("warns when model is not a string", async () => {
		const { calls, notes } = await run("/go", template("model: 5"));
		assert.deepEqual([calls, notes], [[], ['/go: "model" must be a string']]);
	});

	it("warns when the key has no provider", async () => {
		const { notes } = await run("/go", template("model: foo"));
		assert.deepEqual(notes, ['/go: model "foo" must be provider/id']);
	});

	it("ignores commands that are not prompt templates", async () => {
		const { calls } = await run("/go", template("model: a/b"), { source: "extension" });
		assert.deepEqual(calls, []);
	});

	it("ignores input that is not a command", async () => {
		const { calls } = await run("hello", template("model: a/b"));
		assert.deepEqual(calls, []);
	});
});
