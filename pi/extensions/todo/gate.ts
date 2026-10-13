import { hasInProgress, openTodos, TOOL_NAME, type Todo } from "./state.ts";

/** Tool turns without a todo call before the agent gets a reminder. */
export const REMIND_AFTER_TURNS = 5;

const FILE_TOOLS = new Set(["edit", "write"]);

/** Return why a call is blocked, or undefined when it may run. File changes need an in_progress item. */
export async function blockReason(
	todos: readonly Todo[],
	toolName: string,
	input: Record<string, unknown>,
	isReadOnlyBash: (command: string) => Promise<boolean>,
): Promise<string | undefined> {
	if (hasInProgress(todos)) return undefined;
	const changesFiles = FILE_TOOLS.has(toolName) || (toolName === "bash" && !(await isReadOnlyBash(String(input.command ?? ""))));
	if (!changesFiles) return undefined;
	return `No todo is in_progress. Call the ${TOOL_NAME} tool first: list the steps and set the current one to in_progress. Then retry.`;
}

export const shouldRemind = (todos: readonly Todo[], turnsSinceUpdate: number): boolean =>
	turnsSinceUpdate >= REMIND_AFTER_TURNS && openTodos(todos).length > 0;
