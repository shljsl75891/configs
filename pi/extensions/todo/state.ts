export const TOOL_NAME = "todo";
export const STATUSES = ["pending", "in_progress", "completed", "cancelled"] as const;
export type Status = (typeof STATUSES)[number];

export interface Todo {
	content: string;
	status: Status;
}

const MARKS: Record<Status, string> = { pending: " ", in_progress: "~", completed: "x", cancelled: "-" };

/** Return a clean copy of a new list, or throw so the agent sees why the call failed. */
export function checkTodos(todos: readonly Todo[]): Todo[] {
	const clean = todos.map((todo) => {
		const content = todo.content.trim();
		if (!content) throw new Error("Todo content must not be empty");
		return { content, status: todo.status };
	});
	if (clean.filter((todo) => todo.status === "in_progress").length > 1) throw new Error("Only one in_progress item is allowed");
	return clean;
}

export const hasInProgress = (todos: readonly Todo[]): boolean => todos.some((todo) => todo.status === "in_progress");

export const openTodos = (todos: readonly Todo[]): Todo[] => todos.filter((todo) => todo.status === "pending" || todo.status === "in_progress");

export function formatTodos(todos: readonly Todo[]): string {
	if (todos.length === 0) return "No todos";
	return todos.map((todo) => `[${MARKS[todo.status]}] ${todo.content}`).join("\n");
}

/** Minimal shape of a session entry that can hold a todo list. */
export interface SavedEntry {
	type: string;
	message?: { role: string; toolName?: string; details?: unknown };
}

function isTodoList(value: unknown): value is Todo[] {
	return Array.isArray(value) && value.every((todo) => typeof todo?.content === "string" && STATUSES.includes(todo.status));
}

/** Return the list from the last valid todo result in a branch. Old-format and failed results are skipped. */
export function restoreTodos(entries: readonly SavedEntry[]): Todo[] {
	let todos: Todo[] = [];
	for (const { type, message } of entries) {
		if (type !== "message" || message?.role !== "toolResult" || message.toolName !== TOOL_NAME) continue;
		const saved = (message.details as { todos?: unknown } | undefined)?.todos;
		if (isTodoList(saved)) todos = saved;
	}
	return todos;
}
