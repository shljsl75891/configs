/** Renders the XML agent-listing block injected into the system prompt. */

import type { AgentConfig } from "./agents.ts";

function escapeXml(value: string): string {
	return value
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;")
		.replace(/'/g, "&apos;");
}

export function renderAgentBlock(agents: AgentConfig[]): string {
	const lines = [
		"Delegate to these with the `subagent` tool when a task matches one. Each agent runs with",
		"no conversation context, so the task text must be self-contained.",
		"",
		"<available_agents>",
	];
	for (const a of agents) {
		lines.push("  <agent>");
		lines.push(`    <name>${escapeXml(a.name)}</name>`);
		lines.push(`    <description>${escapeXml(a.description)}</description>`);
		lines.push("  </agent>");
	}
	lines.push("</available_agents>");
	return lines.join("\n");
}
