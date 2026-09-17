/**
 * Runs agents as real `pi` TUIs in their own tmux window. Completion is detected
 * by polling the result file that ./marker-extension.ts writes in the child.
 *
 * Windows outlive the run so the user can follow up in them by hand; only an
 * aborted call kills one. Finished windows are renamed to carry their outcome.
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import { CONFIG_DIR_NAME, type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import { type AgentConfig, type AgentScope, discoverAgents } from "./agents.ts";

const MAX_CONCURRENT = 4;
const MAX_SUBAGENT_DEPTH = 3; // root=0; subagent tool stays active while depth < MAX
const DEFAULT_TIMEOUT_MS = 10 * 60 * 1000;
const MIN_TIMEOUT_MS = 1000;
const MAX_TIMEOUT_MS = 60 * 60 * 1000;
const POLL_INTERVAL_MS = 500;
/** Check that the window still exists every Nth poll (~2s at 500ms). */
const LIVENESS_CHECK_EVERY = 4;

const MARKER_EXTENSION_PATH = path.join(path.dirname(fileURLToPath(import.meta.url)), "marker-extension.ts");

interface MarkerResult {
	status: "ok" | "error";
	output: string;
	// Passed through untouched, so the shape is not this tool's to claim.
	usage?: unknown;
	stopReason?: string;
	errorMessage?: string;
}

interface RunResult {
	agent: string;
	agentSource: "user" | "project" | "unknown";
	task: string;
	windowId?: string;
	status: "ok" | "error" | "timeout" | "aborted";
	output: string;
	usage?: unknown;
	stopReason?: string;
	errorMessage?: string;
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
	return new Promise((resolve) => {
		// `once: true` only detaches when abort fires, so the normal path has to
		// remove the listener itself or every poll tick leaks one.
		const done = () => {
			clearTimeout(timer);
			signal?.removeEventListener("abort", done);
			resolve();
		};
		const timer = setTimeout(done, ms);
		signal?.addEventListener("abort", done, { once: true });
	});
}

async function getCurrentTmuxSession(pi: ExtensionAPI): Promise<string> {
	const pane = process.env.TMUX_PANE;
	if (!pane) throw new Error("Not running inside tmux (TMUX_PANE is unset). The subagent tool requires tmux.");
	const result = await pi.exec("tmux", ["display-message", "-p", "-t", pane, "#{session_id}"]);
	if (result.code !== 0) throw new Error(`Failed to resolve current tmux session: ${result.stderr || result.stdout}`);
	return result.stdout.trim();
}

async function createTmuxWindow(
	pi: ExtensionAPI,
	session: string,
	windowName: string,
	cwd: string,
	env: Record<string, string>,
	command: string,
): Promise<string> {
	const args = ["new-window", "-t", session, "-n", windowName, "-c", cwd, "-P", "-F", "#{window_id}"];
	for (const [key, value] of Object.entries(env)) args.push("-e", `${key}=${value}`);
	args.push(command);
	const result = await pi.exec("tmux", args);
	if (result.code !== 0) throw new Error(`Failed to create tmux window: ${result.stderr || result.stdout}`);
	return result.stdout.trim();
}

async function killTmuxWindow(pi: ExtensionAPI, windowId: string): Promise<void> {
	await pi.exec("tmux", ["kill-window", "-t", windowId]).catch(() => {});
}

function windowHint(windowId: string): string {
	return `Window kept for follow-ups: tmux select-window -t ${windowId}`;
}

/** `⋯ explore` while running, `✓ explore` or `✗ explore` once settled. */
function windowName(state: "running" | "ok" | "error", agent: string, depth: number): string {
	const marker = state === "running" ? "⋯" : state === "ok" ? "✓" : "✗";
	const prefix = depth >= 2 ? `L${depth} ` : "";
	return `${prefix}${marker} ${agent}`.slice(0, 30);
}

async function isWindowAlive(pi: ExtensionAPI, windowId: string): Promise<boolean> {
	// By id, not by listing the origin session: a window moved to another session
	// is still alive and must not be reported as gone.
	const result = await pi.exec("tmux", ["display-message", "-p", "-t", windowId, "#{window_id}"]).catch(() => null);
	// A rejected exec says nothing about the window, so assume alive and let the
	// timeout decide. A non-zero exit is a real answer.
	if (!result) return true;
	return result.code === 0 && result.stdout.trim() === windowId;
}

type ResultRead = { ok: true; result: MarkerResult } | { ok: false; detail: string } | null;

async function readResult(resultFile: string): Promise<ResultRead> {
	let raw: string;
	try {
		raw = await fs.promises.readFile(resultFile, "utf-8");
	} catch {
		return null; // Not written yet.
	}
	try {
		const parsed = JSON.parse(raw);
		if ((parsed?.status === "ok" || parsed?.status === "error") && typeof parsed.output === "string") {
			return { ok: true, result: parsed as MarkerResult };
		}
		return { ok: false, detail: raw.slice(0, 200) };
	} catch {
		return { ok: false, detail: raw.slice(0, 200) };
	}
}

type WaitOutcome =
	| { kind: "result"; result: MarkerResult }
	| { kind: "timeout" }
	| { kind: "aborted" }
	| { kind: "windowGone" }
	| { kind: "corrupt"; detail: string };

async function waitForResult(
	pi: ExtensionAPI,
	windowId: string,
	resultFile: string,
	timeoutMs: number,
	signal: AbortSignal | undefined,
	onReview?: (reviewing: boolean) => void,
): Promise<WaitOutcome> {
	const reviewFile = `${resultFile}.review`;
	let deadline = Date.now() + timeoutMs;
	let corruptReads = 0;
	let tick = 0;
	let reviewing = false;

	while (Date.now() < deadline) {
		if (signal?.aborted) return { kind: "aborted" };

		// The marker means a human is looking at the result, so the clock stops
		// and restarts from full once they hand the agent more work.
		const nowReviewing = fs.existsSync(reviewFile);
		if (nowReviewing !== reviewing) {
			reviewing = nowReviewing;
			onReview?.(reviewing);
		}
		if (reviewing) deadline = Date.now() + timeoutMs;

		const read = await readResult(resultFile);
		if (read?.ok) return { kind: "result", result: read.result };
		// The write is atomic, so an invalid file is corruption, not a torn read.
		if (read && !read.ok && ++corruptReads >= 3) return { kind: "corrupt", detail: read.detail };

		// Short-circuits the most likely failure: the child died before writing.
		if (!read && ++tick % LIVENESS_CHECK_EVERY === 0 && !(await isWindowAlive(pi, windowId))) {
			const final = await readResult(resultFile);
			if (final?.ok) return { kind: "result", result: final.result };
			return { kind: "windowGone" };
		}

		await sleep(Math.min(POLL_INTERVAL_MS, Math.max(0, deadline - Date.now())), signal);
	}

	return signal?.aborted ? { kind: "aborted" } : { kind: "timeout" };
}

function buildPiCommand(opts: { model?: string; tools?: string[]; systemPromptFile?: string; task: string }): string {
	const tokens = ["pi", "-e", MARKER_EXTENSION_PATH, "--no-session"];
	if (opts.model) tokens.push("--model", opts.model);
	if (opts.tools && opts.tools.length > 0) tokens.push("--tools", opts.tools.join(","));
	if (opts.systemPromptFile) tokens.push("--append-system-prompt", opts.systemPromptFile);
	tokens.push(`Task: ${opts.task}`);
	return tokens.map(shellQuote).join(" ");
}

async function runSubagent(
	pi: ExtensionAPI,
	ctx: { cwd: string; model?: { provider: string; id: string } },
	agents: AgentConfig[],
	session: string,
	agentName: string,
	task: string,
	timeoutMs: number,
	signal: AbortSignal | undefined,
	depth: number,
	onReview?: (agent: string, windowId: string, reviewing: boolean) => void,
): Promise<RunResult> {
	const agent = agents.find((a) => a.name === agentName);
	if (!agent) {
		const available = agents.map((a) => `"${a.name}"`).join(", ") || "none";
		return {
			agent: agentName,
			agentSource: "unknown",
			task,
			status: "error",
			output: "",
			errorMessage: `Unknown agent: "${agentName}". Available agents: ${available}.`,
		};
	}

	const tmpDir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-tmux-subagent-"));
	const resultFile = path.join(tmpDir, "result.json");
	// A window left open may still write its result, so its dir must outlive this.
	let keepTmpDir = false;

	try {
		let systemPromptFile: string | undefined;
		if (agent.systemPrompt.trim()) {
			systemPromptFile = path.join(tmpDir, "system-prompt.md");
			await fs.promises.writeFile(systemPromptFile, agent.systemPrompt, "utf-8");
		}

		const model = agent.model ?? (ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined);
		const command = buildPiCommand({ model, tools: agent.tools, systemPromptFile, task });


		if (signal?.aborted) {
			return { agent: agent.name, agentSource: agent.source, task, status: "aborted", output: "", errorMessage: "Aborted." };
		}

		const windowId = await createTmuxWindow(
			pi,
			session,
			windowName("running", agent.name, depth + 1),
			ctx.cwd,
			{
				PI_SUBAGENT_RESULT_FILE: resultFile,
				PI_SUBAGENT_REVIEW: agent.review ? "1" : "0",
				PI_SUBAGENT_LABEL: agent.name,
				PI_SUBAGENT_DEPTH: String(depth + 1),
			},
			command,
		);
		const base = { agent: agent.name, agentSource: agent.source, task, windowId };

		// Once the window exists its id must reach the caller, or it is an orphan.
		let outcome: WaitOutcome;
		try {
			outcome = await waitForResult(pi, windowId, resultFile, timeoutMs, signal, (reviewing) =>
				onReview?.(agent.name, windowId, reviewing),
			);
		} catch (error) {
			keepTmpDir = true;
			return {
				...base,
				status: "error",
				output: "",
				errorMessage: `Internal error while waiting for subagent: ${error instanceof Error ? (error.stack ?? error.message) : String(error)}.`,
			};
		}

		switch (outcome.kind) {
			case "aborted":
				await killTmuxWindow(pi, windowId);
				return { ...base, status: "aborted", output: "", errorMessage: "Aborted." };

			case "windowGone":
				return {
					...base,
					status: "error",
					output: "",
					errorMessage:
						"Subagent exited without writing a result (its tmux window closed). Likely a startup failure - check the agent's model and tools, and that `pi` is on PATH.",
				};

			case "corrupt":
				keepTmpDir = true;
				return {
					...base,
					status: "error",
					output: "",
					errorMessage: `Unreadable result file ${resultFile}: ${outcome.detail}.`,
				};

			case "timeout":
				keepTmpDir = true;
				return {
					...base,
					status: "timeout",
					output: "",
					errorMessage: `Timed out after ${timeoutMs}ms.`,
				};

			case "result": {
				const result = outcome.result;
				// The child stays alive for follow-ups and rewrites its result file on
				// every further turn, so the temp dir has to survive this call.
				keepTmpDir = true;
				if (result.status === "error") {
					return {
						...base,
						status: "error",
						output: result.output,
						usage: result.usage,
						stopReason: result.stopReason,
						errorMessage: result.errorMessage ?? "Agent failed.",
					};
				}
				return { ...base, status: "ok", output: result.output, usage: result.usage, stopReason: result.stopReason };
			}
		}

		const unhandled: never = outcome;
		throw new Error(`Unhandled wait outcome: ${JSON.stringify(unhandled)}`);
	} finally {
		if (!keepTmpDir) fs.rm(tmpDir, { recursive: true, force: true }, () => {});
	}
}

const TaskItem = Type.Object({
	agent: Type.String({ description: "Name of the agent to invoke" }),
	task: Type.String({ description: "Task to delegate to the agent" }),
});

const AgentScopeSchema = StringEnum(["user", "project", "both"] as const, {
	description: 'Which agent directories to use. Default: "user". Use "both" to include project-local agents.',
	default: "user",
});

const SubagentParams = Type.Object({
	agent: Type.Optional(Type.String({ description: "Name of the agent to invoke (for single mode)" })),
	task: Type.Optional(Type.String({ description: "Task to delegate (for single mode)" })),
	tasks: Type.Optional(
		Type.Array(TaskItem, { description: `Array of {agent, task} for parallel execution. Max ${MAX_CONCURRENT}.` }),
	),
	agentScope: Type.Optional(AgentScopeSchema),
	confirmProjectAgents: Type.Optional(
		Type.Boolean({ description: "Prompt before running project-local agents. Default: true.", default: true }),
	),
	timeoutMs: Type.Optional(
		Type.Number({ description: `Max ms to wait for the subagent to finish. Default ${DEFAULT_TIMEOUT_MS}.` }),
	),
});

function formatResult(r: RunResult): string {
	const body = r.status === "ok" ? r.output : (r.errorMessage ?? r.output);
	const hint = r.windowId && r.status !== "aborted" ? `\n\n${windowHint(r.windowId)}` : "";
	return `[${r.agent}] ${r.status}\n\n${body}${hint}`;
}

function escapeXml(value: string): string {
	return value
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;")
		.replace(/'/g, "&apos;");
}

function renderAgentBlock(agents: AgentConfig[]): string {
	const lines = [
		"Delegate to these with the `subagent` tool when a task matches one. Each agent runs with",
		"no conversation context, so the task text must be self-contained.",
		"",
		"<available_agents>",
	];
	for (const a of agents) {
		lines.push("  <agent>");
		lines.push(`    <name>${escapeXml(a.name)}</name>`);
		lines.push(`    <description>${escapeXml(a.description)}</description>`);
		lines.push("  </agent>");
	}
	lines.push("</available_agents>");
	return lines.join("\n");
}

export default function (pi: ExtensionAPI) {
	const depth = Number(process.env.PI_SUBAGENT_DEPTH) || 0;
	// Deeper processes stay inert leaves so nesting is bounded.
	if (depth >= MAX_SUBAGENT_DEPTH) return;

	// Not a tool snippet: a custom SYSTEM.md replaces the section those land in.
	// Rebuilt per request so agent file edits apply without a restart.
	pi.on("before_agent_start", (event) => {
		const agents = discoverAgents("", "user").agents.filter((a) => !a.disableModelInvocation);
		if (agents.length === 0) return;
		return { systemPrompt: `${event.systemPrompt}\n\n${renderAgentBlock(agents)}` };
	});

	pi.registerTool({
		name: "subagent",
		label: "Subagent",
		description: [
			"Delegate a task to a specialized agent running as a real, visible `pi` TUI in its own tmux window (same session).",
			"Prefer this over doing the work directly whenever the task matches one of the agents listed below, even if it looks small. The agent's own tool output stays out of this session, only its final report comes back.",
			"Modes: single (agent + task) or parallel (tasks array, up to " + MAX_CONCURRENT + " concurrent).",
			`Default agent scope is "user" (from ${path.join(getAgentDir(), "agents")}), listed under "Available agents" in the system prompt.`,
			`To reach project-local agents in ${CONFIG_DIR_NAME}/agents, name one and set agentScope: "both" (or "project").`,
			"Every window stays open after the run so the user can follow up in it by hand; you cannot send further messages to a subagent yourself.",
		].join(" "),
		parameters: SubagentParams,

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const hasTasks = (params.tasks?.length ?? 0) > 0;
			const hasSingle = Boolean(params.agent && params.task);

			// Before any prompting, so an invalid call cannot ask about agents it
			// will then refuse to run.
			if (Number(hasTasks) + Number(hasSingle) !== 1) {
				throw new Error('Invalid parameters: provide exactly one of { agent, task } or { tasks: [...] }.');
			}
			if (params.tasks && params.tasks.length > MAX_CONCURRENT) {
				throw new Error(`Too many parallel tasks (${params.tasks.length}). Max is ${MAX_CONCURRENT}.`);
			}

			const agentScope: AgentScope = params.agentScope ?? "user";
			const discovery = discoverAgents(ctx.cwd, agentScope);
			const agents = discovery.agents;
			const confirmProjectAgents = params.confirmProjectAgents ?? true;
			const requestedTimeout = params.timeoutMs ?? DEFAULT_TIMEOUT_MS;
			const timeoutMs = Number.isFinite(requestedTimeout)
				? Math.min(Math.max(requestedTimeout, MIN_TIMEOUT_MS), MAX_TIMEOUT_MS)
				: DEFAULT_TIMEOUT_MS;

			if ((agentScope === "project" || agentScope === "both") && confirmProjectAgents && ctx.hasUI && !ctx.isProjectTrusted()) {
				const requestedNames = new Set(params.tasks ? params.tasks.map((t) => t.agent) : [params.agent!]);
				const projectAgentsRequested = Array.from(requestedNames)
					.map((name) => agents.find((a) => a.name === name))
					.filter((a): a is AgentConfig => a?.source === "project");

				if (projectAgentsRequested.length > 0) {
					const names = projectAgentsRequested.map((a) => a.name).join(", ");
					const dir = discovery.projectAgentsDir ?? "(unknown)";
					const ok = await ctx.ui.confirm(
						"Run project-local agents?",
						`Agents: ${names}\nSource: ${dir}\n\nProject agents are repo-controlled. Only continue for trusted repositories.`,
					);
					if (!ok) return { content: [{ type: "text", text: "Canceled: project-local agents not approved." }], details: {} };
				}
			}

			const session = await getCurrentTmuxSession(pi);

			const awaitingReview = new Set<string>();
			const reportReview = (agent: string, windowId: string, reviewing: boolean) => {
				const entry = `${agent} (${windowId})`;
				if (reviewing) awaitingReview.add(entry);
				else awaitingReview.delete(entry);
				const waiting = [...awaitingReview];
				onUpdate?.({
					content: [
						{
							type: "text",
							text: waiting.length > 0 ? `Awaiting your review in: ${waiting.join(", ")}` : "Running…",
						},
					],
					details: {},
				});
			};

			if (params.tasks && params.tasks.length > 0) {
				const tasks = params.tasks;
				// allSettled: a failed spawn must not discard sibling window ids.
				const settled = await Promise.allSettled(
					tasks.map((t) => runSubagent(pi, ctx, agents, session, t.agent, t.task, timeoutMs, signal, depth, reportReview)),
				);
				const results: RunResult[] = settled.map((outcome, i) =>
					outcome.status === "fulfilled"
						? outcome.value
						: {
								agent: tasks[i].agent,
								agentSource: "unknown",
								task: tasks[i].task,
								status: "error",
								output: "",
								errorMessage:
									outcome.reason instanceof Error
										? (outcome.reason.stack ?? outcome.reason.message)
										: String(outcome.reason),
							},
				);
				const successCount = results.filter((r) => r.status === "ok").length;
				return {
					content: [
						{
							type: "text",
							text: `Parallel: ${successCount}/${results.length} succeeded\n\n${results.map(formatResult).join("\n\n---\n\n")}`,
						},
					],
					details: { results },
				};
			}

			const result = await runSubagent(
				pi,
				ctx,
				agents,
				session,
				params.agent!,
				params.task!,
				timeoutMs,
				signal,
				depth,
				reportReview,
			);
			return {
				content: [{ type: "text", text: formatResult(result) }],
				details: { results: [result] },
			};
		},
	});
}
