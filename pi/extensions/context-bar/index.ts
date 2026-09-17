/**
 * Replaces pi's default footer with a single line:
 *
 *   claude-sonnet-5 [high]                       291k/1.0M (29.2%) ₹12.34
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

interface CostRates {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
}

interface UsageTokens {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
}

function costFromUsage(usage: UsageTokens, rates: CostRates): number {
	return (
		(usage.input / 1_000_000) * rates.input +
		(usage.output / 1_000_000) * rates.output +
		(usage.cacheRead / 1_000_000) * rates.cacheRead +
		(usage.cacheWrite / 1_000_000) * rates.cacheWrite
	);
}

/**
 * Static per-model pricing, not `usage.cost.total`, which the relay reports as $0
 * under flat-rate billing. Entries carrying no model fall back to the current one.
 */
function estimateSessionCostUsd(
	entries: SessionEntry[],
	modelRegistry: { find(provider: string, modelId: string): { cost?: CostRates } | undefined },
	fallbackModel: { cost?: CostRates } | undefined,
): number {
	let total = 0;
	for (const entry of entries) {
		let usage: UsageTokens | undefined;
		let rates: CostRates | undefined;

		if (entry.type === "message" && entry.message.role === "assistant") {
			usage = entry.message.usage;
			const model = modelRegistry.find(entry.message.provider, entry.message.responseModel ?? entry.message.model);
			rates = model?.cost;
		} else if (entry.type === "message" && entry.message.role === "toolResult" && entry.message.usage) {
			usage = entry.message.usage;
			rates = fallbackModel?.cost;
		} else if ((entry.type === "branch_summary" || entry.type === "compaction") && entry.usage) {
			usage = entry.usage;
			rates = fallbackModel?.cost;
		}

		if (usage && rates) total += costFromUsage(usage, rates);
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
		ctx.ui.setFooter((_tui, theme, footerData) => ({
			invalidate() {},
			render(width: number): string[] {
				const modelName = ctx.model?.name ?? ctx.model?.id ?? "no model";
				// Custom footers replace the built-in one entirely, so this is the only
				// place ctx.ui.setStatus() from other extensions still gets shown.
				const statuses = [...footerData.getExtensionStatuses().entries()].sort(([a], [b]) => a.localeCompare(b));
				const statusSuffix = statuses.length > 0 ? `  ${statuses.map(([, text]) => text).join("  ")}` : "";
				const left =
					(ctx.thinkingLevel
						? theme.fg("text", modelName) + theme.fg("dim", ` [${ctx.thinkingLevel}]`)
						: theme.fg("text", modelName)) + statusSuffix;

				const usage = ctx.getContextUsage?.();
				const contextWindow: number = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;

				if (!contextWindow) {
					const line = left + theme.fg("dim", " no model");
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
				const costUsd = estimateSessionCostUsd(ctx.sessionManager.getEntries(), ctx.modelRegistry, ctx.model);
				const costStr = rate !== null ? ` ₹${(costUsd * rate).toFixed(2)}` : "";

				const rightPlain = `${tokStr}/${winStr} (${pctStr})${costStr}`;
				const right =
					theme.fg(sev, `${tokStr}/${winStr}`) +
					theme.fg("dim", ` (${pctStr})`) +
					(costStr ? theme.fg("dim", costStr) : "");

				const gap = Math.max(1, width - visibleWidth(left) - visibleWidth(rightPlain));
				const line = left + " ".repeat(gap) + right;

				return [truncateToWidth(line, width)];
			},
		}));
	});
}
