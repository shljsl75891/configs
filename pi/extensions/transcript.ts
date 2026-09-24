/**
 * /transcript
 *
 * Writes a clean markdown transcript of the active session branch: user
 * input, final assistant text, and question-tool decisions only. Thinking
 * blocks and every other tool call/result are dropped, so the file is safe
 * to hand to a non-technical reader.
 */
import { writeFile } from "node:fs/promises";
import { resolve } from "node:path";

import type {
	ExtensionAPI,
	SessionEntry,
	SessionMessageEntry,
} from "@earendil-works/pi-coding-agent";
import type { AssistantMessage, UserMessage } from "@earendil-works/pi-ai";
import type { QuestionDetails } from "./question-tool/index.ts";

interface TranscriptBlock {
	label: "You" | "Assistant" | "Pi asked";
	text: string;
}

function isQuestionDetails(details: unknown): details is QuestionDetails {
	const d = details as QuestionDetails | undefined;
	return Array.isArray(d?.headers) && Array.isArray(d?.answers);
}

function contentToText(content: UserMessage["content"] | AssistantMessage["content"]): string {
	if (typeof content === "string") return content.trim();
	const parts: string[] = [];
	for (const part of content) {
		if (part.type === "text") parts.push(part.text);
		else if (part.type === "image") parts.push("[image attached]");
	}
	return parts.join("\n\n").trim();
}

function questionDecisionText(details: unknown): string {
	if (!isQuestionDetails(details) || details.cancelled) return "";
	const { headers, answers } = details;
	return headers.map((header, i) => `- ${header}: ${answers[i]?.join(", ") || "unanswered"}`).join("\n");
}

function extractBlock(entry: SessionMessageEntry): TranscriptBlock | null {
	const message = entry.message;

	if (message.role === "user" || message.role === "assistant") {
		const text = contentToText(message.content);
		return text ? { label: message.role === "user" ? "You" : "Assistant", text } : null;
	}

	if (message.role === "toolResult" && message.toolName === "question") {
		const text = questionDecisionText(message.details);
		return text ? { label: "Pi asked", text } : null;
	}

	return null;
}

function extractBlocks(entries: SessionEntry[]): TranscriptBlock[] {
	const blocks: TranscriptBlock[] = [];

	for (const entry of entries) {
		if (entry.type !== "message") continue;
		const block = extractBlock(entry);
		if (!block) continue;

		const prev = blocks[blocks.length - 1];
		if (prev && prev.label === block.label) {
			prev.text += `\n\n${block.text}`;
		} else {
			blocks.push(block);
		}
	}

	return blocks;
}

function renderTranscript(title: string, blocks: TranscriptBlock[]): string {
	const rendered = blocks.map((b) => `**${b.label}:**\n\n${b.text}`).join("\n\n---\n\n");
	return `# ${title}\n\n${rendered}\n`;
}

function defaultOutputPath(cwd: string): string {
	const stamp = new Date().toISOString().replace(/[-:]/g, "").replace(/\..+$/, "");
	return resolve(cwd, `pi-transcript-${stamp}.md`);
}

export default function transcript(pi: ExtensionAPI): void {
	pi.registerCommand("transcript", {
		description: "Export a clean transcript (input/output only) to markdown",
		handler: async (args, ctx) => {
			const blocks = extractBlocks(ctx.sessionManager.getBranch());
			if (blocks.length === 0) {
				ctx.ui.notify("Nothing to export: no user or assistant messages in this branch", "warning");
				return;
			}

			const title = ctx.sessionManager.getSessionName() ?? `Pi Session Transcript — ${new Date().toLocaleString()}`;
			const markdown = renderTranscript(title, blocks);

			const target = args.trim();
			const outputPath = target ? resolve(ctx.cwd, target) : defaultOutputPath(ctx.cwd);

			try {
				await writeFile(outputPath, markdown, "utf8");
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`Could not write ${outputPath}: ${message}`, "error");
				return;
			}

			ctx.ui.notify(`Transcript written to ${outputPath}`, "info");
		},
	});
}
