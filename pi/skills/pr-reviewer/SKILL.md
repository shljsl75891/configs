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

Everything else goes to triage (Step 6). Only the human drops a finding there; the agent only recommends. A finding you cannot fully prove stays, as a ❓ question — never silence it. Each lens makes the proven-vs-question call itself when it writes the finding; Step 6 re-checks it and the human decides.

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

Run this skill's `scripts/prepare.sh <PR_NUM>`, resolved relative to this skill's own directory (e.g. `bash /path/to/this/skill/scripts/prepare.sh 2720`). It fetches the base and head refs, builds or reuses a detached worktree at `$STATE_DIR/src`, diffs from the merge-base, and writes into `$STATE_DIR` (printed by the script, deterministically `/tmp/pr-review/<owner>-<repo>-<PR_NUM>`):

- `hunks.tsv` — `path, side, start, end` (1-indexed, inclusive). This is the valid-line table `post.sh` checks against.
- `files.txt` — every changed file.
- `file-groups.tsv`, `files-$g.txt`, `hunks-$g.tsv` — one group (`G1`) unless the PR touches more than 100 files, in which case 2 file-disjoint groups balanced by changed-line volume.
- `existing-comments.jsonl` — the PR's current review comments, for dedup.

It warns (does not stop) if the local file count disagrees with GitHub's; check the warning before trusting line numbers. Re-running at the same head commit reuses the worktree as-is — this is what makes the skill idempotent and resumable, and it also repairs a worktree that lost its `.git` metadata.

### 3. Context

If the invoking command supplied project conventions ("house rules") or acceptance criteria, write them verbatim to `$STATE_DIR/house-rules.md` and `$STATE_DIR/ac.md` — you already have this content in context from reading the invoking prompt; copy it, do not paraphrase it. Skip either file if the caller gave nothing; the lenses run fine without them.

### 4. Lens runs

Read each lens file, relative to this skill's own directory: `lenses/correctness.md`, `conformance.md`, `necessity.md`, `security.md`, `reliability.md`, `tests.md`. For each group `$g`, spawn 6 tasks as parallel `subagent` calls (`agent: code-reviewer`, `timeoutMs: 3600000` — the tool's max), all in one call (the tool's limit is 8), one per lens. Substitute real values for every `$VAR` below before sending the task — it becomes the subagent's task string verbatim, and a subagent starts a brand-new process with no access to your shell variables. Each task:

```
MODE: PR_LENS_REVIEW
Worktree: $STATE_DIR/src (read files here for full context; never modify anything in it)
Files assigned to you: $STATE_DIR/files-$g.txt
Hunks (path\tside\tstart\tend — valid lines for a finding): $STATE_DIR/hunks-$g.tsv
Existing PR comments (do not re-raise these): $STATE_DIR/existing-comments.jsonl
House rules (if present): $STATE_DIR/house-rules.md
Acceptance criteria (if present, correctness lens only): $STATE_DIR/ac.md
ID prefix for findings: $g-<lens>-
Output: append JSONL to $STATE_DIR/out/$g-<lens>.jsonl

RECALL MANDATE: Assume this diff contains bugs. The human triages every finding before posting, so a missed bug costs more than a noisy comment. List EVERY finding; do not stop at the first. Apply no confidence, nit, style, or "will the author agree" filter. Read outside the diff freely (callers, callees, siblings, config, tests). Flag pre-existing issues on diff lines as ❓. A high-impact issue you cannot prove is a ❓, never dropped. Do not read the PR title or description.

Follow this method:
<paste the full content of lenses/<lens>.md here>

Comment format (write the finding's "body" field exactly in this shape):
<paste the COMMENT FORMAT section below here>
```

(One task per lens name — `correctness`, `conformance`, `necessity`, `security`, `reliability`, `tests` — each writing its own `$g-<lens>.jsonl`.)

### 5. Retry a crashed lens

`post.sh` (Step 6 dry-run) reports any `$g-<lens>.jsonl` that does not exist. If one is missing, re-run just that one lens task once, then re-run `post.sh`. Do not re-run a lens that produced output, even a small amount — that is its real result, not a crash.

### 6. Interrogate & triage

Always runs; no skip. Never drop a finding on your own.

1. **Preview.** Run `scripts/post.sh <PR_NUM> --dry-run`. It writes validated, deduped `$STATE_DIR/deduped-findings.json` (each item has `id`, `path`, `line`, `side`, `body`, `lens`).
2. **Challenge.** Re-check every finding against `$STATE_DIR/src`. Give one verdict:
   - **Holds** — evidence as `path:line`.
   - **Weak** — cannot prove it; recommend downgrade to ❓.
   - **Wrong** — proof as `path:line` (POLICY drop reasons only).
3. **Table.** Print: `#`, id, severity, lens, `path:line[side]`, title, verdict.
4. **Ask.** Use the `question` tool, about 5 findings per call, ordered 🔴 🟣 🟠 🟡 ❓. One tab per finding, containing: file and line (range if `start_line`), lens, ±3 lines of code from the worktree, full comment body, your challenge with evidence and any extra context. Options: **Keep**, **Drop**, **Downgrade to ❓**; mark your verdict `[rec]`. The human edits via free text.
5. **Apply.** Edits and downgrades rewrite `body` in `deduped-findings.json` (a downgraded body uses the ❓ format, no Fix block). Write kept ids, one per line, to `$STATE_DIR/approved-ids.txt`. An unanswered finding is kept.

### 7. Post

Run this skill's `scripts/post.sh <PR_NUM>` (needs `approved-ids.txt`; `--dry-run` previews without posting). It, in order:

1. Reports any missing lens output (Step 5 above).
2. Reports file coverage: for each group and lens, any assigned file the lens did not report reading.
3. Validates every finding's line against `hunks.tsv` — drops a finding whose line sits outside every hunk of that path+side, and downgrades a multi-line finding to single-line if only its end line is valid.
4. Removes exact duplicates (same path, line, side and body — e.g. two lenses independently catching the identical dead-parameter case).
5. Keeps only findings whose id is in `approved-ids.txt` (not in `--dry-run`); prints how many triage dropped.
6. Prints counts by lens and by severity (the first character of each `body`).
7. Checks for a pending review at the current head commit and appends to it (GraphQL, one call per comment, 1.2s apart — GitHub caps content creation at 80/min and 500/hour per user), bulk-creates a new one if none exists, or stops if a pending review exists at a different commit.
8. Verifies the response `state` is `PENDING`.

### 8. Report

Paste `post.sh`'s own summary output (it already has the counts and the review URL) plus your acceptance-criteria coverage line if the caller supplied `ac.md`.

## SEVERITY TAXONOMY

- 🔴 **Critical** — security, auth, data loss/corruption, resource/transaction leaks, money/precision errors, silent failure of a write path, unsafe rollout/migration
- 🟣 **Structural** — ad-hoc conditional bolted onto an unrelated flow | feature logic in shared/general-purpose code | thin wrapper/identity abstraction with no clarity gain | a restructure would delete whole branches/layers instead of adding to them | logic in the wrong layer
- 🟠 **Major** — missing test for changed behavior | swallowed error | missing timeout/retry bound | performance (N+1, sequential `await` where `Promise.all` applies) | bespoke helper duplicating a canonical utility | boundary/type erosion (`any`/`unknown`/casts hiding an invariant)
- 🟡 **Improve** — naming, legibility, comment quality, parameter shape
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
- [ ] File coverage checked; any gap named in the report
- [ ] Every finding challenged and triaged; `approved-ids.txt` written
- [ ] Every finding's line is inside a hunk of the same path + side
- [ ] Exact duplicates merged
- [ ] Bulk-create payload has exactly 2 keys: `commit_id`, `comments`; no `body`/`event`
- [ ] Pending-review state checked BEFORE building comments (append vs. bulk-create vs. stop)
- [ ] Response `state: "PENDING"` confirmed

## 422 ERROR FIXES

| Error                                      | Cause                              | Fix                                                      |
| ------------------------------------------ | ----------------------------------- | --------------------------------------------------------- |
| "Line must be part of the diff"            | Comment outside a hunk              | Re-check `post.sh`'s line validation                        |
| "line number could not be resolved"        | Wrong `commit_id` or missing `side` | Use the worktree's current HEAD SHA; always send `side`     |
| "diff hunk can't be blank"                 | No diff context at that line        | Only comment on lines in `hunks.tsv`                        |
| "user_id can only have one pending review" | A pending review exists             | `post.sh`: append (same commit) or stop (different commit) — never delete |
| Misleading multi-line 422                  | `start_line` sent without `start_side` | Always send both together                                |

## MENTAL MODEL

```
Preconditions → prepare.sh (detached worktree @HEAD_SHA, local diff, hunks, groups, existing comments)
↓
Context (house rules + AC from caller)
↓
correctness + conformance + necessity + security + reliability + tests, per group, in parallel (2 batches) — each decides proven vs. ❓ itself
↓
Retry any lens with no output, once
↓
post.sh --dry-run → challenge each finding → human triage (keep/drop/edit) → approved-ids.txt
↓
post.sh: file coverage report → line validation → dedup → build comments → post (append to same-commit
pending review | bulk-create | stop on stale pending) → report
```
