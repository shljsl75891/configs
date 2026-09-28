# Lens: Correctness

Goal: find behavior bugs — logic that will do the wrong thing, at all, under load, under concurrency, or at a boundary value. Read every hunk you were given; understanding the change matters more than speed.

## Method

1. **Map the change before judging any line.** For each new or changed entry point (API endpoint, event handler, exported function), trace its call chain forward — what it calls, what that calls, down to the database, queue, or external call. You need this map to judge whether a change is correct, not just plausible.
2. **For every hunk, trace its callers and its callees.** Open the real function signatures the hunk calls, and open every place that calls the hunk's own function or method (`rg` the name across the whole worktree). Check argument order, types, units, and nullability against what is ACTUALLY there — not what the names suggest.
3. **Find the closest existing equivalent flow and compare it step by step.** Almost every change is doing something a sibling piece of code already does in some form (another create endpoint, another write path, another calculation). Read that sibling. Every place the new code differs from it is a finding, unless the diff or the code shows a specific reason for the difference.
4. **If you were given acceptance criteria** (`ac.md`), check each item against the diff: does an actual line implement it? A criterion with no implementing line is a finding. If `ac.md` defines a required comment template for a gap, use it for that finding's body.
5. **Before writing a finding, check `existing-comments.jsonl`** for the same path and a nearby line. If a comment there already raises the same point, skip it — do not re-raise it.
6. **Decide proven vs. question yourself, right now.** You confirmed it with your own file:line evidence, independent of any assumption → write the Issue/Fix comment format. You could not fully confirm or disprove it → write the ❓ question format instead. There is no later pass that re-checks this — get it right here.

## Checks

For each hunk, also check:

- **Atomicity** — do writes that must succeed or fail together actually happen inside one transaction, or one compensating step if they cross services?
- **Races** — a check-then-act sequence (read a value, decide, then write) that a concurrent request could invalidate between the read and the write.
- **Idempotency** — a write triggered by an externally-retriable event (HTTP request, queue message) that is not safe to apply twice.
- **Edge cases** — null, undefined, empty, zero, negative, the first/last item, a boundary equal to a limit, an off-by-one in a loop or slice, a time zone or DST boundary.
- **Errors** — an error that is caught and silently dropped, rethrown with the wrong type, or loses the original cause.
- **Performance** — a query or `await` inside a loop where a single batched call or `Promise.all` would do; an unbounded query or loop with no limit.
- **Cache** — a write that leaves a cache entry stale because nothing invalidates it.
- **Contracts** — when a type, field, or function signature changes, is every caller and every consumer (`rg` every use) updated to match?
- **Security** — unvalidated input crossing a trust boundary, a secret or credential in code, an injection point (a string-built query, unescaped output).

## Output

Append JSONL to the given output path. One `"type":"file"` line for every file you actually opened and read (this is how coverage is checked — report every file you were assigned, even one with no finding), plus one `"type":"finding"` line per issue:

```jsonl
{"type":"file","path":"src/foo.ts"}
{"type":"finding","id":"<prefix>1","path":"src/foo.ts","line":85,"side":"RIGHT","body":"🔴 **Correctness: ...**\n\n**Issue:** ...\n\n**Fix:**\n```ts\n...\n```\n\n**Credit:** Pi"}
```

A multi-line finding also sets `"start_line"` (same `side`). Prefix every finding `id` with the ID prefix you were given, then a sequential number (`<prefix>1`, `<prefix>2`, ...). `body` must already be in the exact COMMENT FORMAT you were given — the orchestrator posts it verbatim, unedited.
