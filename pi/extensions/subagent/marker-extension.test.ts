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

/**
 * agent_settled's review branch is fire-and-forget in production (see
 * marker-extension.ts), so `fire("agent_settled", ...)` below resolves before
 * the review flow finishes. Poll for the side effect each test actually cares about.
 */
async function waitFor(predicate: () => boolean, timeoutMs = 1000): Promise<void> {
	const start = Date.now();
	while (!predicate()) {
		if (Date.now() - start > timeoutMs) throw new Error("waitFor: condition was not met in time");
		await new Promise((resolve) => setTimeout(resolve, 5));
	}
}

type FakePi = {
	on(event: string, handler: Handler): void;
	exec(cmd: string, args: string[]): Promise<{ code: number; stdout: string; stderr: string }>;
	sendUserMessage(content: unknown): void;
	events: { on(event: string, handler: (data: unknown) => void): void };
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
	const sentMessages: unknown[] = [];
	const bus = new Map<string, Array<(data: unknown) => void>>();
	const pi: FakePi = {
		events: { on(event, handler) { bus.set(event, [...(bus.get(event) ?? []), handler]); } },
		on(event, handler) { handlers.set(event, handler); },
		async exec(_cmd, args) {
			if (args[0] === "rename-window") renames.push(args[args.length - 1] as string);
			return { code: 0, stdout: "", stderr: "" };
		},
		sendUserMessage(content) { sentMessages.push(content); },
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
	const emit = (event: string, data: unknown) => bus.get(event)?.forEach((h) => h(data));
	return { pi, fire, renames, sentMessages, emit };
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

	it("keeps findings from before a question call and before a follow-up", async () => {
		const msg = (role: string, content: unknown[]) => ({ type: "message", message: { role, content, stopReason: "stop" } });
		const text = (t: string) => ({ type: "text", text: t });
		const entries = [
			msg("user", [text("task")]),
			msg("assistant", [text("let me check"), { type: "toolCall", name: "read" }]),
			msg("assistant", [text("FINDINGS"), { type: "toolCall", name: "question" }]),
			msg("toolResult", [text("answer")]),
			msg("assistant", [text("CHANGES")]),
			msg("user", [text("follow-up")]),
			msg("assistant", [text("FINAL")]),
		];
		const { pi, fire } = fakePi();
		markerExtension(pi);

		await fire("agent_settled", { sessionManager: { getEntries: () => entries } });

		const { output } = JSON.parse(fs.readFileSync(resultFile, "utf-8"));
		const sep = "\n\n--- after user input ---\n\n";
		assert.equal(output, ["FINDINGS", "CHANGES", "FINAL"].join(sep));
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
});
