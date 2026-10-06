export const STATUSES = ["pending", "in_progress", "done"] as const;
export type Status = (typeof STATUSES)[number];

export interface Todo {
	id: number;
	text: string;
	status: Status;
}

export interface TodoState {
	todos: readonly Todo[];
	nextId: number;
	/** Rises with every change. Restore uses it to find the newest state. */
	rev: number;
}

export const EMPTY: Readonly<TodoState> = { todos: [], nextId: 1, rev: 0 };

export const MARKS: Record<Status, string> = { pending: " ", in_progress: "~", done: "x" };

function indexOf(state: TodoState, id: number): number {
	const index = state.todos.findIndex((todo) => todo.id === id);
	if (index < 0) throw new Error(`Todo #${id} not found`);
	return index;
}

function cleanText(text: string): string {
	const clean = text.trim();
	if (!clean) throw new Error("Todo text must not be empty");
	return clean;
}

export function addTodo(state: TodoState, text: string): TodoState {
	const todo: Todo = { id: state.nextId, text: cleanText(text), status: "pending" };
	return { todos: [...state.todos, todo], nextId: state.nextId + 1, rev: state.rev + 1 };
}

export function updateTodo(state: TodoState, id: number, change: Partial<Pick<Todo, "text" | "status">>): TodoState {
	const index = indexOf(state, id);
	const old = state.todos[index];
	const next = { ...old, text: change.text === undefined ? old.text : cleanText(change.text), status: change.status ?? old.status };
	if (next.text !== old.text && old.status !== "pending") throw new Error(`Todo #${id} is ${old.status}. Set it to pending before you edit the text`);
	if (next.text === old.text && next.status === old.status) return state;
	return { ...state, todos: state.todos.map((todo, i) => (i === index ? next : todo)), rev: state.rev + 1 };
}

export function removeTodo(state: TodoState, id: number): TodoState {
	const index = indexOf(state, id);
	return { ...state, todos: state.todos.filter((_, i) => i !== index), rev: state.rev + 1 };
}

export function moveTodo(state: TodoState, id: number, delta: -1 | 1): TodoState {
	const from = indexOf(state, id);
	const to = from + delta;
	if (to < 0 || to >= state.todos.length) return state;
	const todos = [...state.todos];
	[todos[from], todos[to]] = [todos[to], todos[from]];
	return { ...state, todos, rev: state.rev + 1 };
}

export function formatTodos(state: TodoState): string {
	if (state.todos.length === 0) return "No todos";
	return state.todos.map((todo) => `[${MARKS[todo.status]}] #${todo.id} ${todo.text}`).join("\n");
}

/** Minimal shape of a session entry that can hold todo state. */
export interface SavedEntry {
	type: string;
	customType?: string;
	data?: unknown;
	message?: { role: string; toolName?: string; details?: unknown };
}

export const TOOL_NAME = "todo";
export const ENTRY_TYPE = "todo-state";

export function isTodoState(value: unknown): value is TodoState {
	const candidate = value as Partial<TodoState> | null;
	return Array.isArray(candidate?.todos) && typeof candidate.nextId === "number" && typeof candidate.rev === "number";
}

/** Return the newest saved state in a branch, oldest entry first. A failed tool call saves no state, so such entries are skipped. */
export function restoreState(entries: readonly SavedEntry[]): TodoState {
	let state = EMPTY;
	for (const entry of entries) {
		const isSaved = entry.type === "custom" && entry.customType === ENTRY_TYPE;
		const isToolResult = entry.type === "message" && entry.message?.role === "toolResult" && entry.message.toolName === TOOL_NAME;
		const saved = isSaved ? entry.data : isToolResult ? entry.message?.details : undefined;
		if (isTodoState(saved) && saved.rev >= state.rev) state = saved;
	}
	return state;
}
