#!/usr/bin/env bash
# pr-reviewer: Steps 6-9 mechanics — coverage report, line validation, dedup, build, post.
# Usage: scripts/post.sh <pr-number> [--dry-run]
# Precondition: scripts/prepare.sh already ran for this PR from the same cwd.
set -euo pipefail

PR_NUM="${1:?usage: post.sh <pr-number> [--dry-run]}"
PR_NUM="${PR_NUM//[^0-9]/}"   # keep digits only: users may type "#N" or "N,"
[ -n "$PR_NUM" ] || { echo "ERROR: PR number has no digits: '$1'" >&2; exit 1; }
DRY_RUN=0
[ "${2:-}" = "--dry-run" ] && DRY_RUN=1

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/pr-review/${REPO//\//-}-${PR_NUM}"
SRC_DIR="$STATE_DIR/src"
OUT_DIR="$STATE_DIR/out"

[ -d "$STATE_DIR" ] || { echo "ERROR: no state dir for $REPO#$PR_NUM — run prepare.sh first." >&2; exit 1; }

PR_GROUPS=$(cut -f2 "$STATE_DIR/file-groups.tsv" | LC_ALL=C sort -u)
LENSES="correctness conformance necessity security reliability tests"

echo "== Missing lens output =="
MISSING=0
for g in $PR_GROUPS; do
  for lens in $LENSES; do
    f="$OUT_DIR/$g-$lens.jsonl"
    if [ ! -f "$f" ]; then
      echo "MISSING: $g-$lens.jsonl (re-run this one lens once, then re-run post.sh)"
      MISSING=1
    fi
  done
done
[ "$MISSING" = "0" ] && echo "none"

echo "== File coverage (files assigned to a lens vs files it reported reading) =="
: > "$STATE_DIR/all-findings.jsonl"
for g in $PR_GROUPS; do
  for lens in $LENSES; do
    f="$OUT_DIR/$g-$lens.jsonl"
    [ -f "$f" ] || continue
    jq -r 'select(.type=="file") | .path' "$f" 2>/dev/null | LC_ALL=C sort -u > "$f.read"
    # Lockfiles and snapshots are generated: lenses do not report reading them, so they are no gap.
    grep -vE '(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|[^/]+\.snap)$' "$STATE_DIR/files-$g.txt" \
      | LC_ALL=C sort -u > "$f.assigned" || true
    LC_ALL=C comm -23 "$f.assigned" "$f.read" > "$f.gaps" || true
    if [ -s "$f.gaps" ]; then
      echo "GAP $g-$lens: $(wc -l < "$f.gaps") file(s) not reported as read:"
      sed 's/^/  /' "$f.gaps"
    fi
    jq -c --arg lens "$lens" --arg g "$g" 'select(.type=="finding") | . + {lens:$lens, group:$g}' "$f" \
      >> "$STATE_DIR/all-findings.jsonl"
  done
done

TOTAL_FOUND=$(wc -l < "$STATE_DIR/all-findings.jsonl")
echo "Total findings before validation: $TOTAL_FOUND"

echo "== Line validation =="
: > "$STATE_DIR/valid-findings.jsonl"
DROPPED=0
DOWNGRADED=0
while IFS= read -r finding; do
  [ -z "$finding" ] && continue
  p=$(jq -r .path <<<"$finding")
  s=$(jq -r .side <<<"$finding")
  end_l=$(jq -r .line <<<"$finding")
  start_l=$(jq -r '.start_line // .line' <<<"$finding")
  ok_end=$(awk -F'\t' -v p="$p" -v l="$end_l" -v s="$s" '$1==p && $2==s && l>=$3 && l<=$4{f=1} END{print f+0}' "$STATE_DIR/hunks.tsv")
  ok_start=$(awk -F'\t' -v p="$p" -v l="$start_l" -v s="$s" '$1==p && $2==s && l>=$3 && l<=$4{f=1} END{print f+0}' "$STATE_DIR/hunks.tsv")
  if [ "$ok_end" != "1" ]; then
    echo "DROPPED (line not in a diff hunk): $p:$end_l:$s" >&2
    DROPPED=$((DROPPED+1))
  elif [ "$ok_start" != "1" ]; then
    echo "DOWNGRADED to single-line (start line not in the same hunk): $p:$start_l..$end_l:$s" >&2
    DOWNGRADED=$((DOWNGRADED+1))
    jq -c 'del(.start_line)' <<<"$finding" >> "$STATE_DIR/valid-findings.jsonl"
  else
    echo "$finding" >> "$STATE_DIR/valid-findings.jsonl"
  fi
done < "$STATE_DIR/all-findings.jsonl"
echo "Dropped: $DROPPED  Downgraded to single-line: $DOWNGRADED"

echo "== Dedup (same path + line + side + body) =="
BEFORE=$(wc -l < "$STATE_DIR/valid-findings.jsonl")
if [ "$DRY_RUN" = "0" ] && [ -f "$STATE_DIR/merged-findings.json" ]; then
  echo "Using $STATE_DIR/merged-findings.json (general-agent merge + triage edits)"
  cp "$STATE_DIR/merged-findings.json" "$STATE_DIR/deduped-findings.json"
else
  jq -s 'unique_by([.path, .line, .side, .body])' "$STATE_DIR/valid-findings.jsonl" > "$STATE_DIR/deduped-findings.json"
fi
AFTER=$(jq 'length' "$STATE_DIR/deduped-findings.json")
echo "Before: $BEFORE  After: $AFTER  Merged: $((BEFORE-AFTER))"

echo "== Triage filter (approved-ids.txt, written by SKILL.md Step 7) =="
if [ "$DRY_RUN" = "0" ]; then
  [ -f "$STATE_DIR/approved-ids.txt" ] || { echo "ERROR: $STATE_DIR/approved-ids.txt missing — run the interrogate & triage step first." >&2; exit 1; }
  jq --rawfile ids "$STATE_DIR/approved-ids.txt" '($ids | split("\n")) as $ok | map(select(.id | IN($ok[])))' \
    "$STATE_DIR/deduped-findings.json" > "$STATE_DIR/triaged-findings.json"
  mv "$STATE_DIR/triaged-findings.json" "$STATE_DIR/deduped-findings.json"
  echo "Dropped in triage: $((AFTER-$(jq 'length' "$STATE_DIR/deduped-findings.json")))"
else
  echo "--dry-run: skipped"
fi

echo "== Findings by lens =="
jq -r '.[].lens' "$STATE_DIR/deduped-findings.json" | sort | uniq -c

echo "== Findings by severity marker (first character of body) =="
jq -r '.[].body[0:1]' "$STATE_DIR/deduped-findings.json" | sort | uniq -c
UNKNOWN=$(jq -r '.[].body[0:1]' "$STATE_DIR/deduped-findings.json" | grep -vcE '🔴|🟣|🟠|🟡|❓' || true)
[ "$UNKNOWN" != "0" ] && echo "WARNING: $UNKNOWN finding(s) have no recognized severity emoji as their first character — still posting them, just flagging for review."

# GitHub rejects start_line > line (422). Lenses and triage edits sometimes write the range backwards.
jq '{comments: [.[]
    | if (.start_line != null and .start_line > .line) then .start_line as $s | .start_line = .line | .line = $s else . end
    | {path, line, side, body} + (if .start_line != null then {start_line, start_side: .side} else {} end)]}' \
  "$STATE_DIR/deduped-findings.json" > "$STATE_DIR/comments.json"

COMMENT_COUNT=$(jq '.comments | length' "$STATE_DIR/comments.json")
echo "== Comments to post: $COMMENT_COUNT =="

if [ "$DRY_RUN" = "1" ]; then
  echo "--dry-run: not posting. Full payload: $STATE_DIR/comments.json"
  jq -r '.comments[] | "\(.path):\(.line)[\(.side)] \(.body[0:70] | gsub("\n";" "))"' "$STATE_DIR/comments.json"
  exit 0
fi

if [ "$COMMENT_COUNT" = "0" ]; then
  echo "Nothing to post."
  exit 0
fi

POST_CHUNK="${POST_CHUNK:-50}"
RETRY_WAIT="${RETRY_WAIT:-60}"

# Runs gh. Retries a GitHub rate limit, a network error or a 5xx up to 5 times, with a longer wait
# each time. Stops at once on any other error (for example a 422), so a real bug is not hidden.
gh_retry() {
  local attempt errf
  errf=$(mktemp)
  for attempt in 1 2 3 4 5; do
    if gh "$@" 2>"$errf"; then rm -f "$errf"; return 0; fi
    if ! grep -qiE 'rate limit|error connecting|timeout|HTTP (429|5[0-9][0-9])' "$errf"; then
      cat "$errf" >&2; rm -f "$errf"; return 1
    fi
    echo "gh failed (attempt $attempt/5): $(head -c 160 "$errf" | tr '\n' ' '). Retry in $((RETRY_WAIT * attempt))s." >&2
    sleep $((RETRY_WAIT * attempt))
  done
  cat "$errf" >&2; rm -f "$errf"; return 1
}

HEAD_SHA=$(cd "$SRC_DIR" && git rev-parse HEAD)
PENDING=$(gh_retry api -H "X-GitHub-Api-Version: 2022-11-28" "repos/$REPO/pulls/$PR_NUM/reviews" \
  --jq '[.[]|select(.state=="PENDING")][0] // empty')
PENDING_SHA=$(jq -r '.commit_id // empty' <<<"$PENDING")

if [ -n "$PENDING" ] && [ "$PENDING_SHA" != "$HEAD_SHA" ]; then
  echo "STOP: a pending review exists at commit $PENDING_SHA, not the current head $HEAD_SHA."
  echo "Ask the user to submit or discard it in the GitHub UI, then re-run post.sh."
  exit 1
fi

if [ -z "$PENDING" ]; then
  # No pending review yet. Create it with the first chunk only: one large create call can trip
  # GitHub's secondary rate limit. Exactly 2 top-level keys: commit_id, comments.
  jq --arg sha "$HEAD_SHA" --argjson n "$POST_CHUNK" '{commit_id:$sha, comments:.comments[:$n]}' \
    "$STATE_DIR/comments.json" > "$STATE_DIR/payload.json"
  gh_retry api -X POST -H "X-GitHub-Api-Version: 2022-11-28" "repos/$REPO/pulls/$PR_NUM/reviews" \
    --input "$STATE_DIR/payload.json" > "$STATE_DIR/response.json"
  REVIEW_ID=$(jq -r .id "$STATE_DIR/response.json")
  NODE_ID=$(jq -r .node_id "$STATE_DIR/response.json")
  echo "Created pending review with $(jq '.comments | length' "$STATE_DIR/payload.json") comment(s)."
else
  # A pending review already sits at the current head. It may hold the human's own draft comments
  # or a part of an earlier run. Append to it; never delete it, never touch its existing threads.
  REVIEW_ID=$(jq -r .id <<<"$PENDING")
  NODE_ID=$(jq -r .node_id <<<"$PENDING")
fi

# Append every comment that the review does not hold yet. So a re-run after a failure resumes
# without duplicates. Match on path + body: this endpoint returns line=null for pending comments.
# GitHub may strip trailing whitespace and \r, so compare normalized bodies.
gh_retry api --paginate -H "X-GitHub-Api-Version: 2022-11-28" \
  "repos/$REPO/pulls/$PR_NUM/reviews/$REVIEW_ID/comments?per_page=100" --jq '.[] | {path, body}' \
  > "$STATE_DIR/posted.jsonl"
jq -c --slurpfile posted "$STATE_DIR/posted.jsonl" '
  def key: [.path, (.body | gsub("\r"; "") | sub("\\s+$"; ""))];
  ($posted | map(key)) as $done
  | .comments[] | select(key as $k | any($done[]; . == $k) | not)' \
  "$STATE_DIR/comments.json" > "$STATE_DIR/to-append.jsonl"
echo "Already in review: $(jq -s length "$STATE_DIR/posted.jsonl")  To append: $(wc -l < "$STATE_DIR/to-append.jsonl")"

while IFS= read -r c; do
  gh_retry api graphql -f query='mutation($rid:ID!,$path:String!,$body:String!,$line:Int!,$side:DiffSide!,$startLine:Int,$startSide:DiffSide){
    addPullRequestReviewThread(input:{pullRequestReviewId:$rid,path:$path,body:$body,line:$line,side:$side,startLine:$startLine,startSide:$startSide}){thread{id}}}' \
    -f rid="$NODE_ID" -f path="$(jq -r .path <<<"$c")" -f body="$(jq -r .body <<<"$c")" \
    -F line="$(jq -r .line <<<"$c")" -f side="$(jq -r .side <<<"$c")" \
    -F startLine="$(jq -r '.start_line // "null"' <<<"$c")" -F startSide="$(jq -r '.start_side // "null"' <<<"$c")" > /dev/null
  sleep 1.2   # GitHub docs: wait >=1s between mutative requests; limit is 80 content-generating/min, 500/hour
done < "$STATE_DIR/to-append.jsonl"

read -r STATE REVIEW_URL < <(gh_retry api -H "X-GitHub-Api-Version: 2022-11-28" \
  "repos/$REPO/pulls/$PR_NUM/reviews/$REVIEW_ID" --jq '"\(.state) \(.html_url)"')
echo "Review state: $STATE"
echo "Pending review: $REVIEW_URL"
echo "Files view (pending comments inline): https://github.com/$REPO/pull/$PR_NUM/files"
