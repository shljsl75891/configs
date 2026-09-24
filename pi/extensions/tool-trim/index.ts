/**
 * Shrinks built-in and mcp-adapter tool descriptions to Simplified Technical
 * English (ASD-STE100) right before the provider request goes out.
 *
 * Rewriting here, instead of overriding each tool, keeps the real
 * implementations (read/bash/edit/write/mcp/mcpScript) untouched. Only the
 * model-facing text shrinks.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type ParamText = Record<string, string>;

interface Trim {
	description: string;
	params?: ParamText;
}

const TRIMS: Record<string, Trim> = {
	Read: {
		description:
			"Reads a file. Use this tool, not cat or sed. It reads text and images (jpg, png, gif, webp, bmp). Text output stops at 2000 lines or 50KB. To read more, use offset and limit.",
		params: {
			path: "The file path.",
			offset: "The first line to read. Line 1 is the first line.",
			limit: "The maximum number of lines.",
		},
	},
	Bash: {
		description:
			"Runs a bash command in the current directory. Use it for ls, rg, find, and git. It returns stdout and stderr. It keeps the last 2000 lines or 50KB. The full output goes to a temporary file. PI_* variables show the model and session data.",
		params: {
			command: "The command.",
			timeout: "The time limit in seconds. Null means no limit.",
		},
	},
	Edit: {
		description:
			"Replaces exact text in one file. Put all changes for a file in one call. The tool compares each oldText with the original file. Each oldText must be unique and small. Edits must not overlap. If two changes are near, merge them into one edit.",
		params: {
			edits: "The replacements.",
			oldText: "The exact text to replace.",
			newText: "The new text.",
		},
	},
	Write: {
		description:
			"Writes a new file or replaces all of a file. It makes missing parent directories. To change part of a file, use Edit.",
		params: {
			path: "The file path.",
			content: "The file content.",
		},
	},
	mcpScript: {
		description:
			"Runs JavaScript that makes many MCP calls in one request. For one call, use mcp. tools.search({query}) returns {items, total, hasMore}. tools.describe({path}) returns the input schema. tools.call(path, args) returns {ok, data} or {ok: false, error}. Use emit(value) to show output. For more data, read the mcp-scripting skill.",
		params: {
			code: "The JavaScript code.",
			timeoutMs: "The time limit in milliseconds. Default 30000.",
		},
	},
};

// The mcp tool keeps its live "Disabled servers: ..." line (it changes as
// servers connect), so only the fixed lead-in is replaced.
const MCP_TOOL_NAME = "mcp";
const MCP_PREFIX =
	"Controls MCP servers and calls one MCP tool. Use it for status, search, describe, install, auth, and single calls. For many calls with logic between them, use mcpScript. The tool uses the first parameter that is set, in this order: action, tool, connect, describe, instructions, search, server. With no parameters, it shows the status.";
const MCP_DISABLED_RE = /Disabled servers[^\n]*/;

function stripNestedDescriptions(schema: unknown): void {
	if (!schema || typeof schema !== "object") return;
	const node = schema as Record<string, unknown>;
	if (Array.isArray(node.anyOf)) {
		for (const branch of node.anyOf) stripNestedDescriptions(branch);
	}
	if (node.items) stripNestedDescriptions(node.items);
	if (node.properties && typeof node.properties === "object") {
		for (const value of Object.values(node.properties as Record<string, unknown>)) {
			stripNestedDescriptions(value);
		}
	}
	if (Array.isArray(node.anyOf) || node.items || node.properties) {
		delete node.description;
	}
}

function applyParamText(properties: Record<string, unknown> | undefined, params: ParamText): void {
	if (!properties) return;
	for (const [name, text] of Object.entries(params)) {
		const prop = properties[name];
		if (prop && typeof prop === "object") {
			(prop as Record<string, unknown>).description = text;
			stripNestedDescriptions(prop);
		}
	}
}

export default function toolTrim(pi: ExtensionAPI): void {
	pi.on("before_provider_request", (event) => {
		const payload = event.payload as { tools?: unknown[] } | undefined;
		if (!payload || !Array.isArray(payload.tools)) return undefined;

		for (const tool of payload.tools) {
			if (!tool || typeof tool !== "object") continue;
			const t = tool as Record<string, unknown>;
			const name = t.name as string | undefined;
			if (!name) continue;

			const trim = TRIMS[name];
			if (trim) {
				t.description = trim.description;
				const schema = t.input_schema as { properties?: Record<string, unknown> } | undefined;
				if (trim.params && schema?.properties) applyParamText(schema.properties, trim.params);
				continue;
			}

			if (name === MCP_TOOL_NAME && typeof t.description === "string") {
				const disabled = t.description.match(MCP_DISABLED_RE);
				t.description = disabled ? `${MCP_PREFIX} ${disabled[0]}` : MCP_PREFIX;
			}
		}

		return payload;
	});
}
