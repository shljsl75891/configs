/**
 * Pure command-building functions extracted from index.ts so they can be tested
 * without importing the full extension (which runs a startup sweep at module scope).
 */
import * as path from "node:path";
import { fileURLToPath } from "node:url";

const MARKER_EXTENSION_PATH = path.join(path.dirname(fileURLToPath(import.meta.url)), "marker-extension.ts");

/** POSIX shell-quote a single token. Single quotes are the safest wrapper; the
 *  only special character inside them is a lone `'`, which is escaped by ending
 *  the single-quoted string, emitting `"'"`, and restarting it. */
export function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'"'"'`)}'`;
}

export function buildPiCommand(opts: {
	model?: string;
	tools?: string[];
	systemPromptFile?: string;
	task: string;
	/** Propagates the parent session's plan mode to the spawned child, so a
	 *  subagent can't be used to bypass the parent's write restriction: the
	 *  child's own plan-mode extension picks this up on session_start, and
	 *  its own permission extension then denies edit/write/bash-writes the
	 *  same way the parent's does. */
	plan?: boolean;
}): string {
	const tokens = ["pi", "-e", MARKER_EXTENSION_PATH, "--no-session"];
	if (opts.model) tokens.push("--model", opts.model);
	if (opts.tools && opts.tools.length > 0) tokens.push("--tools", opts.tools.join(","));
	if (opts.systemPromptFile) tokens.push("--append-system-prompt", opts.systemPromptFile);
	/**
	 * "--plan=true", not bare "--plan": plan is an extension-registered
	 * flag, not one of the CLI's hardcoded ones (cli/args.js in
	 * pi-coding-agent), so the static parser's unknown-flag branch greedily
	 * consumes the *next* token as its value whenever that token doesn't
	 * start with "-"/"@" -- which the task string never does. Without "=",
	 * that swallows "Task: ..." into --plan's value (later discarded, since
	 * boolean extension flags ignore their captured value) and the child
	 * opens with no initial message at all. The "=" form is parsed by a
	 * different branch that never touches the next arg.
	 */
	if (opts.plan) tokens.push("--plan=true");
	tokens.push(`Task: ${opts.task}`);
	return tokens.map(shellQuote).join(" ");
}
