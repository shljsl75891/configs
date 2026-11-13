---
name: pr-reviewer
description: Load for any GitHub PR review. Gives steps to post inline pending-review comments with gh api, verify findings, and rate severity.
---

# PR Reviewer — Generic Mechanics

Reusable workflow for AI-driven GitHub PR reviews that end in a PENDING review the human submits manually. Works on any TypeScript/JavaScript repo. Runs the same full review every time it is invoked — idempotent by design. If a caller wants a narrower re-review (e.g. only the commits pushed since a prior review), that is the caller's instruction to give explicitly; this skill does not try to detect or guess prior-review state on its own.

## POLICY

Flag every issue you find. No count cap. No confidence score. No filter for "nitpick" or "style".

**Drop a candidate finding only when you can prove it wrong:**

- the line is not inside a diff hunk;
- the same case is already handled elsewhere — cite `path:line`;
- an existing PR comment already raises it — cite the comment URL;
- a lint/type-check rule that actually runs in this repo's CI already catches it — cite the config `path:line`.

Everything else goes to triage (Step 7). Only the human drops a finding there; the agent only recommends. A finding you cannot fully prove stays, as a ❓ question — never silence it. Each lens makes the proven-vs-question call itself when it writes the finding; Step 7 re-checks it and the human decides.

A pre-existing bug on a line inside a diff hunk still posts, as a ❓ question. A bug repeated at N sites gets a comment at each site — do not collapse them into one summary comment. Generated and lock files (`package-lock.json`, generated OpenAPI specs, snapshots) are reviewed like any other changed file.

No pass reads the PR title, the PR description, or runs `gh pr view --json body`. Author framing measurably lowers defect detection in LLM reviewers — findings must come from the code and the diff only. A ticket/acceptance-criteria pass may read the ticket if the caller supplies one (Step 3).

## CRITICAL RULES

1. **ALWAYS use `side`**: `RIGHT` for additions/context, `LEFT` for deletions. Never the deprecated `position` param.
2. **Lines MUST be inside a diff hunk** — computed once in `prepare.sh`, checked again in `post.sh`.
3. **Bulk-create payload**: exactly 2 keys — `commit_id` + `comments` (each: `path`, `line`, `side`, `body`; a multi-line comment adds `start_line` + `start_side` TOGETHER — never one without the other).
4. **NO `body`/`event` in the bulk-create payload** — omitting `event` keeps the review PENDING. A pending review's `body` is also silently dropped by the GitHub web UI if the human finishes the review without retyping it — never rely on it.
5. **API version**: every `gh api` call sets `-H "X-GitHub-Api-Version: 2022-11-28"` — this is the only version GitHub currently supports.
6. **One pending review per user per PR.** If one already exists at the CURRENT head commit, append to it — do not delete it; it may hold the human's own draft comments. If it exists at a DIFFERENT commit, stop and tell the user.
7. Verify `state === "PENDING"` in the response before reporting success.
8. **`scripts/prepare.sh` and `scripts/post.sh` must run from inside a clone whose `origin` remote is the PR's own repo** — they resolve the repo from cwd via `gh repo view`, not from an argument. `cd` into that clone (or worktree) first.

## WORKFLOW

### 1. Preconditions

Stop immediately, before any write, if the session is in plan mode — this skill needs a worktree, a diff, and JSONL output files, none of which plan mode allows. Confirm cwd is inside a clone of the PR's repo (Critical Rule 8).

### 2. Setup

Run this skill's `scripts/prepare.sh <PR_NUM>`, resolved relative to this skill's own directory (e.g. `bash /path/to/this/skill/scripts/prepare.sh 2720`). It fetches the base and head refs, builds or reuses a detached worktree at `$STATE_DIR/src`, diffs from the merge-base, and writes into `$STATE_DIR` (printed by the script, deterministically `${XDG_CACHE_HOME:-~/.cache}/pr-review/<owner>-<repo>-<PR_NUM>`):

- `hunks.tsv` — `path, side, start, end` (1-indexed, inclusive). This is the valid-line table `post.sh` checks against.
- `files.txt` — every changed file.
- `file-groups.tsv`, `files-$g.txt`, `hunks-$g.tsv` — one group (`G1`) unless the PR touches more than 100 files, in which case 2 file-disjoint groups balanced by changed-line volume.
- `existing-comments.jsonl` — the PR's current review comments, for dedup.

It warns (does not stop) if the local file count disagrees with GitHub's; check the warning before trusting line numbers. Re-running at the same head commit reuses the worktree as-is — this is what makes the skill idempotent and resumable, and it also repairs a worktree that lost its `.git` metadata.

### 3. Context

If the invoking command supplied project conventions ("house rules"), acceptance criteria, or ticket decisions, write them verbatim to `$STATE_DIR/house-rules.md`, `$STATE_DIR/ac.md` and `$STATE_DIR/ticket-decisions.md` — you already have this content in context from reading the invoking prompt; copy it, do not paraphrase it. Ticket decisions are clarifications agreed on the ticket (for example in its comments); all lenses read them. Skip any file if the caller gave nothing; the lenses run fine without them.

In codemode, load state JSON with `tools.bash` (`cat` or `jq`), not `tools.read`. `tools.read` cuts output at 50KB, so `JSON.parse` fails on a large file.

### 4. Lens runs

Read each lens file, relative to this skill's own directory: `lenses/correctness.md`, `conformance.md`, `necessity.md`, `security.md`, `reliability.md`, `tests.md`. For each group `$g`, spawn 6 tasks as parallel `subagent` calls (`agent: code-reviewer`, `timeoutMs: 3600000` — the tool's max), all in one call (the tool's limit is 8), one per lens. Substitute real values for every `$VAR` below before sending the task — it becomes the subagent's task string verbatim, and a subagent starts a brand-new process with no access to your shell variables. Each task:

```
MODE: PR_LENS_REVIEW
Worktree: $STATE_DIR/src (read files here for full context; never modify anything in it)
Files assigned to you: $STATE_DIR/files-$g.txt
Hunks (path\tside\tstart\tend — valid lines for a finding): $STATE_DIR/hunks-$g.tsv
Existing PR comments (do not re-raise these): $STATE_DIR/existing-comments.jsonl
House rules (if present): $STATE_DIR/house-rules.md
Ticket decisions (if present; never propose a fix that contradicts one): $STATE_DIR/ticket-decisions.md
Acceptance criteria (if present, correctness lens only): $STATE_DIR/ac.md
ID prefix for findings: $g-<lens>-
Output: append JSONL to $STATE_DIR/out/$g-<lens>.jsonl

Output format (exact; a line without "type" is lost): one `"type":"file"` line for every file you opened and read (coverage is checked from these; report every assigned file, even one with no finding), plus one `"type":"finding"` line per issue:
{"type":"file","path":"src/foo.ts"}
{"type":"finding","id":"$g-<lens>-1","path":"src/foo.ts","line":85,"side":"RIGHT","body":"🔴 **Correctness: ...**\n\n**Issue:** ...\n\n**Fix:** ...\n\n**Credit:** Pi"}
A multi-line finding also sets "start_line" (same side). Number ids in sequence after the prefix. `body` must already be in the exact comment format below; it is posted verbatim.

RECALL MANDATE: Assume this diff contains bugs. The human triages every finding before posting, so a missed bug costs more than a noisy comment. List EVERY finding; do not stop at the first. Apply no confidence, nit, style, or "will the author agree" filter. Read outside the diff freely (callers, callees, siblings, config, tests). Flag pre-existing issues on diff lines as ❓. A high-impact issue you cannot prove is a ❓, never dropped. Do not read the PR title or description.

Follow this method:
<paste the full content of lenses/<lens>.md here>

Comment format (write the finding's "body" field exactly in this shape):
<paste the COMMENT FORMAT section below here>
```

(One task per lens name — `correctness`, `conformance`, `necessity`, `security`, `reliability`, `tests` — each writing its own `$g-<lens>.jsonl`.)

### 5. Retry a crashed lens or a coverage gap

Run `scripts/post.sh <PR_NUM> --dry-run` and read its first two sections.

- **Missing output.** If a `$g-<lens>.jsonl` does not exist, re-run that one lens task once, unchanged.
- **Schema.** If the report shows `SCHEMA $g-<lens>: N untyped line(s)`, repair that file yourself with the write tool, before any retry: a line with `id`, `path` and `body` gets `"type":"finding"`; add one `{"type":"file","path":...}` line for each path its findings cite. Then run the dry-run again; a file still missing is a coverage gap.
- **Coverage gap.** If the report shows `GAP $g-<lens>: N file(s) not reported as read`, re-run that one lens once, for those files only. Use the same task with three changes: `Files assigned to you: $STATE_DIR/out/$g-<lens>.jsonl.gaps` (`post.sh` writes this file), ID prefix `$g-<lens>-r-` (so no id repeats), and the same output path (append, do not overwrite). Spawn all the gap re-runs in one parallel `subagent` call.

Retry each lens at most once. Then run the dry-run again. Name any gap that is still there in the Step 9 report. Do not re-run a lens that has output and no gap: that is its real result, not a crash.

### 6. Merge duplicates (general agent)

Always runs, after every lens finished (and Step 5 retries), before triage.

1. **Preview.** Run `scripts/post.sh <PR_NUM> --dry-run`. It writes validated, exact-deduped `$STATE_DIR/deduped-findings.json` (each item has `id`, `path`, `line`, `side`, `body`, `lens`). Note N = its item count.
2. **Merge.** Spawn ONE `subagent` (`agent: general`, `timeoutMs: 3600000`). Substitute the real `$STATE_DIR` first; the task is self-contained:
   - Read `$STATE_DIR/deduped-findings.json` (and code in `$STATE_DIR/src` if needed to judge).
   - Two findings are duplicates if they have the same `path` and `side`, sit within 5 lines of each other or in the same function or template block, AND describe the same issue. Different issues are NOT duplicates, even on one line. Findings in different files are never duplicates.
   - For each duplicate group, write one merged body: highest severity, the best evidence/fix from all copies, same COMMENT FORMAT. Keep the `id` of the member whose line has the strongest evidence; the body names the other lines as `path:line`.
   - Write ONLY `$STATE_DIR/merge-spec.json` with the write tool: `[{"keep": "<id>", "merged_from": ["<every id in the group, keep included>"], "body": "<merged body>"}]`, duplicate groups only (`[]` if none). Also write `$STATE_DIR/merge-log.txt` (each group: ids merged, why). Do not write `merged-findings.json`.
3. **Apply.** Run `scripts/apply-merge.sh <PR_NUM>`. It copies non-duplicates unchanged, builds `merged-findings.json`, and rejects a spec with an unknown or reused id. On failure, re-run the merge agent once with the script's error; if it fails again, `cp deduped-findings.json merged-findings.json`.

### 7. Interrogate & triage

Always runs; no skip. Never drop a finding on your own.

1. **Input.** Work from `$STATE_DIR/merged-findings.json`.
2. **Challenge.** Re-check every finding against `$STATE_DIR/src`. Give one verdict:
   - **Holds** — evidence as `path:line`.
   - **Weak** — cannot prove it; recommend downgrade to ❓.
   - **Wrong** — proof as `path:line` (POLICY drop reasons only).
3. **Open.** Do not print a findings table anywhere. Ask one `question` whose text gives counts only: by severity (serious 🔴 🟣 🟠, minor 🟡 ❓) and by your recommendation (Keep / Drop / Downgrade). Options: **Accept all recs** (record every recommendation as the decision, go to Apply) and **Review** (continue).
4. **Findings.** Use the `question` tool, about 5 findings per call, ordered 🔴 🟣 🟠 🟡 ❓. One tab per finding, containing: file and line (range if `start_line`), lens (and `merged_from` if present), ±3 lines of code from the worktree, full comment body, your challenge with evidence and any extra context. Options: **Keep**, **Drop**, **Downgrade to ❓**; mark your verdict `[rec]`. The human edits via free text.
   - After each `question` call (steps 3-4), parse the answers at once to `{id: "Keep"|"Drop"|"Downgrade"|"<free text>"}`. Merge them into `$STATE_DIR/triage-decisions.json` with `tools.write` before the next call.
   - Never keep raw answers in codemode `store()`. It has a 256KB limit, and a failed save loses the human's answers.
   - On a re-run, read `triage-decisions.json` and ask only about ids that are not in it.
5. **Apply.** Build the result from `triage-decisions.json` only. Edits and downgrades rewrite `body` in `merged-findings.json` (a downgraded body uses the ❓ format, no Fix block). Write kept ids, one per line, to `$STATE_DIR/approved-ids.txt`. An unanswered finding is kept.

### 8. Post

Run this skill's `scripts/post.sh <PR_NUM>` (needs `approved-ids.txt`; `--dry-run` previews without posting). It, in order:

1. Reports any missing lens output (Step 5).
2. Reports file coverage: for each group and lens, any assigned file the lens did not report reading.
3. Validates every finding's line against `hunks.tsv` — drops a finding whose line sits outside every hunk of that path+side, and downgrades a multi-line finding to single-line if only its end line is valid.
4. Removes exact duplicates (same path, line, side and body). In a real run, if `merged-findings.json` exists (Step 6 + triage edits), it is used as-is instead of rebuilding from raw lens output.
5. Keeps only findings whose id is in `approved-ids.txt` (not in `--dry-run`); prints how many triage dropped.
6. Prints counts by lens and by severity (the first character of each `body`).
7. Checks for a pending review. It stops if one exists at a different commit. If none exists, it creates one with only the first `POST_CHUNK` comments (default 50; one large create call can trip GitHub's secondary rate limit).
8. Lists the comments the pending review already holds, and appends only the comments that are not there yet (same path and body — GitHub returns `line: null` for pending comments; GraphQL, one call per comment, 1.2s apart — GitHub caps content creation at 80/min and 500/hour per user).
9. Retries every `gh` call on a rate limit, a network error or a 5xx (5 attempts, wait `RETRY_WAIT` × attempt, default 60s). It stops at once on any other error.
10. Verifies the review `state` is `PENDING`.

If `post.sh` stops partway (rate limit, network, Ctrl-C), run it again with no change. It resumes: it skips what is already posted and appends the rest to the same pending review.

### 9. Report

Paste `post.sh`'s own summary output (it already has the counts and the review URL) plus your acceptance-criteria coverage line if the caller supplied `ac.md`.

## RE-REVIEW (only when the caller asks)

Use this when the author pushed fixes or replied after an earlier review. Thread handling and new findings are separate jobs. Do thread replies first, before any pending review exists: a reply sent while a pending review exists joins that pending review instead of posting.

1. **Fetch.** Run `scripts/threads.sh fetch <PR_NUM>`. It writes `$STATE_DIR/threads.json` (every review thread: `id`, `isResolved`, `isOutdated`, `path`, `line`, `comments`) and prints the unresolved count.
2. **Verify.** Split the unresolved threads over `general` agents (about 40 per agent, in one parallel call). Each agent checks every thread against the code at HEAD, not against the author's claim. It gives one verdict and a draft reply:
   - **Fixed** or **AuthorJustified**: reply `✅ Verified at <sha>: <what changed or why the reason holds, path:line>.`
   - **NotFixed** or **AuthorReasonInvalid**: reply `⚠️ Not fixed at <sha>: <what is still wrong, path:line>. <what to do>.`
   - Every reply ends with `**Credit:** Pi`.
3. **Confirm.** Show the human a table of verdicts. Ask only about the non-✅ threads.
4. **Post.** For each thread, write the reply to a file and run `scripts/threads.sh reply <PR_NUM> <thread_id> <file>`. Then run `scripts/threads.sh resolve <PR_NUM> <thread_id>` for every ✅ thread. Leave ⚠️ threads open. Run `threads.sh fetch` again and report the unresolved count.
5. **Delta scope for new findings.** If the human also wants new findings, review only what the author changed since the old head:
   - Run `prepare.sh` again for the new head.
   - Move the old lens output aside: `out/` → `out-<old head sha>/`. Also move the old `merged-findings.json`, `triage-decisions.json` and `approved-ids.txt`.
   - For each changed file, compare the +/- lines of `git diff OLDBASE...OLDHEAD -- <f>` and `git diff BASE...HEAD -- <f>`. Keep the files that differ.
   - For each group `$g`, overwrite `files-$g.txt` and `hunks-$g.tsv` with only those files. `post.sh` reads these lists, so no other change is needed.
   - Run Steps 4–9 as usual. In each lens task, add: "Raise only lines the author changed between the two diffs above; give both git commands with real SHAs."

## SEVERITY TAXONOMY

- 🔴 **Critical** — security, auth, data loss/corruption, resource/transaction leaks, money/precision errors, silent failure of a write path, unsafe rollout/migration
- 🟣 **Structural** — ad-hoc conditional bolted onto an unrelated flow | feature logic in shared/general-purpose code | thin wrapper/identity abstraction with no clarity gain | a restructure would delete whole branches/layers instead of adding to them | logic in the wrong layer
- 🟠 **Major** — missing test for changed behavior | swallowed error | missing timeout/retry bound | performance (N+1, sequential `await` where `Promise.all` applies) | bespoke helper duplicating a canonical utility | boundary/type erosion (`any`/`unknown`/casts hiding an invariant)
- 🟡 **Improve** — naming, domain term drift (synonym, one name for two concepts, new term with no source), legibility, comment quality, parameter shape
- ❓ **Question** — a finding the lens could not fully prove, or a pre-existing issue found on a diff line

## COMMENT FORMAT

````
[EMOJI] **[CATEGORY]: [TITLE]**

**Issue:** [1-2 sentences]

**Fix:**
```lang
code
```

**Credit:** Pi
````

A ❓ finding drops the Fix block:

```
❓ **Question: [TITLE]**

[1-2 sentences: what looks off, and what evidence would confirm or clear it]

**Credit:** Pi
```

Write the `Issue` text or the question text in Simplified Technical English (ASD-STE100) — short sentences, simple vocabulary, active voice, one instruction per sentence.

**Suggestion blocks**: for a small self-contained fix (≤5 lines, single location), use a ` ```suggestion ` fence instead of a plain code fence — it replaces the ENTIRE commented line range, so never duplicate surrounding lines. Never use it for a structural or multi-location fix.

## VALIDATION CHECKLIST

- [ ] Not running in plan mode
- [ ] Local diff file count matches GitHub's `changedFiles` (or the mismatch is explained)
- [ ] Every lens's `$g-<lens>.jsonl` exists (retried once if missing)
- [ ] File coverage checked; each gap retried once; any remaining gap named in the report
- [ ] Every finding challenged and triaged; `approved-ids.txt` written
- [ ] Every finding's line is inside a hunk of the same path + side
- [ ] Exact duplicates merged
- [ ] General-agent merge done; id-accounting check passed (no finding lost)
- [ ] Bulk-create payload has exactly 2 keys: `commit_id`, `comments`; no `body`/`event`; at most `POST_CHUNK` comments
- [ ] Pending-review state checked BEFORE building comments (create first chunk + append vs. append vs. stop)
- [ ] Comment count in the review equals the number approved (re-run `post.sh` to resume if lower)
- [ ] Response `state: "PENDING"` confirmed

## 422 ERROR FIXES

| Error                                      | Cause                              | Fix                                                      |
| ------------------------------------------ | ----------------------------------- | --------------------------------------------------------- |
| "Line must be part of the diff"            | Comment outside a hunk              | Re-check `post.sh`'s line validation                        |
| "line number could not be resolved"        | Wrong `commit_id` or missing `side` | Use the worktree's current HEAD SHA; always send `side`     |
| "diff hunk can't be blank"                 | No diff context at that line        | Only comment on lines in `hunks.tsv`                        |
| "user_id can only have one pending review" | A pending review exists             | `post.sh`: append (same commit) or stop (different commit) — never delete |
| Misleading multi-line 422                  | `start_line` sent without `start_side` | Always send both together                                |
| "start_line: nil is not a number"          | A finding has `"start_line": null`  | `post.sh` adds `start_line` only when it is not null; never write a null `start_line` |
| 403 "secondary rate limit"                 | Too much content created too fast   | `post.sh` retries; if it still stops, wait a few minutes and re-run it — it resumes |

## MENTAL MODEL

```
Preconditions → prepare.sh (detached worktree @HEAD_SHA, local diff, hunks, groups, existing comments)
↓
Context (house rules + AC from caller)
↓
correctness + conformance + necessity + security + reliability + tests, per group, in parallel (2 batches) — each decides proven vs. ❓ itself
↓
post.sh --dry-run → retry, once, any lens with no output or with a file-coverage gap (gap files only)
↓
post.sh --dry-run → general agent specs nearby duplicates (merge-spec.json) → apply-merge.sh (merged-findings.json) → challenge each finding → human triage (keep/drop/edit) → approved-ids.txt
↓
post.sh: file coverage report → line validation → dedup → build comments → post (stop on stale pending |
create with first POST_CHUNK | then append only the comments not yet in the review; gh calls retried) → report
(re-run post.sh to resume after any stop)
```
