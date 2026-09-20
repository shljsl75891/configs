/**
 * Replaces pi's default footer with a single line:
 *
 *   claude-sonnet-5 [high]                       291k/1.0M (29.2%) ₹12.34
 */

import { readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type {
	ContextUsage,
	ExtensionAPI,
	ExtensionContext,
	ReadonlyFooterDataProvider,
	SessionEntry,
	Theme,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
/**
 * Only the status key, not plan-mode's session-scan logic: the footer's
 * live extension-status map already mirrors plan-mode's enabled state.
 */
import { PLAN_MODE_STATUS_KEY } from "../plan-mode/index.ts";

const BOLD = "\x1b[1m";
const BOLD_OFF = "\x1b[22m";

const FX_CACHE_FILE = join(tmpdir(), "pi-context-bar-usd-inr.json");
const FX_TTL_MS = 6 * 60 * 60 * 1000;
const FX_URL = "https://open.er-api.com/v6/latest/USD";
const FX_FETCH_TIMEOUT_MS = 5_000;
// Failure-retry cooldown, separate from FX_TTL_MS — see mayRetry below.
const FX_RETRY_MS = 60_000;
// Full branch scan; render runs every keystroke, so cache briefly.
const COST_TTL_MS = 500;
const CONTEXT_PCT_WARN = 70;
const CONTEXT_PCT_ERROR = 90;

let cachedRate: number | null = null;
let cachedAt = 0;
let cacheLoaded = false;
let lastFetchAttemptAt = 0;
let fetchInFlight: Promise<void> | null = null;
/**
 * Set by the footer factory. Assumes one footer per process (true for
 * this interactive CLI), so a single slot is enough.
 */
let requestFooterRepaint: (() => void) | undefined;

function readCache(): { rate: number; timestamp: number } | undefined {
	try {
		const parsed: unknown = JSON.parse(readFileSync(FX_CACHE_FILE, "utf8"));
		if (typeof parsed !== "object" || parsed === null) return undefined;
		const { rate, timestamp } = parsed as Partial<{ rate: unknown; timestamp: unknown }>;
		return typeof rate === "number" && typeof timestamp === "number" ? { rate, timestamp } : undefined;
	} catch {
		return undefined;
	}
}

async function refreshRate(): Promise<void> {
	try {
		const res = await fetch(FX_URL, { signal: AbortSignal.timeout(FX_FETCH_TIMEOUT_MS) });
		if (!res.ok) return;
		const data: unknown = await res.json();
		const rate =
			typeof data === "object" && data !== null
				? (data as { rates?: Record<string, unknown> }).rates?.INR
				: undefined;
		if (typeof rate === "number") {
			cachedRate = rate;
			cachedAt = Date.now();
			writeFileSync(FX_CACHE_FILE, JSON.stringify({ rate, timestamp: cachedAt }));
		}
	} catch {
		// FX is cosmetic: keep last known rate, retry next TTL window.
	}
}

/**
 * Render runs on every keystroke and stream chunk; the on-disk cache is
 * only worth reading once per process, not once per frame. `refreshRate`
 * keeps `cachedRate`/`cachedAt` current in memory after that.
 */
function getUsdToInrRate(): number | null {
	if (!cacheLoaded) {
		cacheLoaded = true;
		const cache = readCache();
		if (cache) {
			cachedRate = cache.rate;
			cachedAt = cache.timestamp;
		}
	}

	const now = Date.now();
	const isFresh = cachedRate !== null && now - cachedAt < FX_TTL_MS;
	/**
	 * Without a cooldown, a failed fetch leaves the rate stale, so the
	 * very next render — and a successful fetch's own repaint request —
	 * would retry immediately, turning a network hiccup into one HTTP
	 * request per repaint for the rest of the session.
	 */
	const mayRetry = now - lastFetchAttemptAt > FX_RETRY_MS;
	if (!isFresh && !fetchInFlight && mayRetry) {
		lastFetchAttemptAt = now;
		const before = cachedRate;
		fetchInFlight = refreshRate().finally(() => {
			fetchInFlight = null;
			if (cachedRate === before) return; // nothing new to paint
			requestFooterRepaint?.();
		});
	}
	return cachedRate;
}

/**
 * Deliberately local, not the SDK's Usage/ModelCost (@earendil-works/pi-ai):
 * those aren't re-exported from pi-coding-agent's public entry. This also
 * means cacheWrite1h and tiered pricing aren't modeled — the footer cost
 * is an estimate, not a bill.
 */
interface TokenBuckets {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
}

function costFromUsage({ usage, rates }: { usage: TokenBuckets; rates: TokenBuckets }): number {
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
	entries: readonly SessionEntry[],
	modelRegistry: ExtensionContext["modelRegistry"],
	fallbackModel: ExtensionContext["model"],
): number {
	let total = 0;
	for (const entry of entries) {
		let usage: TokenBuckets | undefined;
		let rates: TokenBuckets | undefined;

		if (entry.type === "message" && entry.message.role === "assistant") {
			usage = entry.message.usage;
			const model = modelRegistry.find(entry.message.provider, entry.message.responseModel ?? entry.message.model);
			// Relay ids etc. may not be in the registry; fall back rather than drop the cost.
			rates = model?.cost ?? fallbackModel?.cost;
		} else if (entry.type === "message" && entry.message.role === "toolResult" && entry.message.usage) {
			usage = entry.message.usage;
			rates = fallbackModel?.cost;
		} else if (entry.type === "usage") {
			// Out-of-band usage (eg. cache warming), not tied to a rendered message.
			usage = entry.usage;
			rates = modelRegistry.find(entry.provider, entry.model)?.cost ?? fallbackModel?.cost;
		} else if ((entry.type === "branch_summary" || entry.type === "compaction") && entry.usage) {
			usage = entry.usage;
			rates = fallbackModel?.cost;
		}

		if (usage && rates) total += costFromUsage({ usage, rates });
	}
	return total;
}

function formatTokens(n: number): string {
	if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
	if (n >= 1_000) return `${Math.round(n / 1_000)}k`;
	return String(n);
}

/**
 * Plan-mode's setStatus(key, undefined) deletes the map entry when
 * disabled, so map membership below is an exact, cheap mirror of its state.
 */
function renderLeft(ctx: ExtensionContext, theme: Theme, footerData: ReadonlyFooterDataProvider): string {
	const model = ctx.model;
	const statuses = footerData.getExtensionStatuses();
	const planActive = statuses.has(PLAN_MODE_STATUS_KEY);
	const modeLabel = planActive ? "Plan" : "Build";
	// Skip plan-mode's own "[plan]" badge; we already render Plan/Build above.
	const statusSuffix = [...statuses]
		.filter(([key]) => key !== PLAN_MODE_STATUS_KEY)
		.map(([, text]) => text)
		.join("  ");

	let left = "";
	if (model) {
		const modeColor = planActive ? "success" : "customMessageLabel";
		left += theme.fg(modeColor, modeLabel);
		left += theme.fg("text", `  ${model.name ?? model.id}`);
		left += theme.fg("dim", `  ${model.provider}`);
		if (ctx.thinkingLevel) {
			left += `  ${BOLD}${theme.fg("warning", ctx.thinkingLevel)}${BOLD_OFF}`;
		}
	}
	if (statusSuffix) left += (left ? "  " : "") + statusSuffix;
	return left;
}

/** Context-window usage plus the (optional) INR cost estimate. */
function renderRight({
	theme,
	usage,
	contextWindow,
	rate,
	costUsd,
}: {
	theme: Theme;
	usage: ContextUsage | undefined;
	contextWindow: number;
	rate: number | null;
	costUsd: number;
}): string {
	const percent = usage?.percent ?? null;
	const tokens = usage?.tokens ?? null;
	const winStr = formatTokens(contextWindow);
	const tokStr = tokens !== null ? formatTokens(tokens) : "?";
	const pctStr = percent !== null ? `${Math.max(0, Math.min(100, percent)).toFixed(1)}%` : "?";

	const sev: "success" | "warning" | "error" | "dim" =
		percent === null ? "dim" : percent > CONTEXT_PCT_ERROR ? "error" : percent > CONTEXT_PCT_WARN ? "warning" : "success";

	const costStr = rate !== null ? ` ₹${(costUsd * rate).toFixed(2)}` : "";

	return (
		theme.fg(sev, `${tokStr}/${winStr}`) + theme.fg("dim", ` (${pctStr})`) + (costStr ? theme.fg("dim", costStr) : "")
	);
}

export default function contextBar(pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		let costCache = { at: 0, usd: 0 };
		function sessionCostUsd(): number {
			const now = Date.now();
			if (now - costCache.at > COST_TTL_MS) {
				costCache = { at: now, usd: estimateSessionCostUsd(ctx.sessionManager.getBranch(), ctx.modelRegistry, ctx.model) };
			}
			return costCache.usd;
		}

		ctx.ui.setFooter((tui, theme, footerData) => {
			requestFooterRepaint = () => tui.requestRender();
			return {
				invalidate() {},
				dispose() {
					requestFooterRepaint = undefined;
				},
				render(width: number): string[] {
					const left = renderLeft(ctx, theme, footerData);

					const usage = ctx.getContextUsage?.();
					const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
					if (!contextWindow) {
						const line = left + theme.fg("dim", left ? " no model" : "no model");
						return [truncateToWidth(line, width)];
					}

					const right = renderRight({ theme, usage, contextWindow, rate: getUsdToInrRate(), costUsd: sessionCostUsd() });
					const gap = Math.max(1, width - visibleWidth(left) - visibleWidth(right));
					const line = left + " ".repeat(gap) + right;

					return [truncateToWidth(line, width)];
				},
			};
		});
	});
}
