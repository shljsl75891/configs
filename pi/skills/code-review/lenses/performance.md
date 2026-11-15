# Lens: Performance

Goal: find avoidable cost. Measure or reason from the code; do not guess micro-gains.

## Method

1. Find hot paths the hunks touch: loops, request handlers, render cycles, queries, startup.
2. Estimate the cost growth (per item, per request, per render). Cite `path:line`.
3. Check `existing-comments.jsonl`; skip a finding already raised.
4. Proven (clear cost growth you can state) → Issue/Fix with the expected gain. Unclear → ❓ and ask for a measurement.

## Checks

- **Recompute** — same value computed in a loop or render; move out or memoize.
- **Iteration** — repeated passes over one collection; wrong data structure (array `find` in a loop where a `Map` fits).
- **N+1** — a query or call per item in a loop.
- **Async** — sequential `await` that can use `Promise.all`; missing timeout or cancellation (`Promise.race` does not cancel the losing work; use `AbortSignal.timeout`); unbounded parallelism.
- **Leaks** — missing cleanup of subscriptions, listeners, timers, effects, streams; growing caches.
- **Payload** — fetching or returning more data than used; no pagination; large bundle import where a small one fits.
- **Frontend** — change detection or re-render storms, missing `track`/`trackBy`/keys, layout thrash.
- **Constraints** — any performance limit in `SPEC.md` that the change breaks.

## Output

JSONL exactly as the "Output format" in your task says. State the gain with each fix.
