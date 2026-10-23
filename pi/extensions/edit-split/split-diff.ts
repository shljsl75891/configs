/**
 * Side-by-side diff component, built from the display diff string of pi's edit tool.
 * Line format (pi edit-diff.ts): "+12 text", "-12 text", " 12 text", and "     ..." for a skipped block.
 */
import { visibleWidth } from "@earendil-works/pi-tui";

export type Side = { num: string; text: string } | undefined;
export type Row = { kind: "context" | "change"; left: Side; right: Side } | { kind: "skip" };
export type Span = [start: number, end: number];

/** Theme methods the view needs. Method syntax keeps pi's narrower color-name types assignable. */
export interface DiffTheme {
	fg(color: string, text: string): string;
	getFgAnsi(color: string): string;
}

type Rgb = [number, number, number];
type Style = { color: string; sign: string; lineBg: string; wordBg: string };

export const MIN_SPLIT_WIDTH = 100;
const DEFAULT_BASE_BG: Rgb = [0x1d, 0x20, 0x21];
const LINE_TINT = 0.18;
const WORD_TINT = 0.4;
const TAB = "   "; // Same as replaceTabs in pi's diff renderer.
const LINE_RE = /^([+\- ])(\s*\d+) (.*)$/s;
const SKIP_RE = /^\s*\.\.\.$/;
const SEGMENTER = new Intl.Segmenter();
const NON_ASCII = /[^\x00-\x7f]/;

export function parseRows(diff: string): Row[] {
	const rows: Row[] = [];
	const lines = diff.split("\n");
	let i = 0;
	let offset = 0; // New line number minus old line number. Context rows need it for the right side.
	while (i < lines.length) {
		const m = LINE_RE.exec(lines[i]);
		if (!m) {
			if (SKIP_RE.test(lines[i])) rows.push({ kind: "skip" });
			i++;
			continue;
		}
		if (m[1] === " ") {
			const num = m[2].trim();
			rows.push({ kind: "context", left: { num, text: m[3] }, right: { num: String(Number(num) + offset), text: m[3] } });
			i++;
			continue;
		}
		const removed: Side[] = [];
		const added: Side[] = [];
		for (let p = LINE_RE.exec(lines[i] ?? ""); p?.[1] === "-"; p = LINE_RE.exec(lines[++i] ?? "")) {
			removed.push({ num: p[2].trim(), text: p[3] });
		}
		for (let p = LINE_RE.exec(lines[i] ?? ""); p?.[1] === "+"; p = LINE_RE.exec(lines[++i] ?? "")) {
			added.push({ num: p[2].trim(), text: p[3] });
		}
		offset += added.length - removed.length;
		for (let k = 0; k < Math.max(removed.length, added.length); k++) {
			rows.push({ kind: "change", left: removed[k], right: added[k] });
		}
	}
	return rows;
}

/** Changed span of each text, from the common prefix and suffix. Edges sit on whole characters. */
export function changedSpans(oldText: string, newText: string): [old: Span, next: Span] {
	let prefix = 0;
	while (prefix < oldText.length && prefix < newText.length && oldText[prefix] === newText[prefix]) prefix++;
	let suffix = 0;
	const max = Math.min(oldText.length, newText.length) - prefix;
	while (suffix < max && oldText[oldText.length - 1 - suffix] === newText[newText.length - 1 - suffix]) suffix++;
	const span = (text: string): Span => [snap(text, prefix, "down"), snap(text, text.length - suffix, "up")];
	return [span(oldText), span(newText)];
}

/** Move index to the nearest character boundary: down (earlier) or up (later). */
function snap(text: string, index: number, direction: "down" | "up"): number {
	if (index <= 0 || index >= text.length || !NON_ASCII.test(text)) return index;
	let previous = 0;
	for (const { index: boundary } of SEGMENTER.segment(text)) {
		if (boundary === index) return index;
		if (boundary > index) return direction === "down" ? previous : boundary;
		previous = boundary;
	}
	return direction === "down" ? previous : text.length;
}

/** Read the "r;g;b" of a truecolor SGR code. The plane is 38 for text and 48 for background. */
function rgbOf(ansi: string, plane: 38 | 48): Rgb | undefined {
	const m = new RegExp(`${plane};2;(\\d+);(\\d+);(\\d+)`).exec(ansi);
	return m ? [Number(m[1]), Number(m[2]), Number(m[3])] : undefined;
}

function tintedBg(color: Rgb | undefined, base: Rgb, amount: number): string {
	if (!color) return "";
	const [r, g, b] = color.map((c, i) => Math.round(base[i] + (c - base[i]) * amount));
	return `\x1b[48;2;${r};${g};${b}m`;
}

type Chunk = { text: string; offset: number; width: number };

/** Split plain text into pieces of at most `max` columns. Cuts fall between characters. One pass. */
export function chunks(text: string, max: number): Chunk[] {
	const total = visibleWidth(text);
	if (max <= 0 || total <= max) return [{ text, offset: 0, width: total }];
	const out: Chunk[] = [];
	let start = 0;
	let width = 0;
	for (const { segment, index } of SEGMENTER.segment(text)) {
		const w = visibleWidth(segment);
		if (width + w > max && index > start) {
			out.push({ text: text.slice(start, index), offset: start, width });
			start = index;
			width = 0;
		}
		width += w;
	}
	out.push({ text: text.slice(start), offset: start, width });
	return out;
}

function highlight(text: string, [rawStart, end]: Span, wordBg: string, lineBg: string): string {
	const start = Math.max(0, rawStart);
	const stop = Math.min(end, text.length);
	if (start >= stop) return text;
	return text.slice(0, start) + wordBg + text.slice(start, stop) + lineBg + text.slice(stop);
}

export interface SplitDiffOptions {
	diff: string;
	theme: DiffTheme;
	/** Draws the diff when the terminal is narrower than `minWidth`. */
	fallback: { render(width: number): string[] };
	/** ANSI background of the enclosing box. Each cell ends with it, because a reset would remove it. */
	baseBg: string;
	minWidth?: number;
}

export class SplitDiff {
	private readonly rows: Row[];
	private readonly numWidth: number;
	private readonly gutterWidth: number;
	private readonly theme: DiffTheme;
	private readonly fallback: SplitDiffOptions["fallback"];
	private readonly baseBg: string;
	private readonly minWidth: number;
	private cachedWidth: number | undefined;
	private cachedLines: string[] | undefined;

	constructor({ diff, theme, fallback, baseBg, minWidth = MIN_SPLIT_WIDTH }: SplitDiffOptions) {
		this.theme = theme;
		this.fallback = fallback;
		this.baseBg = baseBg;
		this.minWidth = minWidth;
		this.rows = parseRows(diff.replace(/\t/g, TAB));
		this.numWidth = this.rows.reduce(
			(max, row) => (row.kind === "skip" ? max : Math.max(max, row.left?.num.length ?? 0, row.right?.num.length ?? 0)),
			1,
		);
		this.gutterWidth = this.numWidth + 3; // Number, space, sign, space.
	}

	invalidate(): void {
		this.cachedWidth = undefined;
		this.cachedLines = undefined;
	}

	// The TUI calls render() on every frame, scrolling included. Cache per width, like pi-tui Text.
	render(width: number): string[] {
		if (width < this.minWidth) return this.fallback.render(width);
		if (this.cachedLines && this.cachedWidth === width) return this.cachedLines;
		this.cachedWidth = width;
		this.cachedLines = this.build(width);
		return this.cachedLines;
	}

	private build(width: number): string[] {
		const leftWidth = Math.floor((width - 1) / 2);
		const rightWidth = width - 1 - leftWidth;
		const base = rgbOf(this.baseBg, 48) ?? DEFAULT_BASE_BG;
		const style = (color: string, sign: string): Style => {
			const rgb = rgbOf(this.theme.getFgAnsi(color), 38);
			return { color, sign, lineBg: tintedBg(rgb, base, LINE_TINT), wordBg: tintedBg(rgb, base, WORD_TINT) };
		};
		const styles = {
			removed: style("toolDiffRemoved", "-"),
			added: style("toolDiffAdded", "+"),
			context: { color: "toolDiffContext", sign: " ", lineBg: "", wordBg: "" },
		};
		const divider = this.theme.fg("borderMuted", "│");
		const blank = (w: number) => " ".repeat(w);
		const { gutterWidth } = this;

		return this.rows.flatMap((row) => {
			if (row.kind === "skip") {
				const dots = (w: number) => this.theme.fg("dim", " ".repeat(this.numWidth) + "  ⋯") + blank(w - gutterWidth) + this.baseBg;
				return [dots(leftWidth) + divider + dots(rightWidth)];
			}
			const changed = row.kind === "change";
			const spans = changed && row.left && row.right ? changedSpans(row.left.text, row.right.text) : undefined;
			const left = this.cell(row.left, changed ? styles.removed : styles.context, leftWidth, spans?.[0]);
			const right = this.cell(row.right, changed ? styles.added : styles.context, rightWidth, spans?.[1]);
			// A wrapped side can be taller than the other. Fill the shorter side with blank cells.
			const height = Math.max(left.length, right.length);
			return Array.from({ length: height }, (_, i) => (left[i] ?? blank(leftWidth)) + divider + (right[i] ?? blank(rightWidth)));
		});
	}

	/** One logical line as one or more rows, wrapped to the column width. */
	private cell(side: Side, style: Style, width: number, span?: Span): string[] {
		if (!side) return [" ".repeat(width)];
		const { color, sign, lineBg, wordBg } = style;
		const { gutterWidth } = this;
		const gutter = this.theme.fg(sign === " " ? "dim" : color, `${side.num.padStart(this.numWidth)} ${sign} `);
		return chunks(side.text, Math.max(1, width - gutterWidth)).map((chunk, i) => {
			const local: Span | undefined = span && [span[0] - chunk.offset, span[1] - chunk.offset];
			const body = local && wordBg ? highlight(chunk.text, local, wordBg, lineBg) : chunk.text;
			const lead = i === 0 ? gutter : " ".repeat(gutterWidth);
			const fill = " ".repeat(Math.max(0, width - gutterWidth - chunk.width));
			return lineBg + lead + lineBg + this.theme.fg(color, body) + lineBg + fill + this.baseBg;
		});
	}
}
