# Lens: Reliability and Silent Failure

Goal: find code that fails without anyone knowing, hangs, leaks, or amplifies an outage. A bug nobody sees costs the most.

## Method

1. **For every hunk, ask "what happens when this call fails, is slow, returns nothing, or runs twice?"** Open the callee and the callers (`rg` across the worktree).
2. **For every `catch`, `.catch`, `?.`, `??`, `||` default, and fallback in the hunks**, decide whether it hides a real failure.
3. **Find the closest existing flow** (another consumer, another external call) and compare its timeout, retry, cleanup, and logging. Each difference is a finding.
4. **Check `existing-comments.jsonl`** for the same path and nearby line; skip if already raised.
5. **Proven vs. question**: you traced the failure path with `path:line` evidence → Issue/Fix. You cannot confirm the failure can occur → ❓.

## Checks

- **Swallowed errors** — empty `catch`; `catch` that only logs then continues; catch-all that hides unrelated error types; error converted to `null`/`undefined`/`[]`/`false`/default; `?.` or `??` that silently skips a failing operation; original `cause` lost on rethrow; error message with no operation, id, or next step.
- **Fail-open** — on error the code allows, skips validation, or uses a mock/stub/fallback value outside tests.
- **Promises** — floating promise (no `await`/`.catch`/`void`); `arr.forEach(async …)`; promise used in `if`; `return promise` inside `try` without `await` (catch never runs); `Promise.all` where one rejection orphans the rest; unhandled rejection in event handlers/timers.
- **Timeouts** — HTTP/DB/RPC/queue call with no timeout (`fetch` has none; use `AbortSignal.timeout`); callee timeout larger than the caller's.
- **Retries** — retry of a non-idempotent call; no cap, no backoff/jitter; retries stacked across layers; retries that exhaust silently.
- **Queues / events** — ack before work completes; no poison-message cap or DLQ; handler not safe to run twice; ordering assumed; DB write plus event publish as two steps with no outbox/transaction.
- **Cleanup / leaks** — connection, transaction, file handle, stream, timer, listener, lock opened without `finally`/`using`; transaction not rolled back on error; unbounded `Map`/cache/array growth; event listeners added per call.
- **Backpressure / event loop** — unbounded `Promise.all` over input; unbounded in-memory queue; `*Sync` fs, big `JSON.parse/stringify`, CPU-heavy loop on a request path.
- **Process lifecycle** — no graceful shutdown for SIGTERM; swallowed `uncaughtException`; startup failing open on missing config.
- **Observability** — failure path with no log/metric/alert; log without the identifier needed to debug; background job failing with no notification.
- **Time-bounded damage** — a destructive or bulk operation (delete, update-many, migration, script) with no dry-run, limit, confirmation, or environment guard.
- **Angular / RxJS** — `subscribe` with no unsubscribe/`takeUntilDestroyed`/`async` pipe; nested `subscribe`; missing error handler on a stream that then dies; `catchError` returning `EMPTY` silently; `shareReplay` without `refCount`; `switchMap` vs `mergeMap`/`concatMap` choice that drops or duplicates requests; `effect` writing a signal it reads.

## Output

Same JSONL contract as `correctness.md`. Name the failing call and the swallowing line with `path:line` in the Issue text.
