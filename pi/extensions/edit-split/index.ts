import type { ExtensionAPI, ToolRenderers } from "@earendil-works/pi-coding-agent";
import { Box, Text } from "@earendil-works/pi-tui";
import { SplitDiff, type DiffTheme } from "./split-diff.ts";

/**
 * Side-by-side diff for the built-in edit tool.
 * pi builds the edit box (header, spacer, diff Text) again in both renderCall and renderResult.
 * So the swap runs after both: it replaces the diff Text with a SplitDiff.
 * Pi's own Text stays as the fallback for narrow terminals.
 * If the box has another shape, nothing changes and pi shows its own diff.
 */

type EditPreview = { diff: string } | { error: string };
type ThemeWithBg = DiffTheme & { getBgAnsi(color: "toolSuccessBg"): string };

function swapDiff(box: unknown, theme: ThemeWithBg): void {
	if (!(box instanceof Box)) return;
	const preview = (box as Box & { preview?: EditPreview }).preview;
	if (!preview || !("diff" in preview)) return;
	const index = box.children.findLastIndex((child) => child instanceof Text || child instanceof SplitDiff);
	const body = box.children[index];
	// A SplitDiff stays valid: pi sets a new preview and builds the box again together.
	if (!(body instanceof Text)) return;
	// pi gives the box toolSuccessBg whenever a diff preview exists (getEditHeaderBg in renderers/edit.js).
	const baseBg = theme.getBgAnsi("toolSuccessBg");
	box.children[index] = new SplitDiff({ diff: preview.diff, theme, fallback: body, baseBg });
}

export default function (pi: ExtensionAPI) {
	pi.registerToolRenderer((toolName, next) => {
		const builtin = next();
		if (toolName !== "edit" || !builtin?.renderCall || !builtin.renderResult) return builtin;
		const { renderCall, renderResult } = builtin;
		const renderers: ToolRenderers = {
			...builtin,
			renderCall(args, theme, context) {
				const component = renderCall(args, theme, context);
				swapDiff(component, theme);
				return component;
			},
			renderResult(result, options, theme, context) {
				const component = renderResult(result, options, theme, context);
				swapDiff(context.state?.callComponent, theme);
				return component;
			},
		};
		return renderers;
	});
}
