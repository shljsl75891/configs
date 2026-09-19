/**
 * Poll-loop that waits for a subagent result file to appear.
 * `checkWindowAlive` is injectable so this module can be unit-tested without tmux.
 */

import * as fs from "node:fs";
import { setTimeout as delay } from "node:timers/promises";
import { isSubagentResult, type SubagentResult } from "./result.ts";
import { reviewMarkerFor } from "./protocol.ts";
import { MAX_TIMEOUT_MS } from "./tasks.ts";

const POLL_INTERVAL_MS = 500;
/** Check that the window still exists every Nth poll (~2 s at 500 ms). */
const LIVENESS_CHECK_EVERY = 4;
/** Tolerate this many consecutive corrupt result-file reads before giving up. */
const MAX_CORRUPT_READS = 3;
/** Extra budget a review pause may consume beyond the caller's timeout. */
const REVIEW_GRACE_MS = MAX_TIMEOUT_MS;

type ResultRead = { ok: true; result: SubagentResult } | { ok: false; detail: string } | null;

export type WaitOutcome =
	| { kind: "result"; result: SubagentResult }
	| { kind: "timeout" }
	| { kind: "aborted" }
	| { kind: "windowGone" }
	| { kind: "corrupt"; detail: string };

export interface WaitOptions {
	windowId: string;
	resultFile: string;
	timeoutMs: number;
	signal?: AbortSignal;
	onReview?: (reviewing: boolean) => void;
	/** Injected; must return true if the window is still alive. */
	checkWindowAlive: (windowId: string) => Promise<boolean>;
	/** Poll cadence in ms; defaults to POLL_INTERVAL_MS. */
	pollIntervalMs?: number;
}

/** Parse the result file without throwing. Returns null if not written yet. */
async function readResult(resultFile: string): Promise<ResultRead> {
	let raw: string;
	try {
		raw = await fs.promises.readFile(resultFile, "utf-8");
	} catch {
		return null; // Not written yet.
	}
	try {
		const parsed = JSON.parse(raw);
		if (isSubagentResult(parsed)) return { ok: true, result: parsed };
		return { ok: false, detail: raw.slice(0, 200) };
	} catch {
		return { ok: false, detail: raw.slice(0, 200) };
	}
}

/** Poll until the result file appears, the window dies, or a limit is hit. */
export async function waitForResult(opts: WaitOptions): Promise<WaitOutcome> {
	const { windowId, resultFile, timeoutMs, signal, onReview, checkWindowAlive } = opts;
	const pollIntervalMs = opts.pollIntervalMs ?? POLL_INTERVAL_MS;
	const reviewFile = reviewMarkerFor(resultFile);
	// Headroom over the caller's own timeout, not a coincident bound — otherwise a
	// caller who requests the maximum timeout gets zero review-pause budget.
	const hardDeadline = Date.now() + timeoutMs + REVIEW_GRACE_MS;
	let deadline = Date.now() + timeoutMs;
	let corruptReads = 0;
	let tick = 0;
	let reviewing = false;

	try {
		// deadline never exceeds hardDeadline: initialized below it, clamped to it on every
		// review extension (see the Math.min below). No separate hardDeadline check needed here.
		while (Date.now() < deadline) {
			if (signal?.aborted) return { kind: "aborted" };

			// The marker means a human is looking at the result, so the clock stops
			// and restarts from full once they hand the agent more work.
			const nowReviewing = fs.existsSync(reviewFile);
			if (nowReviewing !== reviewing) {
				reviewing = nowReviewing;
				onReview?.(reviewing);
			}
			if (reviewing) deadline = Math.min(Date.now() + timeoutMs, hardDeadline);

			const read = await readResult(resultFile);
			if (read?.ok) return { kind: "result", result: read.result };
			// The write is atomic, so an invalid file is corruption, not a torn read.
			// A vanished file resets the counter; a valid read returns above.
			if (read?.ok === false) {
				if (++corruptReads >= MAX_CORRUPT_READS) return { kind: "corrupt", detail: read.detail };
			} else {
				corruptReads = 0;
			}

			// Short-circuits the most likely failure: the child died before writing.
			// Only null reads advance the cadence: corrupt reads have their own budget.
			if (!read && ++tick % LIVENESS_CHECK_EVERY === 0 && !(await checkWindowAlive(windowId))) {
				const final = await readResult(resultFile);
				if (final?.ok) return { kind: "result", result: final.result };
				return { kind: "windowGone" };
			}

			await delay(Math.min(pollIntervalMs, Math.max(0, deadline - Date.now())), undefined, { signal }).catch(() => {});
		}

		return signal?.aborted ? { kind: "aborted" } : { kind: "timeout" };
	} finally {
		// Ensure the caller always hears the "not reviewing" edge, even when a
		// result lands while the review marker is still present (a real race).
		if (reviewing) onReview?.(false);
	}
}
