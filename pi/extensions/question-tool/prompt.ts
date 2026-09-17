import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as os from "node:os";
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
import { type Action, answersOf, createState, customRow, isConfirmTab, type QuestionSpec, reduce } from "./state.ts";

export const CUSTOM_LABEL = "Type your own answer";

type ClipboardApi = {
	readClipboardImage(): Promise<{ bytes: Uint8Array; mimeType: string } | null>;
	extensionForImageMimeType(mimeType: string): string | null;
	readClipboardText(): Promise<string | null>;
};

let clipboardApi: Promise<ClipboardApi | null> | undefined;

/** Walk up from the running CLI to the pi package root. */
export function findPiRoot(from: string = process.argv[1] ?? ""): string | null {
	let dir = path.dirname(fs.realpathSync(from));
	for (let i = 0; i < 6; i++) {
		if (fs.existsSync(path.join(dir, "dist/utils/clipboard-image.js"))) return dir;
		const parent = path.dirname(dir);
		if (parent === dir) break;
		dir = parent;
	}
	return null;
}

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
				extensionForImageMimeType: image.extensionForImageMimeType,
				readClipboardText: text.readClipboardText,
			};
		} catch {
			return null;
		}
	})();
	return clipboardApi;
}

/**
 * Renders the question UI and resolves with one list of chosen labels per
 * question, or null when dismissed. An aborted signal dismisses it too, so
 * callers distinguish the two by checking the signal afterwards.
 */
export function askQuestions(
	ui: Pick<ExtensionUIContext, "custom">,
	questions: QuestionSpec[],
	options: { signal?: AbortSignal } = {},
): Promise<string[][] | null> {
	return ui.custom<string[][] | null>((tui, theme, keybindings, done) => {
		let state = createState(questions);
		let warning: string | null = null;
		let cachedLines: string[] | undefined;
		const rows = new Map<number, Action>();
		let tabBar: { line: number; ends: number[] } | undefined;

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
			cachedLines = undefined;
			tui.requestRender();
		}

		function apply(action: Action) {
			const wasEditing = state.editing;
			state = reduce(state, action, questions);
			if (state.submitted) {
				done(answersOf(state, questions));
				return;
			}
			if (state.editing && !wasEditing) editor.setText("");
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
			const image = await clipboard.readClipboardImage();
			if (image) {
				const ext = clipboard.extensionForImageMimeType(image.mimeType) ?? "png";
				const file = path.join(os.tmpdir(), `pi-clipboard-${crypto.randomUUID()}.${ext}`);
				fs.writeFileSync(file, Buffer.from(image.bytes));
				editor.insertTextAtCursor(file);
			} else {
				const text = await clipboard.readClipboardText();
				if (text) editor.insertTextAtCursor(text);
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

		function handleMouse(event: TuiMouseEvent) {
			if (event.type !== "click") return;
			if (tabBar && event.y === tabBar.line) {
				const index = tabBar.ends.findIndex((end) => event.x < end);
				if (index >= 0) apply({ type: "tabTo", index });
				return { handled: true };
			}
			const action = rows.get(event.y);
			if (action) apply(action);
			return { handled: true };
		}

		function render(width: number): string[] {
			if (cachedLines) return cachedLines;

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

			if (questions.length > 1) {
				const headers = [...questions.map((q) => q.header), "Confirm"];
				const ends: number[] = [];
				let column = 1;
				const tabs = headers.map((header, i) => {
					column += header.length + 3;
					ends.push(column);
					const active = i === state.tab;
					return theme.fg(active ? "accent" : "dim", active ? `[${header}]` : ` ${header} `);
				});
				tabBar = { line: lines.length, ends };
				lines.push(` ${tabs.join(" ")}`);
				lines.push("");
			}

			if (isConfirmTab(state, questions)) {
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
			} else {
				const current = questions[state.tab];
				addWrappedWithPrefix(" ", theme.fg("text", current.question));
				lines.push("");

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
			const hints = state.editing
				? "Enter to submit • Ctrl+V to paste an image • Esc to go back"
				: isConfirmTab(state, questions)
					? "Enter to submit • ←→ to revisit • Esc to cancel"
					: "↑↓ navigate • 1-9 select • ←→ switch • Enter to choose • Esc to cancel";
			addWrappedWithPrefix(" ", theme.fg("dim", hints));
			lines.push(theme.fg("accent", "─".repeat(renderWidth)));

			cachedLines = lines;
			return lines;
		}

		return {
			render,
			invalidate: () => {
				cachedLines = undefined;
			},
			handleInput,
			handleMouse,
			dispose: () => options.signal?.removeEventListener("abort", dismiss),
		};
	});
}
