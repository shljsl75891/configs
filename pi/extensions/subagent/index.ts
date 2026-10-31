/**
 * Runs agents as real `pi` TUIs in their own tmux window. Completion is detected
 * by polling the result file that ./marker-extension.ts writes in the child.
 *
 * Windows outlive a run that ends in an error, so the user can inspect it or
 * follow up by hand. A successful run has nothing left to do there, so its window
 * closes like an aborted one. Finished windows are renamed to carry their outcome.
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { CONFIG_DIR_NAME, type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import { onPlanModeChange } from "../plan-mode/index.ts";
import { modelKey } from "../lib/model.ts";
import { type AgentConfig, type AgentScope, discoverAgents } from "./agents.ts";
import { trackAutoApprove } from "../lib/auto-approve.ts";
import { buildPiCommand } from "./command.ts";
import { childDepth, ENV } from "./protocol.ts";
import { clampTimeout, DEFAULT_TIMEOUT_MS, MAX_CONCURRENT, MAX_TIMEOUT_MS, normalizeTasks } from "./tasks.ts";
import { formatWindowName } from "./window-name.ts";
import { renderAgentBlock } from "./agent-block.ts";
import { errorText } from "../lib/errors.ts";
import { type RunResult, toRunResult, formatResult } from "./run-result.ts";
import { getCurrentTmuxSession, createTmuxWindow, isWindowAlive, killTmuxWindow } from "./tmux.ts";
import { type WaitOutcome, waitForResult } from "./wait.ts";
import { awaitForeground, createRunHandle, type Detach, isActive, type RunHandle } from "./background.ts";
import { askQuestions } from "../question-tool/prompt.ts";

const LABEL_MAX_CHARS = 60;
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
	/** Parent is in plan mode: the child starts with --plan so its own permission rules apply. */
	plan: boolean;
	/** Parent has auto-approve on: the child starts with --approve. */
	approve: boolean;
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
	plan,
	approve,
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

		const model = agent.model ?? modelKey(ctx.model);
		const command = buildPiCommand({ model, systemPromptFile, task, plan, approve });

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
				[ENV.label]: agent.name,
				[ENV.depth]: String(depth + 1),
				...(agent.tools ? { [ENV.tools]: agent.tools.join(",") } : {}),
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

		// Closed like an abort: a successful run has nothing left to review, so the window would just sit there.
		const closeWindow = outcome.kind === "aborted" || (outcome.kind === "result" && outcome.result.status === "ok");
		keepTmpDir = !closeWindow && outcome.kind !== "windowGone";
		const result = toRunResult(outcome, base, { resultFile, timeoutMs });
		if (closeWindow) await killTmuxWindow(pi, windowId);
		return result;
	} finally {
		if (!keepTmpDir) fs.rm(tmpDir, { recursive: true, force: true }, () => {});
	}
}

const TaskItem = Type.Object({
	agent: Type.String({ description: "The agent name." }),
	task: Type.String({ description: "The task for the agent." }),
});

const AgentScopeSchema = StringEnum(["user", "project", "both"] as const, {
	description: 'The agent directories to use. Default: "user". Use "both" to add project agents.',
	default: "user",
});

const SubagentParams = Type.Object({
	agent: Type.Optional(Type.String({ description: "The agent name, for single mode." })),
	task: Type.Optional(Type.String({ description: "The task, for single mode." })),
	tasks: Type.Optional(
		Type.Array(TaskItem, { description: `The tasks, for parallel mode. Maximum ${MAX_CONCURRENT}.` }),
	),
	agentScope: Type.Optional(AgentScopeSchema),
	confirmProjectAgents: Type.Optional(
		Type.Boolean({ description: "Set false to skip the prompt before a project agent runs. Default: true.", default: true }),
	),
	background: Type.Optional(
		Type.Boolean({ description: "Set true to return at once while the agents keep running. Each result arrives later as a follow-up message. Use only when you have other work to do meanwhile; leave it unset when your next step needs the result. Top-level agent only." }),
	),
	timeoutMs: Type.Optional(
		Type.Number({ description: `The time limit in milliseconds. Default ${DEFAULT_TIMEOUT_MS}.` }),
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

	let planActive = false;
	onPlanModeChange(pi, (enabled) => {
		planActive = enabled;
	});
	const approveActive = trackAutoApprove(pi);

	/** Runs of every subagent call that still waits; tool calls can run in parallel. */
	const foregroundRuns = new Set<RunHandle>();
	/** Reports to the user; the context may be stale by then, so a failure falls back to stderr. */
	let notify: (message: string) => void = console.error;
	let pickerOpen = false;
	/**
	 * Throws on a stale extension instance (after /new or a reload). The run's window
	 * stays open on purpose, so the message names it for the user to read by hand.
	 */
	const deliverBackground = (r: RunResult): void => {
		try {
			pi.sendMessage(
				{ customType: "subagent-background", content: formatResult(r), display: true, details: { result: r } },
				{ triggerTurn: true, deliverAs: "steer" },
			);
		} catch (error) {
			const where = r.windowId ? ` Window: ${r.windowId}.` : "";
			notify(`Could not deliver the result of background subagent ${r.agent}: ${errorText(error)}.${where}`);
		}
	};

	if (depth === 0) pi.registerShortcut("ctrl+shift+b", {
		description: "Send running subagents to the background",
		handler: async (ctx) => {
			const active = [...foregroundRuns].filter(isActive);
			if (active.length === 0 || pickerOpen) return;
			if (active.length === 1) {
				if (active[0].moveToBackground()) ctx.ui.notify(`Moved ${active[0].agent} to the background.`, "info");
				return;
			}
			const labels = active.map((h, i) => `${i + 1}. ${h.agent}: ${h.task.replace(/\s+/g, " ").slice(0, LABEL_MAX_CHARS)}`);
			pickerOpen = true;
			const choice = await askQuestions(ctx.ui, [
				{
					question: "Which subagents go to the background?",
					header: "Background",
					multiple: true,
					options: labels.map((label, i) => ({ label, description: active[i].task.replace(/\s+/g, " ").slice(0, 200) })),
				},
			]).finally(() => {
				pickerOpen = false;
			});
			// Runs may have ended while the picker was open; moveToBackground ignores those.
			for (const answer of choice?.answers[0] ?? []) active[labels.indexOf(answer)]?.moveToBackground();
		},
	});

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
			"Runs an agent in its own tmux window, in this session. The agent's tool output stays in that window. Only its final report comes back here.",
			"Use single mode (agent and task) or parallel mode (a tasks array, maximum " + MAX_CONCURRENT + " at once).",
			`The default agent scope is "user", from ${path.join(getAgentDir(), "agents")}. The system prompt lists these agents under "Available agents".`,
			`To use a project agent from ${CONFIG_DIR_NAME}/agents, name it and set agentScope to "both" or "project".`,
			"Set background to true to return at once. Each result then arrives later as a follow-up message, so do not poll or wait for it.",
			"Use background only when you have other useful work to do meanwhile, or when the task is long and independent of your next step. Do not use it when your very next step needs the result: run it in the foreground. Do not end your turn just to wait for a result.",
			"Only the top-level agent can use background: a nested agent must wait for its own subagents. The user can also press Ctrl+Shift+B while you wait to move runs to the background.",
			"The window stays open after the run. The user can work in it by hand. You cannot send more messages to the agent.",
			"Every subagent can launch its own subagents of any type, such as explore or web-research-expert. Do not run research or exploration first just to pass the results on. Give the goal and let the subagent find its own facts.",
		].join(" "),
		parameters: SubagentParams,

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			/**
			 * Normalize first: single call is treated as parallel with n=1.
			 * Before any prompting, so an invalid call cannot ask about agents it will then refuse to run.
			 */
			const tasks = normalizeTasks(params);
			if (params.background && depth > 0) throw new Error("background is only available to the top-level agent.");
			if (params.background && !ctx.hasUI) throw new Error("background needs an interactive session.");
			notify = (message) => {
				try {
					ctx.ui.notify(message, "warning");
				} catch {
					console.error(message);
				}
			};
			const timeoutMs = clampTimeout(params.timeoutMs);

			const agentScope: AgentScope = params.agentScope ?? "user";
			const discovery = discoverAgents(ctx.cwd, agentScope);
			const agents = discovery.agents;
			const unknown = tasks.filter((t) => !agents.some((a) => a.name === t.agent));
			if (params.background && unknown.length > 0) {
				const available = agents.map((a) => `"${a.name}"`).join(", ") || "none";
				throw new Error(`Unknown agent: ${unknown.map((t) => `"${t.agent}"`).join(", ")}. Available agents: ${available}.`);
			}
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
							text: waiting.length > 0 ? `Awaiting your answer in: ${waiting.join(", ")}` : "Running… (Ctrl+Shift+B: send to background)",
						},
					],
					details: {},
				});
			};

			const handles: RunHandle[] = tasks.map((t) => {
				const run = async (detach: Detach): Promise<RunResult> => {
					/** The caller's abort stops the run only while the caller still waits for it. */
					const runAbort = new AbortController();
					const forwardAbort = () => {
						if (!detach.detached) runAbort.abort();
					};
					if (signal?.aborted) forwardAbort();
					else signal?.addEventListener("abort", forwardAbort, { once: true });
					const onReview = (agent: string, windowId: string, reviewing: boolean) => {
						if (detach.detached) awaitingReview.delete(`${agent} (${windowId})`);
						else reportReview(agent, windowId, reviewing);
					};
					try {
						return await runSubagent({ pi, ctx, agents, session, agentName: t.agent, task: t.task, timeoutMs, signal: runAbort.signal, depth, plan: planActive, approve: approveActive(), onReview });
					} catch (error) {
						return { agent: t.agent, agentSource: "unknown", task: t.task, status: "error", output: "", errorMessage: errorText(error) };
					} finally {
						signal?.removeEventListener("abort", forwardAbort);
					}
				};
				return createRunHandle(t.agent, t.task, run, deliverBackground);
			});
			if (params.background) handles.forEach((h) => h.moveToBackground());
			handles.forEach((h) => foregroundRuns.add(h));
			let results: RunResult[];
			try {
				results = await Promise.all(handles.map(awaitForeground));
			} finally {
				handles.forEach((h) => foregroundRuns.delete(h));
			}
			const successCount = results.filter((r) => r.status === "ok").length;
			const backgrounded = results.filter((r) => r.status === "backgrounded").length;
			const header = tasks.length > 1 ? `Parallel: ${successCount}/${results.length - backgrounded} succeeded${backgrounded ? `, ${backgrounded} backgrounded` : ""}\n\n` : "";
			return {
				content: [{ type: "text", text: `${header}${results.map(formatResult).join("\n\n---\n\n")}` }],
				details: { results },
			};
		},
	});
}
