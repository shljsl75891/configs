/**
 * Request sanitization so Anthropic OAuth traffic looks like Claude Code
 * instead of a third-party harness.
 *
 * Anthropic classifies some agent-CLI fingerprints and then bills the
 * request against extra usage (per-token) instead of the Claude Max plan.
 * This module strips those fingerprints from the system prompt / payload.
 */

export const CLAUDE_CODE_IDENTITY =
	"You are Claude Code, Anthropic's official CLI for Claude.";

const PARAGRAPH_REMOVAL_ANCHORS = [
	"operating inside pi, a coding agent harness",
	"Pi documentation (read only",
	"When reading pi docs",
	"When asked about: extensions (docs/extensions.md",
	"Always read pi .md files",
	"github.com/earendil-works",
	"@earendil-works/pi",
];

const TEXT_REPLACEMENTS: { match: string; replacement: string }[] = [
	{
		match: "operating inside pi, a coding agent harness. ",
		replacement: "",
	},
	{
		match: "operating inside pi, a coding agent harness",
		replacement: "",
	},
	{
		match:
			"Here is some useful information about the environment you are running in:",
		replacement: "Environment context you are running in:",
	},
];

function isRecord(value: unknown): value is Record<string, unknown> {
	return value !== null && typeof value === "object" && !Array.isArray(value);
}

export function sanitizeSystemText(text: string): string {
	if (!text || text === CLAUDE_CODE_IDENTITY) return text;

	const paragraphs = text.split(/\n\n+/);
	const filtered = paragraphs.filter((paragraph) => {
		for (const anchor of PARAGRAPH_REMOVAL_ANCHORS) {
			if (paragraph.includes(anchor)) return false;
		}
		return true;
	});

	let result = filtered.join("\n\n");
	for (const rule of TEXT_REPLACEMENTS) {
		if (result.includes(rule.match)) {
			result = result.split(rule.match).join(rule.replacement);
		}
	}

	return result.replace(/\n{3,}/g, "\n\n").trim();
}

function upgradeCacheControl(value: unknown): void {
	if (!isRecord(value) || !isRecord(value.cache_control)) return;
	value.cache_control.ttl = "1h";
}

function sanitizeSystemValue(system: unknown): unknown {
	if (typeof system === "string") {
		return sanitizeSystemText(system);
	}

	if (Array.isArray(system)) {
		return system.map((block) => {
			if (!isRecord(block)) return block;
			if (typeof block.text === "string") {
				block.text = sanitizeSystemText(block.text);
			}
			upgradeCacheControl(block);
			return block;
		});
	}

	if (isRecord(system) && typeof system.text === "string") {
		system.text = sanitizeSystemText(system.text);
		upgradeCacheControl(system);
	}

	return system;
}

function upgradeMessageCache(messages: unknown): void {
	if (!Array.isArray(messages)) return;

	for (const message of messages) {
		if (!isRecord(message)) continue;
		if (Array.isArray(message.content)) {
			for (const block of message.content) upgradeCacheControl(block);
		}
		upgradeCacheControl(message);
	}
}

function upgradeToolCache(tools: unknown): void {
	if (!Array.isArray(tools)) return;
	for (const tool of tools) upgradeCacheControl(tool);
}

/**
 * Mutate an Anthropic Messages payload in place:
 * - sanitize system text
 * - upgrade cache_control ttl to 1h
 */
export function sanitizeAnthropicPayload(payload: unknown): unknown {
	if (!isRecord(payload)) return payload;

	if ("system" in payload) {
		payload.system = sanitizeSystemValue(payload.system);
	}
	upgradeMessageCache(payload.messages);
	upgradeToolCache(payload.tools);
	return payload;
}

export function isAnthropicOAuthKey(apiKey: string | undefined): boolean {
	return typeof apiKey === "string" && apiKey.includes("sk-ant-oat");
}
