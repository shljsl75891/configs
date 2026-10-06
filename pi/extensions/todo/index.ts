/**
 * Todo list for the agent and the user.
 * The agent edits it with the `todo` tool. Alt+T opens a popup to add, edit,
 * delete, and reorder items. Only the agent changes status. The list is saved in the
 * session branch. When the popup closes after edits, the agent gets a hidden message with the new list.
 */
import { StringEnum } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { Box, Input, matchesKey, Text, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import {
	addTodo,
	EMPTY,
	ENTRY_TYPE,
	formatTodos,
	isTodoState,
	moveTodo,
	removeTodo,
	restoreState,
	type Status,
	STATUSES,
	TOOL_NAME,
	type Todo,
	type TodoState,
	updateTodo,
} from "./state.ts";

const UPDATE_TYPE = "todo-update";
const MAX_ROWS = 12;

const TodoParams = Type.Object({
	action: StringEnum(["list", "add", "update", "delete"] as const),
	text: Type.Optional(Type.String({ description: "Todo text (add, update)" })),
	id: Type.Optional(Type.Number({ description: "Todo id (update, delete)" })),
	status: Type.Optional(StringEnum(STATUSES)),
});

function icon(theme: Theme, status: Status): string {
	if (status === "done") return theme.fg("success", "✓");
	if (status === "in_progress") return theme.fg("warning", "◐");
	return theme.fg("dim", "○");
}

function row(theme: Theme, todo: Todo): string {
	const text = todo.status === "done" ? theme.fg("dim", todo.text) : todo.text;
	return `${icon(theme, todo.status)} ${theme.fg("muted", `#${todo.id}`)} ${text}`;
}

export default function todo(pi: ExtensionAPI): void {
	let state = EMPTY;
	let open = false;
	let refresh: (() => void) | undefined;

	const restore = (_event: unknown, ctx: ExtensionContext) => {
		state = restoreState(ctx.sessionManager.getBranch());
	};
	pi.on("session_start", restore);
	pi.on("session_tree", restore);

	pi.registerTool({
		name: TOOL_NAME,
		label: "Todo",
		description:
			"Manage the todo list that the user also sees and can edit. Actions: list, add (text), update (id, text and/or status), delete (id). " +
			"Status is pending, in_progress, or done. " +
			"Use it before you start work with 3 or more steps, and right after the user approves a plan: add one item for each step. " +
			"Set an item to in_progress before you start it. Keep only one item in_progress. Mark it done as soon as you finish it. Add new steps when you find them. " +
			"Do not use it for one-step or trivial tasks, or to answer questions. " +
			"The user can change the list. Call list if you are not sure what it holds.",
		parameters: TodoParams,
		// The tool changes shared state, so calls must not run in parallel.
		executionMode: "sequential",
		promptSnippet: "Track multi-step work in the shared todo list",

		async execute(_toolCallId, params) {
			switch (params.action) {
				case "add":
					if (!params.text) throw new Error("text required for add");
					state = addTodo(state, params.text);
					break;
				case "update":
					if (params.id === undefined) throw new Error("id required for update");
					if (params.text === undefined && params.status === undefined) throw new Error("text or status required for update");
					state = updateTodo(state, params.id, { text: params.text, status: params.status });
					break;
				case "delete":
					if (params.id === undefined) throw new Error("id required for delete");
					state = removeTodo(state, params.id);
					break;
				case "list":
					break;
			}
			refresh?.();
			return { content: [{ type: "text", text: formatTodos(state) }], details: state };
		},

		renderResult(result, _options, theme) {
			if (!isTodoState(result.details)) {
				const first = result.content[0];
				return new Text(first?.type === "text" ? first.text : "", 0, 0);
			}
			const { todos } = result.details;
			return new Text(todos.length ? todos.map((todo) => row(theme, todo)).join("\n") : theme.fg("dim", "No todos"), 0, 0);
		},
	});

	pi.registerShortcut("alt+t", {
		description: "Show todos",
		handler: async (ctx) => {
			if (open) return;
			open = true;
			const before = formatTodos(state);
			/** Apply a popup edit. The agent can delete an item while the popup is open, so errors go to a notice. */
			const commit = (change: () => TodoState): boolean => {
				let next: TodoState;
				try {
					next = change();
				} catch (error) {
					ctx.ui.notify(error instanceof Error ? error.message : String(error), "warning");
					return false;
				}
				if (next === state) return false;
				state = next;
				pi.appendEntry(ENTRY_TYPE, state);
				return true;
			};
			try {
				await ctx.ui.custom(
					(tui, theme, _kb, done) => {
						let selected = 0;
						const clampSelected = () => {
							selected = Math.max(0, Math.min(selected, state.todos.length - 1));
						};
						let editing: { input: Input; id?: number } | undefined;

						const startInput = (id?: number) => {
							const input = new Input({ prompt: "" });
							input.focused = true;
							if (id !== undefined) {
								input.setValue(state.todos.find((t) => t.id === id)?.text ?? "");
								// Input has no cursor API; ctrl+e moves the cursor to the end.
								input.handleInput("\x05");
							}
							input.onEscape = () => {
								editing = undefined;
							};
							input.onSubmit = (value) => {
								const text = value.trim();
								if (id === undefined) {
									if (commit(() => addTodo(state, text))) selected = state.todos.length - 1;
								} else commit(() => updateTodo(state, id, { text }));
								editing = undefined;
							};
							editing = { input, id };
						};

						const box = new Box(2, 1, (text) => theme.bg("userMessageBg", text));
						box.addChild({
							render: (width: number) => {
								const title = theme.fg("accent", theme.bold("Todos"));
								return [" ".repeat(Math.max(0, Math.floor((width - visibleWidth(title)) / 2))) + title, ""];
							},
							invalidate: () => {},
						});
						box.addChild({
							render: (width: number) => {
								const lines: string[] = [];
								// The agent can delete items while the popup is open.
								clampSelected();
								if (state.todos.length === 0) lines.push(theme.fg("dim", "No todos"));
								const start = Math.max(0, Math.min(selected - Math.floor(MAX_ROWS / 2), state.todos.length - MAX_ROWS));
								for (const [i, item] of state.todos.slice(start, start + MAX_ROWS).entries()) {
									const cursor = start + i === selected ? theme.fg("accent", "▸") : " ";
									lines.push(truncateToWidth(`${cursor} ${row(theme, item)}`, width));
								}
								if (editing) lines.push("", ...editing.input.render(width));
								return lines;
							},
							invalidate: () => {},
						});

						const handleList = (data: string) => {
							const current = state.todos[selected];
							if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) done(undefined);
							else if (matchesKey(data, "shift+up") && current) {
								if (commit(() => moveTodo(state, current.id, -1))) selected -= 1;
							} else if (matchesKey(data, "shift+down") && current) {
								if (commit(() => moveTodo(state, current.id, 1))) selected += 1;
							} else if (matchesKey(data, "up") || matchesKey(data, "ctrl+p")) selected = Math.max(0, selected - 1);
							else if (matchesKey(data, "down") || matchesKey(data, "ctrl+n")) {
								selected += 1;
								clampSelected();
							} else if (matchesKey(data, "a")) startInput();
							else if ((matchesKey(data, "e") || matchesKey(data, "enter")) && current) {
								if (current.status !== "pending") ctx.ui.notify("Only pending items can be edited", "warning");
								else startInput(current.id);
							} else if (matchesKey(data, "d") && current) {
								commit(() => removeTodo(state, current.id));
								clampSelected();
							}
						};

						refresh = () => tui.requestRender();
						return {
							render: (width: number) => box.render(width),
							invalidate: () => box.invalidate(),
							handleInput: (data: string) => {
								if (matchesKey(data, "alt+t")) return;
								if (editing) editing.input.handleInput(data);
								else handleList(data);
								tui.requestRender();
							},
						};
					},
					{ overlay: true, overlayOptions: { anchor: "center", width: "35%", maxHeight: "90%" } },
				);
			} finally {
				open = false;
				refresh = undefined;
				// triggerTurn false: an idle agent reads it with the next prompt; a running agent gets it after the current tool batch.
				if (formatTodos(state) !== before) {
					pi.sendMessage(
						{ customType: UPDATE_TYPE, content: `The user changed the todo list. Current list:\n${formatTodos(state)}`, display: false },
						{ triggerTurn: false },
					);
				}
			}
		},
	});
}
