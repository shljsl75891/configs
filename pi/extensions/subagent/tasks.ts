/**
 * Task normalisation and timeout clamping extracted from execute() so they
 * can be unit-tested without importing the full extension module.
 */

export const MAX_CONCURRENT = 4;
export const DEFAULT_TIMEOUT_MS = 10 * 60 * 1000;
export const MIN_TIMEOUT_MS = 1_000;
export const MAX_TIMEOUT_MS = 60 * 60 * 1_000;

export interface TaskItem {
	agent: string;
	task: string;
}

const INVALID_PARAMS = "Invalid parameters: provide exactly one of { agent, task } or { tasks: [...] }.";

/**
 * Normalise `{agent, task}` or `{tasks:[...]}` into a canonical task list.
 * Throws before any prompting so an invalid call cannot ask about agents it
 * will then refuse; pi's tool runner converts the throw into an error result.
 */

export function normalizeTasks(params: {
	tasks?: { agent: string; task: string }[];
	agent?: string;
	task?: string;
}): TaskItem[] {
	if (params.tasks != null && (params.agent != null || params.task != null)) throw new Error(INVALID_PARAMS);
	const fromBatch = params.tasks?.length ? params.tasks : null;
	const fromSingle = params.agent && params.task ? [{ agent: params.agent, task: params.task }] : null;
	const tasks = fromBatch ?? fromSingle;
	if (!tasks) throw new Error(INVALID_PARAMS);
	if (tasks.length > MAX_CONCURRENT) throw new Error(`Too many parallel tasks (${tasks.length}). Max is ${MAX_CONCURRENT}.`);
	return tasks;
}

/** Clamp an optional timeout to the allowed range, falling back to the default. */
export function clampTimeout(requested: number | undefined): number {
	if (requested == null || !Number.isFinite(requested)) return DEFAULT_TIMEOUT_MS;
	return Math.min(Math.max(requested, MIN_TIMEOUT_MS), MAX_TIMEOUT_MS);
}
