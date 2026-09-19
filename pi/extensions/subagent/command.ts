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
}): string {
	const tokens = ["pi", "-e", MARKER_EXTENSION_PATH, "--no-session"];
	if (opts.model) tokens.push("--model", opts.model);
	if (opts.tools && opts.tools.length > 0) tokens.push("--tools", opts.tools.join(","));
	if (opts.systemPromptFile) tokens.push("--append-system-prompt", opts.systemPromptFile);
	tokens.push(`Task: ${opts.task}`);
	return tokens.map(shellQuote).join(" ");
}
