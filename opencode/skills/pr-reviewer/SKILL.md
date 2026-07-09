---
name: pr-reviewer
description: Generic mechanics for reviewing GitHub PRs with inline pending-review comments — diff hunk line validation, review API payload construction/submission via gh api, adaptive single/multi-agent review, verification pass, and a reusable severity taxonomy. Load when doing any PR review
---

# PR Reviewer — Generic Mechanics

Reusable workflow for AI-driven GitHub PR reviews that end in a PENDING review the human submits manually.

## CRITICAL RULES

1. **ALWAYS use `side` param**: `RIGHT` for additions/context, `LEFT` for deletions. Never use deprecated `position`.
2. **Lines MUST be within diff hunks** — parse the diff to compute valid ranges first.
3. **Payload**: exactly 2 keys — `commit_id` + `comments` (each comment: `path`, `line`, `side`, `body`; multi-line adds `start_line`, `start_side`).
4. **NO `body`/`event` in payload** — omitting `event` keeps review PENDING. (Pending-review `body` is also lossy in the GitHub UI — never set it.)
5. Verify `state === "PENDING"` in the response.
6. **One pending review per user per PR** — a stale pending review causes a 422; detect and handle before creating.

## WORKFLOW

### 1. Setup

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
PR_NUM=<PR number from the invoking command>
PR_BRANCH=$(gh pr view $PR_NUM --json headRefName -q .headRefName)
HEAD_SHA=$(gh pr view $PR_NUM --json headRefOid -q .headRefOid)
WORKTREE_DIR="/tmp/pr-review-${REPO//\//-}-$PR_NUM"

git worktree add "$WORKTREE_DIR" "$PR_BRANCH" 2>/dev/null || git worktree add "$WORKTREE_DIR" "origin/$PR_BRANCH"
gh pr diff $PR_NUM --patch > "$WORKTREE_DIR/.pr.diff"
echo '{"commit_id": "'$HEAD_SHA'", "comments": []}' > "$WORKTREE_DIR/.comments.json"
```

### 2. Stale Pending Review Check

```bash
PENDING_ID=$(gh api "repos/$REPO/pulls/$PR_NUM/reviews" -q '.[] | select(.state=="PENDING") | .id' | head -1)
[ -n "$PENDING_ID" ] && gh api -X DELETE "repos/$REPO/pulls/$PR_NUM/reviews/$PENDING_ID"
```

If deletion fails, ABORT and tell the user a pending review already exists.

### 3. Parse Diff — Extract Valid Line Ranges

```bash
grep -E "^\+\+\+ b/|^@@" "$WORKTREE_DIR/.pr.diff" | awk '
/^\+\+\+ b\// { file=substr($0, 5) }
/^@@ .*\+([0-9]+),?([0-9]*)/ {
  match($0, /\+([0-9]+),?([0-9]*)/, arr)
  start=arr[1]
  count=(arr[2]=="") ? 1 : arr[2]
  print file ":" start "-" (start+count-1)
}' > "$WORKTREE_DIR/.valid-lines.txt"
```

Hunk header `@@ -45,10 +55,12 @@` → `+55,12` means NEW-file lines 55–66 are valid for comments (`side: "RIGHT"`, 99% of cases); `LEFT` only for deletions.

```diff
@@ -45,10 +45,12 @@ export class Example {
   constructor(
+    @inject('services.FooService')
+    private fooService: FooService,  // Line 47 — VALID, side RIGHT
   ) {}
 }
```

### 4. Dedup Context

Fetch existing inline comments; skip findings already raised:

```bash
gh api "repos/$REPO/pulls/$PR_NUM/comments" --jq '.[] | {path, line, body: .body[0:120]} | @json' > "$WORKTREE_DIR/.existing-comments.jsonl"
```

### 5. Review — Adaptive Strategy

```bash
CHANGED_FILES=$(grep -c '^+++ ' "$WORKTREE_DIR/.pr.diff")
```

**≤25 files — single-pass:** review each changed file directly against the command's review-focus tiers. Only flag issues on lines within `.valid-lines.txt` ranges.

**>25 files — multi-agent:** spawn parallel specialized subagents (one message, multiple Task calls), one per taxonomy tier the command defines focus items for (e.g. Security, Structural, Performance/Abstraction, Quality). Each subagent prompt must include:

- Worktree path, `.pr.diff` path, `.valid-lines.txt` path
- The command's focus items for its tier only
- Output contract: JSON findings `[{path, line, start_line?, severity, title, body, rationale}]` — lines must fall in valid ranges

If the command defines a ticket cross-check (e.g. JIRA AC), run it as one more parallel subagent. Merge all findings; on same `path`+`line` overlap keep the highest-severity one.

### 6. Verification Pass (both modes)

For every candidate finding, re-examine against actual file content + diff:

- Confirm the issue is real, introduced by THIS diff (not pre-existing), and on a valid diff line
- Assign confidence 0–100; **drop anything <80**
- Drop anything matching the suppression list below

### 7. Build Comments

Append each surviving finding:

```bash
cat > "$WORKTREE_DIR/.comment.json" << 'EOF'
{
  "path": "src/example.ts",
  "line": 47,
  "side": "RIGHT",
  "body": "..."
}
EOF
jq '.comments += [input]' "$WORKTREE_DIR/.comments.json" "$WORKTREE_DIR/.comment.json" > "$WORKTREE_DIR/.temp.json" && mv "$WORKTREE_DIR/.temp.json" "$WORKTREE_DIR/.comments.json"
```

**Multi-line finding** (span within one hunk): add `"start_line": <first>`, `"start_side": "RIGHT"` alongside `line`/`side`. ALWAYS send `start_side` explicitly — omitting it yields a misleading 422.

### 8. Submit (PENDING)

```bash
# Validate BEFORE building payload — catch stray keys at the source
jq -e '.body or .event' "$WORKTREE_DIR/.comments.json" 2>/dev/null && echo "❌ Remove body/event from comments.json" && exit 1
jq -e '.comments | length == 0' "$WORKTREE_DIR/.comments.json" >/dev/null && echo "❌ No comments to post" && exit 1

jq -c '{commit_id: .commit_id, comments: .comments}' "$WORKTREE_DIR/.comments.json" > "$WORKTREE_DIR/.payload.json"

gh api -X POST \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "repos/$REPO/pulls/$PR_NUM/reviews" \
  --input "$WORKTREE_DIR/.payload.json" > "$WORKTREE_DIR/.response.json"

state=$(jq -r '.state // "ERROR"' "$WORKTREE_DIR/.response.json")
[ "$state" = "PENDING" ] && echo "✅ Review: $(jq -r '.html_url' "$WORKTREE_DIR/.response.json")"
[ "$state" != "PENDING" ] && jq '.' "$WORKTREE_DIR/.response.json" && exit 1
```

### 9. Cleanup

```bash
git worktree remove --force "$WORKTREE_DIR"
echo "Review PENDING — user submits via GitHub UI"
```

## SEVERITY TAXONOMY (default — command maps its focus items into these tiers)

- 🔴 **Critical** — security vulnerabilities, auth gaps, data corruption/loss, transaction/resource leaks
- 🟣 **Structural** — new ad-hoc conditionals bolted onto unrelated flows | feature logic leaked into shared/general-purpose paths | thin wrappers/identity abstractions with no clarity gain | missed code-judo: whole branches/layers deletable instead of added | logic in wrong layer | file-size explosions
- 🟠 **Major** — performance (N+1, sequential awaits where `Promise.all` applies, missing pagination/bulk ops) | bespoke helper duplicating a canonical utility | boundary/type-contract erosion (`any`/`unknown`/casts papering over invariants)
- 🟡 **Improve** — naming, legibility, ≤2 params (options object), no flag params, `import type`, `throw new Error()` not strings, never swallow caught errors

## COMMENT FORMAT

````
[EMOJI] **[CATEGORY]: [TITLE]**

**Issue:** [1-2 sentences]

**Fix:**
```lang
code
```

**Credit:** Open Code
````

**Suggestion blocks**: for small self-contained fixes (≤5 lines, single location), use a ` ```suggestion ` fence instead of a plain code fence — it replaces the ENTIRE commented line range, so never duplicate surrounding lines. Never use suggestion blocks for structural/multi-location fixes.

## APPROVAL BAR (baseline)

Behavior-correct is NOT sufficient. Presumptive blockers:

- Structural regression: code objectively harder to reason about than before
- Missed code-judo move that would delete whole categories of complexity
- Ad-hoc conditional bolted onto an existing unrelated flow
- Feature logic scattered into shared/general-purpose code
- Thin wrapper or identity abstraction adding indirection with no clarity gain
- Bespoke helper duplicating an existing canonical utility
- Sequential `await` chain where `Promise.all` is obviously applicable
- Caught error silently swallowed (no log, no rethrow)

## SKIP / FALSE-POSITIVE SUPPRESSION

Never flag:

- Anything a linter, formatter, or type-checker already catches
- Pre-existing issues not introduced by this diff
- Pedantic nitpicks or subjective style with no semantic impact
- General quality concerns without a concrete, actionable fix
- Missing docs on self-explanatory code

Commands may extend this list.

## VALIDATION CHECKLIST

- [ ] Stale pending review handled
- [ ] Comments only on lines within diff hunks (@@ ranges)
- [ ] Every comment has `path`, `line`, `side`, `body` (+ `start_line`/`start_side` for ranges)
- [ ] Deduped against existing PR comments
- [ ] Verification pass done; only confidence ≥80 findings posted
- [ ] Payload has exactly 2 keys: `commit_id`, `comments`; no `body`/`event`
- [ ] Response `state: "PENDING"`
- [ ] Worktree cleaned up

## 422 ERROR FIXES

| Error                                      | Cause                             | Fix                                                  |
| ------------------------------------------ | --------------------------------- | ---------------------------------------------------- |
| "Line must be part of the diff"            | Comment outside hunk              | Verify line is in @@ range                           |
| "line number could not be resolved"        | Wrong commit_id or missing `side` | Use HEAD_SHA, add `"side": "RIGHT"`                  |
| "diff hunk can't be blank"                 | No diff context                   | Only comment on changed lines                        |
| "user_id can only have one pending review" | Stale pending review              | Delete/submit existing pending review first (Step 2) |
| Misleading multi-line 422                  | Missing `start_side`              | Always send `start_side` with `start_line`           |

## MENTAL MODEL

```
Setup → Stale-pending check → Parse diff → Valid line ranges → Dedup context
↓
≤25 files: single-pass review | >25 files: parallel tier subagents (+ ticket pass) → merge
↓
Verification pass (confidence ≥80, suppression list)
↓
Build comments (path+line+side[+start_line+start_side]+body, suggestion blocks for small fixes)
↓
Submit PENDING via gh api → Cleanup → Human submits via GitHub UI
```
