/**
 * Tests for the pending/delivered/followUp state machine in markerExtension.
 *
 * @earendil-works/pi-tui is resolved from a stub in node_modules/@earendil-works/
 * in this directory so the extension can be imported without pi's custom loader.
 * That stub is committed (see the negation patterns in .gitignore) so `node --test`
 * works on a fresh clone.
 *
 * The file-system is the observable boundary: we assert on result-file presence,
 * review-marker presence, and result-file contents — never on internal state values.
 */
import { afterEach, beforeEach, describe, it } from "node:test";
import * as assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { ENV, reviewMarkerFor } from "./protocol.ts";
import markerExtension from "./marker-extension.ts";

type Handler = (event: object, ctx: object) => Promise<void>;

type FakePi = {
	on(event: string, handler: Handler): void;
	exec(cmd: string, args: string[]): Promise<{ code: number; stdout: string; stderr: string }>;
};

type FakeUi = {
	onTerminalInput(fn: () => undefined): () => void;
	custom?<T>(factory: unknown): Promise<T>;
};

type FakeCtxOverrides = {
	mode?: string;
	isIdle?(): boolean;
	sessionManager?: { getEntries(): unknown[] };
	ui?: FakeUi;
};

function fakePi() {
	const handlers = new Map<string, Handler>();
	const renames: string[] = [];
	const pi: FakePi = {
		on(event, handler) { handlers.set(event, handler); },
		async exec(_cmd, args) {
			if (args[0] === "rename-window") renames.push(args[args.length - 1] as string);
			return { code: 0, stdout: "", stderr: "" };
		},
	};
	const fire = async (event: string, overrides: FakeCtxOverrides = {}): Promise<void> => {
		const h = handlers.get(event);
		if (!h) return;
		await h({}, {
			mode: "api", // non-TUI by default: review() is skipped, so askQuestions is never reached
			isIdle: () => false,
			sessionManager: {
				getEntries: () => [{
					type: "message",
					message: {
						role: "assistant",
						content: [{ type: "text", text: "result text" }],
						stopReason: "end_turn",
						errorMessage: undefined,
						usage: null,
					},
				}],
			},
			ui: { onTerminalInput: () => () => {} },
			...overrides,
		});
	};
	return { pi, fire, renames };
}

describe("markerExtension", () => {
	let dir: string;
	let resultFile: string;
	let savedEnv: NodeJS.ProcessEnv;

	beforeEach(() => {
		savedEnv = { ...process.env };
		dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-marker-test-"));
		resultFile = path.join(dir, "result.json");
		process.env[ENV.resultFile] = resultFile;
		process.env[ENV.review] = "0"; // keep askQuestions (pi-tui) out of the call path by default
		process.env[ENV.label] = "test-agent";
		process.env[ENV.depth] = "1";
		process.env.TMUX_PANE = "%42";
	});

	afterEach(() => {
		process.env = savedEnv;
		fs.rmSync(dir, { recursive: true, force: true });
	});

	it("retries the write on the next turn when the first write fails", async () => {
		const badDir = path.join(dir, "missing");
		const badFile = path.join(badDir, "result.json");
		process.env[ENV.resultFile] = badFile;

		const { pi, fire } = fakePi();
		markerExtension(pi);

		await fire("agent_settled");
		assert.ok(!fs.existsSync(badFile), "no result after failed write");

		fs.mkdirSync(badDir, { recursive: true });
		await fire("agent_start");
		await fire("agent_settled");

		assert.ok(fs.existsSync(badFile), "result written after retry");
	});

	it("does not write the review marker after successful delivery", async () => {
		const { pi, fire } = fakePi();
		markerExtension(pi);

		await fire("agent_settled");
		assert.ok(fs.existsSync(resultFile), "result should be written");

		const reviewFile = reviewMarkerFor(resultFile);
		await fire("ui_prompt_start");
		assert.ok(!fs.existsSync(reviewFile), "review marker must not appear after delivery");
	});

	it("does not rewrite the result on a manual follow-up turn", async () => {
		const { pi, fire } = fakePi();
		markerExtension(pi);

		await fire("agent_settled");
		fs.writeFileSync(resultFile, "SENTINEL");

		// Simulate the user continuing the conversation manually in the kept-open window.
		await fire("agent_start");
		await fire("agent_settled");

		assert.equal(fs.readFileSync(resultFile, "utf-8"), "SENTINEL", "follow-up turn must not overwrite the delivered result");
	});

	// ── review-enabled path: the interaction the earlier fixes targeted ────────

	it("delivers the result and clears the review marker when the user chooses Send as-is", async () => {
		process.env[ENV.review] = "1";
		const { pi, fire } = fakePi();
		markerExtension(pi);
		const reviewFile = reviewMarkerFor(resultFile);

		/**
		 * A faked ui.custom that mimics real pi: fires ui_prompt_start before
		 * showing the prompt and ui_prompt_end once it resolves. This is a
		 * legitimate boundary (the terminal UI), not an internal collaborator.
		 */
		const custom = async () => {
			await fire("ui_prompt_start");
			/**
			 * The load-bearing assertion: the marker must exist *while* the prompt is up,
			 * which is what pauses the parent's clock — not just its absence afterward.
			 */
			assert.ok(fs.existsSync(reviewFile), "marker must be present while the review prompt is up");
			assert.ok(!fs.existsSync(resultFile), "result must not be delivered before the user answers");
			await fire("ui_prompt_end", { isIdle: () => true });
			return { answers: [["Send as-is"]], images: [] };
		};

		await fire("agent_settled", { mode: "tui", ui: { onTerminalInput: () => () => {}, custom } });

		assert.ok(fs.existsSync(resultFile), "result should be written after Send as-is");
		assert.ok(!fs.existsSync(reviewFile), "review marker must be cleared once the prompt ends");
	});

	it("writes nothing and keeps the review marker cleared when the user chooses Keep working", async () => {
		process.env[ENV.review] = "1";
		const { pi, fire } = fakePi();
		markerExtension(pi);
		const reviewFile = reviewMarkerFor(resultFile);

		const custom = async () => {
			await fire("ui_prompt_start");
			assert.ok(fs.existsSync(reviewFile), "marker must be present while the review prompt is up");
			await fire("ui_prompt_end", { isIdle: () => true });
			return { answers: [["Keep working"]], images: [] };
		};

		await fire("agent_settled", { mode: "tui", ui: { onTerminalInput: () => () => {}, custom } });

		assert.ok(!fs.existsSync(resultFile), "no result should be written when the user keeps working");
		assert.ok(!fs.existsSync(reviewFile), "review marker must not linger after the prompt ends");
	});

	it("delivers custom-typed replacement text when the user rewrites the answer", async () => {
		process.env[ENV.review] = "1";
		const { pi, fire } = fakePi();
		markerExtension(pi);
		const reviewFile = reviewMarkerFor(resultFile);

		const custom = async () => {
			await fire("ui_prompt_start");
			await fire("ui_prompt_end", { isIdle: () => true });
			return { answers: [["rewritten output"]], images: [] };
		};

		await fire("agent_settled", { mode: "tui", ui: { onTerminalInput: () => () => {}, custom } });

		assert.ok(fs.existsSync(resultFile), "result should be written for a custom-typed answer");
		const written = JSON.parse(fs.readFileSync(resultFile, "utf-8"));
		assert.equal(written.output, "rewritten output", "delivered output must be the user's typed replacement");
		assert.ok(!fs.existsSync(reviewFile), "review marker must be cleared once the prompt ends");
	});
});
