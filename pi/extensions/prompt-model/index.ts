/**
 * Prompt template `model:` frontmatter.
 *
 * Syntax: `model: provider/id[:thinking]`, same as the `--model` CLI flag.
 * Switches the session model (and thinking level) before the template runs.
 * The switch stays after the run.
 */
import { readFile } from "node:fs/promises";

import {
	parseFrontmatter,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";

import { errorText } from "../lib/errors.ts";
import { modelKey, parseModelKey } from "../lib/model.ts";

/** Taken from `setThinkingLevel` because the package index does not export the type. */
type ThinkingLevel = Parameters<ExtensionAPI["setThinkingLevel"]>[0];

/** `Record` makes the compiler flag any level that pi adds. */
const THINKING_LEVELS: Record<ThinkingLevel, true> = {
	off: true,
	minimal: true,
	low: true,
	medium: true,
	high: true,
	xhigh: true,
	max: true,
};
const COMMAND_NAME = /^\/(\S+)/;

export default function (pi: ExtensionAPI) {
	pi.on("input", async (event, ctx) => {
		// Queued input runs after the current turn. A switch now would change the running turn.
		if (event.streamingBehavior) return;
		const name = COMMAND_NAME.exec(event.text)?.[1];
		if (!name) return;
		try {
			await applyTemplateModel(pi, ctx, name);
		} catch (error) {
			ctx.ui.notify(`/${name}: ${errorText(error)}`, "warning");
		}
	});
}

async function applyTemplateModel(pi: ExtensionAPI, ctx: ExtensionContext, name: string): Promise<void> {
	const command = pi.getCommands().find((c) => c.name === name && c.source === "prompt");
	if (!command) return;

	const value = parseFrontmatter(await readFile(command.sourceInfo.path, "utf-8")).frontmatter.model;
	if (value == null) return;
	if (typeof value !== "string") throw new Error('"model" must be a string');

	const { key, level } = splitThinking(value);
	const ref = parseModelKey(key);
	if (!ref) throw new Error(`model "${key}" must be provider/id`);
	const model = ctx.modelRegistry.find(ref.provider, ref.id);
	if (!model) throw new Error(`model "${key}" not found`);
	if (key !== modelKey(ctx.model) && !(await pi.setModel(model))) {
		throw new Error(`no auth for ${model.provider}`);
	}
	if (level) pi.setThinkingLevel(level);
}

/** Splits a trailing ":level". Other colons stay in the id, such as "ollama/qwen:7b". */
function splitThinking(value: string): { key: string; level?: ThinkingLevel } {
	const colon = value.lastIndexOf(":");
	const suffix = value.slice(colon + 1);
	return colon > 0 && isThinkingLevel(suffix)
		? { key: value.slice(0, colon), level: suffix }
		: { key: value };
}

function isThinkingLevel(text: string): text is ThinkingLevel {
	return Object.hasOwn(THINKING_LEVELS, text);
}
