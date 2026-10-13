/**
 * Todo list the agent must keep for every task. The `todo` tool replaces the whole list.
 * Code enforces it: file changes need an in_progress item, a run cannot end with open
 * items without one nudge, and a stale list is shown again. Subagents are exempt.
 * A panel in the top-right corner shows the whole list, or only the count when collapsed. It starts collapsed. Alt+T toggles it.
 * The list is saved in the tool results of the session branch.
 */
import { StringEnum } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { Box, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { isReadOnlyBash } from "../permission/index.ts";
import { onPlanModeChange } from "../plan-mode/index.ts";
import { ENV } from "../subagent/protocol.ts";
import { blockReason, shouldRemind } from "./gate.ts";
import { checkTodos, formatTodos, openTodos, restoreTodos, STATUSES, TOOL_NAME, type Status, type Todo } from "./state.ts";

const PANEL_KEY = "todo";
const PANEL_WIDTH = 44;
const PANEL_PAD_X = 2;
const PANEL_PAD_Y = 1;
/** Nerd Font glyphs: nf-oct-circle, nf-md-circle, nf-md-check_circle, nf-md-close_circle. */
const ICONS: Record<Status, string> = { pending: "\u{f111}", in_progress: "\u{f0765}", completed: "\u{f05e0}", cancelled: "\u{f0159}" };
const REMIND_TYPE = "todo-reminder";
const FINISH_TYPE = "todo-finish";
const PLAN_DONE_TYPE = "todo-plan-approved";

const TodoParams = Type.Object({
	todos: Type.Array(
		Type.Object({
			content: Type.String({ description: "One short step" }),
			status: StringEnum(STATUSES),
		}),
		{ description: "The complete new list. It replaces the old list." },
	),
});

const DESCRIPTION =
	"Keep the todo list for the current task. Each call replaces the whole list. " +
	"Statuses: pending, in_progress, completed, cancelled. " +
	"Use this tool for EVERY task that changes anything, including one-step tasks. " +
	"Write the list before your first action. Set an item to in_progress before you start it. Keep only one item in_progress. " +
	"Mark an item completed right after you finish it. Do not batch updates. Add new steps when you find them. " +
	"Do not end your turn with pending or in_progress items, unless you wait for the user. Cancel items that you will not do. " +
	"Edit, write, and file-changing bash commands are blocked while no item is in_progress.";

export default function todo(pi: ExtensionAPI): void {
	let todos: Todo[] = [];
	let turnsSinceUpdate = 0;
	let finishNudged = false;
	let planJustApproved = false;
	let planMode: boolean | undefined;
	const isSubagent = process.env[ENV.resultFile] !== undefined;

	/** Set while the panel is shown. */
	let requestRender: (() => void) | undefined;
	/** The panel starts collapsed (hidden). */
	let expanded = false;

	const iconColor = (status: Status) => (status === "completed" ? "success" : status === "in_progress" ? "warning" : "dim");

	const summary = (): string => `Todos ${todos.length - openTodos(todos).length}/${todos.length}`;

	/** Every item. Long items wrap. `width` is the space inside the padding. */
	const panelLines = (theme: Theme, width: number): string[] =>
		todos.flatMap((item) => {
			const done = item.status === "completed" || item.status === "cancelled";
			const mark = theme.fg(iconColor(item.status), ICONS[item.status]);
			return wrapTextWithAnsi(item.content, Math.max(1, width - 2)).map((line, i) => (i ? "  " : `${mark} `) + (done ? theme.fg("dim", line) : line));
		});

	/** Show the panel while an item is open, hide it otherwise. */
	const showPanel = (ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;
		if (openTodos(todos).length === 0) {
			ctx.ui.setWidget(PANEL_KEY, undefined);
			return;
		}
		if (requestRender) {
			requestRender();
			return;
		}
		// A widget cannot sit in a corner. Its factory gets the TUI, so it opens a non-capturing overlay and hides it on dispose.
		ctx.ui.setWidget(PANEL_KEY, (tui, theme) => {
			// Same look as the MCP popup: solid background, padding, no border. The collapsed box has no vertical padding and a lighter background.
			const bg = (text: string) => theme.bg("userMessageBg", text);
			const full = new Box(PANEL_PAD_X, PANEL_PAD_Y, bg);
			full.addChild({ render: (width: number) => panelLines(theme, width), invalidate: () => {} });
			const collapsed = new Box(PANEL_PAD_X, 0, (text) => theme.bg("selectedBg", text));
			collapsed.addChild({ render: () => [theme.bold(theme.fg("accent", summary()))], invalidate: () => {} });
			const panel = {
				render: (width: number) => (expanded ? full : collapsed).render(width),
				invalidate: () => {
					full.invalidate();
					collapsed.invalidate();
				},
			};
			// The TUI reads the options on every render, so a getter keeps the width in step with the state.
			const options = {
				nonCapturing: true,
				anchor: "top-right" as const,
				get width() {
					return expanded ? PANEL_WIDTH : visibleWidth(summary()) + 2 * PANEL_PAD_X;
				},
			};
			const handle = tui.showOverlay(panel, options);
			requestRender = () => tui.requestRender();
			return {
				render: () => [],
				invalidate: () => {},
				dispose: () => {
					handle.hide();
					requestRender = undefined;
				},
			};
		});
	};

	const restore = (_event: unknown, ctx: ExtensionContext) => {
		todos = restoreTodos(ctx.sessionManager.getBranch());
		showPanel(ctx);
	};
	pi.registerShortcut("alt+t", {
		description: "Toggle todo panel",
		handler: () => {
			expanded = !expanded;
			requestRender?.();
		},
	});

	pi.on("session_start", restore);
	pi.on("session_tree", restore);

	pi.registerTool({
		name: TOOL_NAME,
		label: "Todo",
		description: DESCRIPTION,
		parameters: TodoParams,
		promptSnippet: "Keep a todo list for every task, even one-step tasks",
		promptGuidelines: [
			"Call the todo tool before your first action on every task, including one-step tasks. Keep it current: one in_progress item, mark items completed right away.",
		],
		executionMode: "sequential",

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			todos = checkTodos(params.todos);
			turnsSinceUpdate = 0;
				showPanel(ctx);
			return { content: [{ type: "text", text: formatTodos(todos) }], details: { todos } };
		},
	});

	if (isSubagent) return;

	onPlanModeChange(pi, (enabled) => {
		if (planMode && !enabled) planJustApproved = true;
		planMode = enabled;
	});

	pi.on("tool_call", async (event, ctx) => {
		if (planMode) return undefined;
		const reason = await blockReason(todos, event.toolName, event.input as Record<string, unknown>, (command) => isReadOnlyBash(command, ctx));
		return reason ? { block: true, reason } : undefined;
	});

	pi.on("before_agent_start", () => {
		finishNudged = false;
		if (!planJustApproved) return undefined;
		planJustApproved = false;
		return {
			message: {
				customType: PLAN_DONE_TYPE,
				content: `Plan mode is off. Call the ${TOOL_NAME} tool now: turn the approved plan into a todo list. Then start the first step.`,
				display: false,
			},
		};
	});

	pi.on("turn_end", () => {
		turnsSinceUpdate++;
	});

	pi.on("context", (event) => {
		if (!shouldRemind(todos, turnsSinceUpdate)) return undefined;
		turnsSinceUpdate = 0;
		const content = `Todo reminder: you did not update the list for a while. Current list:\n${formatTodos(todos)}\nCall the ${TOOL_NAME} tool to update it.`;
		return { messages: [...event.messages, { role: "custom", customType: REMIND_TYPE, content, display: false, timestamp: Date.now() }] };
	});

	pi.on("agent_before_settle", (event) => {
		if (planMode || finishNudged || event.outcome !== "completed" || openTodos(todos).length === 0) return undefined;
		finishNudged = true;
		const content = `The todo list has open items:\n${formatTodos(todos)}\nFinish them, or call ${TOOL_NAME} to complete or cancel them. If you wait for the user, say so.`;
		return { entries: [{ type: "custom_message", customType: FINISH_TYPE, content, display: false }], continue: true };
	});
}
