import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { askQuestions, CUSTOM_LABEL } from "./prompt.ts";
import type { QuestionSpec } from "./state.ts";

const MIME_TYPES: Record<string, string> = {
	".png": "image/png",
	".jpg": "image/jpeg",
	".jpeg": "image/jpeg",
	".gif": "image/gif",
	".webp": "image/webp",
	".bmp": "image/bmp",
};

interface QuestionDetails {
	questions: { question: string; header: string; options: string[] }[];
	answers: string[][];
}

const OptionSchema = Type.Object({
	label: Type.String({ description: "Display text, 1-5 words" }),
	description: Type.Optional(Type.String({ description: "Optional explanation shown below the label" })),
});

const QuestionSchema = Type.Object({
	question: Type.String({ description: "The complete question" }),
	header: Type.String({ description: "Very short tab label, max 30 chars" }),
	options: Type.Array(OptionSchema, { description: "Choices to offer" }),
	multiple: Type.Optional(Type.Boolean({ description: "Allow selecting more than one choice" })),
});

const QuestionParams = Type.Object({
	questions: Type.Array(QuestionSchema, { description: "Questions to ask, answered together" }),
});

/** Pasted images arrive as file paths in the answer text; send the bytes, not the path. */
function imagesIn(text: string): { type: "image"; data: string; mimeType: string }[] {
	return text.split(/\s+/).flatMap((token) => {
		const mimeType = MIME_TYPES[path.extname(token).toLowerCase()];
		if (!mimeType) return [];
		try {
			return [{ type: "image" as const, data: fs.readFileSync(token).toString("base64"), mimeType }];
		} catch {
			return [];
		}
	});
}

function summarize(questions: QuestionSpec[], answers: string[][]): string {
	const parts = questions.map((q, i) => `"${q.question}"="${answers[i].join(", ") || "Unanswered"}"`);
	return `User has answered your questions: ${parts.join(", ")}.`;
}

export default function question(pi: ExtensionAPI) {
	pi.registerTool({
		name: "question",
		label: "Question",
		description:
			"Ask the user one or more questions and let them pick from options. Use when you need user input to proceed. " +
			"Each question needs a short `header` (used as a tab label) and at least one option — never call this tool " +
			"as a standalone intro with no options. A 'Type your own answer' choice is added automatically, so never " +
			"author your own 'Other' option. To recommend a choice, put it first and append '(Recommended)' to its label. " +
			"Answers come back as the option labels the user chose; an unanswered question comes back empty.",
		parameters: QuestionParams,
		executionMode: "sequential",

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const questions = params.questions as QuestionSpec[];
			const details: QuestionDetails = {
				questions: questions.map((q) => ({
					question: q.question,
					header: q.header,
					options: q.options.map((o) => o.label),
				})),
				answers: questions.map(() => []),
			};

			if (ctx.mode !== "tui") {
				return {
					content: [{ type: "text", text: "Error: UI not available (running in non-interactive mode)" }],
					details,
				};
			}
			if (questions.length === 0 || questions.some((q) => q.options.length === 0)) {
				return { content: [{ type: "text", text: "Error: every question needs at least one option" }], details };
			}

			const answers = await askQuestions(ctx.ui, questions);

			if (!answers) {
				return { content: [{ type: "text", text: "User cancelled the selection" }], details };
			}

			details.answers = answers;
			return {
				content: [{ type: "text", text: summarize(questions, answers) }, ...answers.flat().flatMap(imagesIn)],
				details,
			};
		},

		renderCall(args, theme, _context) {
			const questions = (Array.isArray(args.questions) ? args.questions : []) as QuestionSpec[];
			let text = theme.fg("toolTitle", theme.bold("question "));
			text += theme.fg("muted", questions.map((q) => q.header).join(" • "));
			for (const q of questions) {
				const labels = [...q.options.map((o) => o.label), CUSTOM_LABEL].map((o, i) => `${i + 1}. ${o}`);
				text += `\n${theme.fg("muted", `  ${q.question}`)}`;
				text += `\n${theme.fg("dim", `    ${labels.join(", ")}`)}`;
			}
			return new Text(text, 0, 0);
		},

		renderResult(result, _options, theme, _context) {
			const details = result.details as QuestionDetails | undefined;
			if (!details) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "", 0, 0);
			}
			if (details.answers.every((answer) => answer.length === 0)) {
				return new Text(theme.fg("warning", "Cancelled"), 0, 0);
			}
			const lines = details.questions.map((q, i) => {
				const answer = details.answers[i]?.join(", ");
				return answer
					? `${theme.fg("success", "✓ ")}${theme.fg("muted", `${q.header}: `)}${theme.fg("accent", answer)}`
					: `${theme.fg("dim", `· ${q.header}: unanswered`)}`;
			});
			return new Text(lines.join("\n"), 0, 0);
		},
	});
}
