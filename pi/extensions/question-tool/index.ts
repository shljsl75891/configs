import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { askQuestions, CUSTOM_LABEL } from "./prompt.ts";
import type { QuestionSpec } from "./state.ts";

export interface QuestionDetails {
	headers: string[];
	answers: string[][];
	cancelled: boolean;
}

const OptionSchema = Type.Object({
	label: Type.String({ description: "The option text. Use 1 to 5 words. Add ' *' at the end for the recommended option." }),
	description: Type.Optional(Type.String({ description: "An explanation. It shows below the label." })),
});

const QuestionSchema = Type.Object({
	question: Type.String({ description: "The question text." }),
	header: Type.String({ description: "A tab label. Maximum 30 characters." }),
	options: Type.Array(OptionSchema, { description: "The options." }),
	multiple: Type.Optional(Type.Boolean({ description: "Set true to allow more than one choice." })),
});

const QuestionParams = Type.Object({
	questions: Type.Array(QuestionSchema, { description: "The questions. The tool asks all of them together." }),
});

function summarize(questions: QuestionSpec[], answers: string[][]): string {
	const parts = questions.map((q, i) => `"${q.question}"="${answers[i].join(", ") || "Unanswered"}"`);
	return `User has answered your questions: ${parts.join(", ")}.`;
}

export default function question(pi: ExtensionAPI) {
	pi.registerTool({
		name: "question",
		label: "Question",
		description:
			"Asks the user questions. Each question must have a header and one or more options. The header is a tab label, 30 characters maximum. " +
			"The tool adds a free-text option. Do not add an 'Other' option. " +
			"Put the recommended option first. Add ' *' to the end of its label. " +
			"The tool returns the selected labels. If the user does not answer, the result is empty.",
		parameters: QuestionParams,
		executionMode: "sequential",

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const questions: QuestionSpec[] = params.questions;
			const details: QuestionDetails = {
				headers: questions.map((q) => q.header),
				answers: questions.map(() => []),
				cancelled: false,
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

			const result = await askQuestions(ctx.ui, questions, { signal });

			if (!result) {
				return { content: [{ type: "text", text: "User cancelled the selection" }], details: { ...details, cancelled: true } };
			}

			details.answers = result.answers;
			return {
				content: [
					{ type: "text", text: summarize(questions, result.answers) },
					...result.images.map(({ data, mimeType }) => ({ type: "image" as const, data, mimeType })),
				],
				details,
			};
		},

		renderCall(args, theme, _context) {
			const questions = (Array.isArray(args.questions) ? args.questions : []).filter(
				(q): q is QuestionSpec => Boolean(q?.question && q?.header && Array.isArray(q?.options)),
			);
			let text = theme.fg("toolTitle", theme.bold("question "));
			text += theme.fg("muted", questions.map((q) => q.header).join(" • "));
			for (const q of questions) {
				const labels = [...q.options.map((o) => o?.label ?? ""), CUSTOM_LABEL].map((o, i) => `${i + 1}. ${o}`);
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
			if (details.cancelled) {
				return new Text(theme.fg("warning", "Cancelled"), 0, 0);
			}
			const lines = details.headers.map((header, i) => {
				const answer = details.answers[i]?.join(", ");
				return answer
					? `${theme.fg("success", "✓ ")}${theme.fg("muted", `${header}: `)}${theme.fg("accent", answer)}`
					: `${theme.fg("dim", `· ${header}: unanswered`)}`;
			});
			return new Text(lines.join("\n"), 0, 0);
		},
	});
}
