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
import { CONFIG_DIR_NAME, type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import { type AgentConfig, type AgentScope, discoverAgents } from "./agents.ts";
import { buildPiCommand } from "./command.ts";
import { childDepth, ENV } from "./protocol.ts";
import { clampTimeout, DEFAULT_TIMEOUT_MS, MAX_CONCURRENT, MAX_TIMEOUT_MS, normalizeTasks } from "./tasks.ts";
import { formatWindowName } from "./window-name.ts";
import { renderAgentBlock } from "./agent-block.ts";
import { errorText } from "./errors.ts";
import { type RunResult, toRunResult, formatResult } from "./run-result.ts";
import { getCurrentTmuxSession, createTmuxWindow, isWindowAlive, killTmuxWindow } from "./tmux.ts";
import { type WaitOutcome, waitForResult } from "./wait.ts";

const MAX_SUBAGENT_DEPTH = 3; // root=0; subagent tool stays active while depth < MAX

interface RunSubagentOptions {
	pi: ExtensionAPI;
	ctx: { cwd: string; model?: { provider: string; id: string } };
	agents: AgentConfig[];
	session: string;
	agentName: string;
	task: string;
	timeoutMs: number;
	signal: AbortSignal | undefined;
	depth: number;
	onReview?: (agent: string, windowId: string, reviewing: boolean) => void;
}

async function runSubagent({
	pi,
	ctx,
	agents,
	session,
	agentName,
	task,
	timeoutMs,
	signal,
	depth,
	onReview,
}: RunSubagentOptions): Promise<RunResult> {
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
		/**
		 * Plan mode always removes edit and write together (plan-mode/index.ts'
		 * MUTATING_TOOLS), so requiring both absent is the correct live signal
		 * to detect it: there is no separate flag to read across extensions,
		 * and this is the same pi.getActiveTools()/setActiveTools() API
		 * plan-mode itself uses to gate/restore tools.
		 */
		const activeTools = pi.getActiveTools();
		const planActive = !activeTools.includes("edit") && !activeTools.includes("write");
		const command = buildPiCommand({ model, tools: agent.tools, systemPromptFile, task, plan: planActive });

		if (signal?.aborted) {
			return { agent: agent.name, agentSource: agent.source, task, status: "aborted", output: "", errorMessage: "Aborted." };
		}

		const windowId = await createTmuxWindow(
			pi,
			session,
			formatWindowName("running", agent.name, depth + 1),
			ctx.cwd,
			{
				[ENV.resultFile]: resultFile,
				[ENV.review]: agent.review ? "1" : "0",
				[ENV.label]: agent.name,
				[ENV.depth]: String(depth + 1),
			},
			command,
		);
		const base = { agent: agent.name, agentSource: agent.source, task, windowId };
		// Record the window ID so the startup sweep can verify liveness before deleting.
		await fs.promises.writeFile(path.join(tmpDir, "window-id"), windowId, "utf-8").catch(() => {});

		// Once the window exists its id must reach the caller, or it is an orphan.
		let outcome: WaitOutcome;
		try {
			outcome = await waitForResult({
				windowId,
				resultFile,
				timeoutMs,
				signal,
				onReview: (reviewing) => onReview?.(agent.name, windowId, reviewing),
				checkWindowAlive: (wid) => isWindowAlive(pi, wid),
			});
		} catch (error) {
			// The window is untouched and may still write, so the dir must survive.
			keepTmpDir = true;
			return {
				...base,
				status: "error",
				output: "",
				errorMessage: `Internal error while waiting for subagent: ${errorText(error)}.`,
			};
		}

		// The window stays alive for all outcomes except aborted (killed) and windowGone (dead).
		keepTmpDir = outcome.kind !== "aborted" && outcome.kind !== "windowGone";
		const result = toRunResult(outcome, base, { resultFile, timeoutMs });
		if (outcome.kind === "aborted") await killTmuxWindow(pi, windowId);
		return result;
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


/** Twice the max run so a dir can never be swept while its window could still write. */
const STALE_TMP_DIR_AGE_MS = MAX_TIMEOUT_MS * 2;

/** Delete temp dirs from previous runs that are both old enough and have no living tmux window. */
async function sweepStaleTempDirs(pi: ExtensionAPI): Promise<void> {
	try {
		const prefix = "pi-tmux-subagent-";
		const entries = await fs.promises.readdir(os.tmpdir(), { withFileTypes: true });
		const cutoff = Date.now() - STALE_TMP_DIR_AGE_MS;
		await Promise.all(
			entries
				.filter((e) => e.isDirectory() && e.name.startsWith(prefix))
				.map(async (e) => {
					const full = path.join(os.tmpdir(), e.name);
					const stat = await fs.promises.stat(full).catch(() => null);
					if (!stat || stat.mtimeMs >= cutoff) return;
					// If the recorded window is still alive the dir must outlive this process.
					const windowId = await fs.promises.readFile(path.join(full, "window-id"), "utf-8").catch(() => null);
					if (windowId && (await isWindowAlive(pi, windowId.trim()))) return;
					fs.rm(full, { recursive: true, force: true }, () => {});
				}),
		);
	} catch {
		// Non-critical: sweep failure silently ignored.
	}
}

export default function (pi: ExtensionAPI) {
	const depth = childDepth();
	// Deeper processes stay inert leaves so nesting is bounded.
	if (depth >= MAX_SUBAGENT_DEPTH) return;

	// Only root sweeps; children would duplicate the scan (non-critical).
	if (depth === 0) void sweepStaleTempDirs(pi);

	/**
	 * Not a tool snippet: a custom SYSTEM.md replaces the section those land in.
	 * Rebuilt per request so agent file edits apply without a restart.
	 */
	pi.on("before_agent_start", (event, ctx) => {
		/**
		 * Only user agents are advertised; project agents require an explicit name
		 * plus a trust confirm, so listing them here would invite unapproved calls.
		 */
		const agents = discoverAgents(ctx.cwd, "user").agents.filter((a) => !a.disableModelInvocation);
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
			/**
			 * Normalize first: single call is treated as parallel with n=1.
			 * Before any prompting, so an invalid call cannot ask about agents it will then refuse to run.
			 */
			const tasks = normalizeTasks(params);
			const timeoutMs = clampTimeout(params.timeoutMs);

			const agentScope: AgentScope = params.agentScope ?? "user";
			const discovery = discoverAgents(ctx.cwd, agentScope);
			const agents = discovery.agents;
			const confirmProjectAgents = params.confirmProjectAgents ?? true;

			if ((agentScope === "project" || agentScope === "both") && confirmProjectAgents && !ctx.isProjectTrusted()) {
				const requestedNames = new Set(tasks.map((t) => t.agent));
				const projectAgentsRequested = Array.from(requestedNames)
					.map((name) => agents.find((a) => a.name === name))
					.filter((a): a is AgentConfig => a?.source === "project");

				if (projectAgentsRequested.length > 0) {
					if (!ctx.hasUI) {
						return { content: [{ type: "text", text: "Refused: untrusted project-local agents cannot be confirmed in a headless run." }], details: {} };
					}
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

			// allSettled: a failed spawn must not discard sibling window ids.
			const settled = await Promise.allSettled(
				tasks.map((t) => runSubagent({ pi, ctx, agents, session, agentName: t.agent, task: t.task, timeoutMs, signal, depth, onReview: reportReview })),
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
							errorMessage: errorText(outcome.reason),
						},
			);
			const successCount = results.filter((r) => r.status === "ok").length;
			const header = tasks.length > 1 ? `Parallel: ${successCount}/${results.length} succeeded\n\n` : "";
			return {
				content: [{ type: "text", text: `${header}${results.map(formatResult).join("\n\n---\n\n")}` }],
				details: { results },
			};
		},
	});
}
