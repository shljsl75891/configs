/**
 * Context Bar
 *
 * Replaces pi's default footer (branch, token deltas, cache hit, cost,
 * subagent status) with a single status line:
 *
 *   claude-sonnet-5 [high]                       Ctx 291k/1.0M (29.2%) ₹12.34
 *
 * Model name (+ thinking/effort level, when set) left-aligned, context-window
 * usage + session cost (converted to INR) right-aligned.
 *
 * `ctx.getContextUsage()` returns { tokens, contextWindow, percent }. After
 * compaction, tokens/percent are null until the next response — shown as
 * "?" in that case.
 *
 * USD→INR rate is fetched periodically and cached to disk; the last known
 * rate is reused if a fetch fails or hasn't happened yet.
 */

import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, SessionEntry } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const FX_CACHE_FILE = join(tmpdir(), "pi-context-bar-usd-inr.json");
const FX_TTL_MS = 6 * 60 * 60 * 1000;
const FX_URL = "https://open.er-api.com/v6/latest/USD";

let cachedRate: number | null = null;
let fetchInFlight: Promise<void> | null = null;

function readCache(): { rate: number; timestamp: number } | undefined {
	try {
		if (!existsSync(FX_CACHE_FILE)) return undefined;
		const parsed = JSON.parse(readFileSync(FX_CACHE_FILE, "utf8"));
		return typeof parsed?.rate === "number" && typeof parsed?.timestamp === "number" ? parsed : undefined;
	} catch {
		return undefined;
	}
}

async function refreshRate(): Promise<void> {
	try {
		const res = await fetch(FX_URL);
		const data = (await res.json()) as { rates?: Record<string, number> };
		const rate = data?.rates?.INR;
		if (typeof rate === "number") {
			cachedRate = rate;
			writeFileSync(FX_CACHE_FILE, JSON.stringify({ rate, timestamp: Date.now() }));
		}
	} catch {
		// keep last-known rate on failure
	}
}

function getUsdToInrRate(): number | null {
	const cache = readCache();
	if (cachedRate === null && cache) cachedRate = cache.rate;

	const isFresh = cache !== undefined && Date.now() - cache.timestamp < FX_TTL_MS;
	if (!isFresh && !fetchInFlight) {
		fetchInFlight = refreshRate().finally(() => {
			fetchInFlight = null;
		});
	}
	return cachedRate;
}

function sumSessionCostUsd(entries: SessionEntry[]): number {
	let total = 0;
	for (const entry of entries) {
		const usage =
			entry.type === "message" && (entry.message.role === "assistant" || entry.message.role === "toolResult")
				? entry.message.usage
				: entry.type === "branch_summary" || entry.type === "compaction"
					? entry.usage
					: undefined;
		if (usage?.cost?.total) total += usage.cost.total;
	}
	return total;
}

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
				const modelName = ctx.model?.name ?? ctx.model?.id ?? "no model";
				const leftPlain = ctx.thinkingLevel ? `${modelName} [${ctx.thinkingLevel}]` : modelName;
				const left = ctx.thinkingLevel
					? theme.fg("dim", modelName) + theme.fg("dim", ` [${ctx.thinkingLevel}]`)
					: theme.fg("dim", modelName);

				const usage = ctx.getContextUsage?.();
				const contextWindow: number = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;

				if (!contextWindow) {
					const line = left + theme.fg("dim", "  Ctx: no model");
					return [truncateToWidth(line, width)];
				}

				const percent: number | null = usage?.percent ?? null;
				const tokens: number | null = usage?.tokens ?? null;
				const winStr = formatTokens(contextWindow);
				const tokStr = tokens !== null ? formatTokens(tokens) : "?";
				const pctStr = percent !== null ? `${Math.max(0, Math.min(100, percent)).toFixed(1)}%` : "?";

				const sev: "success" | "warning" | "error" | "dim" =
					percent === null ? "dim" : percent > 90 ? "error" : percent > 70 ? "warning" : "success";

				const rate = getUsdToInrRate();
				const costUsd = sumSessionCostUsd(ctx.sessionManager.getEntries());
				const costStr = rate !== null ? ` ₹${(costUsd * rate).toFixed(2)}` : "";

				const rightPlain = `Ctx ${tokStr}/${winStr} (${pctStr})${costStr}`;
				const right =
					theme.fg("dim", "Ctx ") +
					theme.fg(sev, `${tokStr}/${winStr}`) +
					theme.fg("dim", ` (${pctStr})`) +
					(costStr ? theme.fg("dim", costStr) : "");

				const gap = Math.max(1, width - visibleWidth(leftPlain) - visibleWidth(rightPlain));
				const line = left + " ".repeat(gap) + right;

				return [truncateToWidth(line, width)];
			},
		}));
	});
}
