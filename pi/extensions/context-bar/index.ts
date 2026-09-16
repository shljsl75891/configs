/**
 * Context Bar
 *
 * Replaces pi's default footer (branch, token deltas, cache hit, cost,
 * subagent status) with a single context-window usage stat, e.g.:
 *
 *   Ctx 291k/1.0M (29.2%)
 *
 * `ctx.getContextUsage()` returns { tokens, contextWindow, percent }. After
 * compaction, tokens/percent are null until the next response — shown as
 * "?" in that case.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

function formatTokens(n: number): string {
	if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
	if (n >= 1_000) return `${Math.round(n / 1_000)}k`;
	return String(n);
}

export default function contextBar(pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setFooter((_tui, theme) => ({
			invalidate() {},
			render(width: number): string[] {
				const usage = ctx.getContextUsage?.();
				const contextWindow: number = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;

				if (!contextWindow) {
					return [theme.fg("dim", "Ctx: no model")];
				}

				const percent: number | null = usage?.percent ?? null;
				const tokens: number | null = usage?.tokens ?? null;
				const winStr = formatTokens(contextWindow);
				const tokStr = tokens !== null ? formatTokens(tokens) : "?";
				const pctStr = percent !== null ? `${Math.max(0, Math.min(100, percent)).toFixed(1)}%` : "?";

				const sev: "success" | "warning" | "error" | "dim" =
					percent === null ? "dim" : percent > 90 ? "error" : percent > 70 ? "warning" : "success";

				const text = theme.fg("dim", "Ctx ") + theme.fg(sev, `${tokStr}/${winStr}`) + theme.fg("dim", ` (${pctStr})`);

				return [truncateToWidth(text, width)];
			},
		}));
	});
}
