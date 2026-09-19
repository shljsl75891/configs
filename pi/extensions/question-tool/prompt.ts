import * as path from "node:path";
import type { ExtensionUIContext } from "@earendil-works/pi-coding-agent";
import {
	Editor,
	type EditorTheme,
	Key,
	matchesKey,
	type TuiMouseEvent,
	visibleWidth,
	wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { type Action, answersOf, createState, customRow, isConfirmTab, type QuestionSpec, type State, reduce } from "./state.ts";
import { findPiRoot } from "./pi-root.ts";


export const CUSTOM_LABEL = "Type your own answer";

export type PastedImage = { token: string; data: string; mimeType: string };
export type AskResult = { answers: string[][]; images: PastedImage[] };

type ClipboardApi = {
	readClipboardImage(): Promise<{ bytes: Uint8Array; mimeType: string } | null>;
	readClipboardText(): Promise<string | null>;
};

let clipboardApi: Promise<ClipboardApi | null> | undefined;

/**
 * pi implements clipboard reading in files it does not export, and its `exports`
 * map blocks the subpath, so they are imported by absolute path. Private API:
 * assume it can vanish in any release.
 */
function loadClipboardApi(): Promise<ClipboardApi | null> {
	clipboardApi ??= (async () => {
		try {
			const root = findPiRoot();
			if (!root) return null;
			const image = await import(path.join(root, "dist/utils/clipboard-image.js"));
			const text = await import(path.join(root, "dist/utils/clipboard.js"));
			return {
				readClipboardImage: image.readClipboardImage,
				readClipboardText: text.readClipboardText,
			};
		} catch {
			return null;
		}
	})();
	return clipboardApi;
}

const MIN_QUESTION_LINES = 3;
const MAX_QUESTION_LINES = 12;
/** Rows drawn outside the question text: separators, tabs, options, hints. */
const CHROME_ROWS = 14;
const PAGE_SCROLL_LINES = 5;

function hintFor(state: State, questions: QuestionSpec[], scrolling: boolean): string {
	if (state.editing) return "Enter to submit \u2022 Ctrl+V to paste an image \u2022 Esc to go back";
	if (isConfirmTab(state, questions)) return "Enter to submit \u2022 \u2190\u2192 to revisit \u2022 Esc to cancel";
	if (scrolling) return "\u2191\u2193 navigate \u2022 1-9 select \u2022 \u2190\u2192 switch \u2022 Enter to choose \u2022 PgUp/PgDn scroll text \u2022 Esc to cancel";
	return "\u2191\u2193 navigate \u2022 1-9 select \u2022 \u2190\u2192 switch \u2022 Enter to choose \u2022 Esc to cancel";
}

/**
 * Renders the question UI and resolves with the chosen labels and any pasted
 * images still referenced in those answers (carried as base64 tokens), or null
 * when dismissed. An aborted signal dismisses it too, so callers distinguish
 * the two by checking the signal afterwards.
 */
export function askQuestions(
	ui: Pick<ExtensionUIContext, "custom">,
	questions: QuestionSpec[],
	options: { signal?: AbortSignal } = {},
): Promise<AskResult | null> {
	// Guard pre-aborted signals: addEventListener won't fire for an already-aborted signal.
	if (options.signal?.aborted) return Promise.resolve(null);
	return ui.custom<AskResult | null>((tui, theme, keybindings, done) => {
		let state = createState(questions);
		let warning: string | null = null;
		let cache: { width: number; rows: number; lines: string[] } | undefined;
		const rows = new Map<number, Action>();
		let tabBar: { line: number; ends: number[] } | undefined;
		let questionScroll = 0;
		let questionTextRegion: { start: number; end: number; total: number } | undefined;
		const pastedImages: PastedImage[] = [];

		const dismiss = () => done(null);
		options.signal?.addEventListener("abort", dismiss, { once: true });

		const editorTheme: EditorTheme = {
			borderColor: (s) => theme.fg("accent", s),
			selectList: {
				selectedPrefix: (t) => theme.fg("accent", t),
				selectedText: (t) => theme.fg("accent", t),
				description: (t) => theme.fg("muted", t),
				scrollInfo: (t) => theme.fg("dim", t),
				noMatch: (t) => theme.fg("warning", t),
			},
		};
		const editor = new Editor(tui, editorTheme);

		function refresh() {
			cache = undefined;
			tui.requestRender();
		}

		/** Returns the max visible lines for the scrollable question text region. */
		const questionLineBudget = () =>
			Math.max(MIN_QUESTION_LINES, Math.min(MAX_QUESTION_LINES, tui.terminal.rows - CHROME_ROWS));

		/** Scroll question text by `delta` lines, clamped to valid range. */
		const scrollQuestion = (delta: number) => {
			const budget = questionLineBudget();
			const max = Math.max(0, (questionTextRegion?.total ?? 0) - budget);
			questionScroll = Math.max(0, Math.min(questionScroll + delta, max));
			refresh();
		};

		function apply(action: Action) {
			warning = null;
			const wasEditing = state.editing;
			const prevTab = state.tab;
			state = reduce(state, action, questions);
			if (state.submitted) {
				const answers = answersOf(state, questions);
				const flat = answers.flat();
				done({ answers, images: pastedImages.filter((img) => flat.some((a) => a.includes(img.token))) });
				return;
			}
			if (state.tab !== prevTab) { questionScroll = 0; questionTextRegion = undefined; }
			if (state.editing && !wasEditing) editor.setText(state.custom[state.tab] ?? "");
			refresh();
		}

		editor.onSubmit = (value) => {
			const text = value.trim();
			if (text) apply({ type: "custom", text });
			else apply({ type: "cancelEdit" });
		};

		async function pasteFromClipboard() {
			const clipboard = await loadClipboardApi();
			if (!clipboard) {
				warning = "Image paste unavailable — pi internals moved";
				refresh();
				return;
			}
			try {
				const image = await clipboard.readClipboardImage();
				if (image) {
					const token = `[image:${pastedImages.length + 1}]`;
					pastedImages.push({ token, data: Buffer.from(image.bytes).toString("base64"), mimeType: image.mimeType });
					editor.insertTextAtCursor(token);
				} else {
					const text = await clipboard.readClipboardText();
					if (text) editor.insertTextAtCursor(text);
				}
			} catch (error) {
				warning = `Paste failed: ${error instanceof Error ? error.message : String(error)}`;
			}
			refresh();
		}

		function handleInput(data: string) {
			if (state.editing) {
				if (keybindings.matches(data, "app.clipboard.pasteImage")) {
					void pasteFromClipboard();
					return;
				}
				if (matchesKey(data, Key.escape)) {
					apply({ type: "cancelEdit" });
					return;
				}
				editor.handleInput(data);
				refresh();
				return;
			}

			if (matchesKey(data, Key.escape)) {
				done(null);
				return;
			}
			if (matchesKey(data, Key.enter)) {
				apply({ type: "choose" });
				return;
			}
			if (matchesKey(data, Key.pageUp)) {
				scrollQuestion(-PAGE_SCROLL_LINES);
				return;
			}
			if (matchesKey(data, Key.pageDown)) {
				scrollQuestion(PAGE_SCROLL_LINES);
				return;
			}
			if (matchesKey(data, Key.up) || data === "k") {
				apply({ type: "cursor", delta: -1 });
				return;
			}
			if (matchesKey(data, Key.down) || data === "j") {
				apply({ type: "cursor", delta: 1 });
				return;
			}
			if (matchesKey(data, Key.right) || matchesKey(data, Key.tab) || data === "l") {
				apply({ type: "tab", delta: 1 });
				return;
			}
			if (matchesKey(data, Key.left) || matchesKey(data, "shift+tab") || data === "h") {
				apply({ type: "tab", delta: -1 });
				return;
			}
			if (/^[1-9]$/.test(data) && !isConfirmTab(state, questions)) {
				const index = Number(data) - 1;
				if (index <= customRow(questions[state.tab])) apply({ type: "choose", index });
			}
		}

		// Returns undefined for unhandled events; the host treats undefined as unhandled.
		function handleMouse(event: TuiMouseEvent) {
			// Only scroll when the pointer is actually over the question text band.
			if (event.type === "wheel" && questionTextRegion &&
				event.y >= questionTextRegion.start && event.y <= questionTextRegion.end) {
				// Normalize to ±1 to match pi's other scroll lists (wheelDelta is direction * scrollLines).
				const delta = Math.sign(event.wheelDelta ?? 0);
				if (delta) {
					scrollQuestion(delta);
					return { handled: true };
				}
			}
			if (event.type !== "click") return;
			if (tabBar && event.y === tabBar.line) {
				const index = tabBar.ends.findIndex((end) => event.x < end);
				if (index >= 0) apply({ type: "tabTo", index });
				return { handled: true };
			}
			const action = rows.get(event.y);
			if (!action) return; // let the host handle clicks outside option rows
			apply(action);
			return { handled: true };
		}

		function render(width: number): string[] {
			if (cache?.width === width && cache.rows === tui.terminal.rows) return cache.lines;

			const lines: string[] = [];
			const renderWidth = Math.max(1, width);
			rows.clear();

			function addWrappedWithPrefix(prefix: string, text: string, action?: Action) {
				const prefixWidth = visibleWidth(prefix);
				const wrapped =
					prefixWidth >= renderWidth
						? wrapTextWithAnsi(prefix + text, renderWidth)
						: wrapTextWithAnsi(text, renderWidth - prefixWidth);
				const continuation = " ".repeat(Math.min(prefixWidth, renderWidth));
				for (let i = 0; i < wrapped.length; i++) {
					if (action) rows.set(lines.length, action);
					lines.push(prefixWidth >= renderWidth ? wrapped[i] : `${i === 0 ? prefix : continuation}${wrapped[i]}`);
				}
			}

			lines.push(theme.fg("accent", "─".repeat(renderWidth)));

			function renderTabBar() {
				if (questions.length <= 1) return;
				const headers = [...questions.map((q) => q.header), "Confirm"];
				const ends: number[] = [];
				let column = 1;
				const tabs = headers.map((header, i) => {
					column += visibleWidth(header) + 3;
					ends.push(column);
					const active = i === state.tab;
					return theme.fg(active ? "accent" : "dim", active ? `[${header}]` : ` ${header} `);
				});
				tabBar = { line: lines.length, ends };
				lines.push(` ${tabs.join(" ")}`);
				lines.push("");
			}

			function renderConfirm() {
				addWrappedWithPrefix(" ", theme.fg("text", "Review your answers:"));
				lines.push("");
				const answers = answersOf(state, questions);
				questions.forEach((q, i) => {
					const answer = answers[i].join(", ") || "Unanswered";
					addWrappedWithPrefix("  ", `${theme.fg("muted", `${q.header}: `)}${theme.fg("accent", answer)}`, {
						type: "tabTo",
						index: i,
					});
				});
			}

			function renderQuestionText() {
				const current = questions[state.tab];
				const qText = theme.fg("text", current.question);
				const qWrapped = wrapTextWithAnsi(qText, Math.max(1, renderWidth - 1)).map((l) => ` ${l}`);
				const budget = questionLineBudget();
				if (qWrapped.length <= budget) {
					questionTextRegion = undefined;
					for (const l of qWrapped) lines.push(l);
				} else {
					// Also clamp here to handle terminal resize that reduced the budget.
					questionScroll = Math.min(questionScroll, Math.max(0, qWrapped.length - budget));
					const regionStart = lines.length;
					for (const l of qWrapped.slice(questionScroll, questionScroll + budget)) lines.push(l);
					questionTextRegion = { start: regionStart, end: lines.length - 1, total: qWrapped.length };
					lines.push(theme.fg("dim", `  Lines ${questionScroll + 1}–${questionScroll + budget} of ${qWrapped.length}`));
				}
				lines.push("");
			}

			function renderOptions() {
				const current = questions[state.tab];
				const labels = [...current.options.map((o) => o.label), CUSTOM_LABEL];
				for (let i = 0; i < labels.length; i++) {
					const isCustom = i === customRow(current);
					const active = i === state.cursor;
					const chosen = state.selected[state.tab].has(i);
					const box = current.multiple && !isCustom ? (chosen ? "[✓] " : "[ ] ") : "";
					const mark = !current.multiple && chosen ? " ✓" : "";
					const prefix = active ? theme.fg("accent", "> ") : "  ";
					const color = active || chosen ? "accent" : "text";
					addWrappedWithPrefix(prefix, theme.fg(color, `${i + 1}. ${box}${labels[i]}${mark}`), {
						type: "choose",
						index: i,
					});
					const description = current.options[i]?.description;
					if (description) addWrappedWithPrefix("     ", theme.fg("muted", description));
				}
				const custom = state.custom[state.tab];
				if (custom && !state.editing) {
					lines.push("");
					addWrappedWithPrefix(" ", theme.fg("muted", `Your answer: ${custom}`));
				}
			}

			renderTabBar();
			if (isConfirmTab(state, questions)) {
				renderConfirm();
			} else {
				renderQuestionText();
				renderOptions();
			}

			if (state.editing) {
				lines.push("");
				addWrappedWithPrefix(" ", theme.fg("muted", "Your answer:"));
				for (const line of editor.render(Math.max(1, renderWidth - 2))) lines.push(` ${line}`);
			}

			if (warning) {
				lines.push("");
				addWrappedWithPrefix(" ", theme.fg("warning", warning));
			}

			lines.push("");
			addWrappedWithPrefix(" ", theme.fg("dim", hintFor(state, questions, Boolean(questionTextRegion))));
			lines.push(theme.fg("accent", "─".repeat(renderWidth)));

			cache = { width, rows: tui.terminal.rows, lines };
			return lines;
		}

		return {
			render,
			invalidate: () => {
				cache = undefined;
			},
			handleInput,
			handleMouse,
			dispose: () => {
				options.signal?.removeEventListener("abort", dismiss);
				// Images are carried in memory as base64 tokens — nothing to clean up on disk.
			},
		};
	});
}
