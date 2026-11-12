#!/usr/bin/env bash
# pr-reviewer: Step 6 mechanics — build merged-findings.json from deduped-findings.json + merge-spec.json.
# Usage: scripts/apply-merge.sh <pr-number>
# merge-spec.json: [{"keep": "<id>", "merged_from": ["<id>", ...], "body": "<merged body>"}]
# Exits non-zero, and writes nothing, when the spec names an unknown id, reuses an id, or omits keep.
set -euo pipefail

PR_NUM="${1:?usage: apply-merge.sh <pr-number>}"
PR_NUM="${PR_NUM//[^0-9]/}"
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/pr-review/${REPO//\//-}-${PR_NUM}"
FINDINGS="$STATE_DIR/deduped-findings.json"
SPEC="$STATE_DIR/merge-spec.json"

[ -f "$FINDINGS" ] || { echo "ERROR: $FINDINGS missing — run post.sh --dry-run first." >&2; exit 1; }
[ -f "$SPEC" ] || { echo "ERROR: $SPEC missing — the merge agent writes it." >&2; exit 1; }

ERRORS=$(jq -r --slurpfile spec "$SPEC" '
  (map(.id)) as $ids
  | ([$spec[0][].merged_from[]]) as $gone
  | ([$gone[] | select(IN($ids[]) | not) | "unknown id: \(.)"]
     + [$gone | group_by(.)[] | select(length > 1) | "id in more than one group: \(.[0])"]
     + [$spec[0][] | select(.keep as $k | any(.merged_from[]; . == $k) | not) | "keep not in its merged_from: \(.keep)"]
     + [$spec[0][] | select((.merged_from | length) < 2) | "group has fewer than 2 ids: \(.keep)"])[]' \
  "$FINDINGS")
if [ -n "$ERRORS" ]; then
  echo "ERROR: merge-spec.json is invalid:" >&2
  echo "$ERRORS" | sed 's/^/  /' >&2
  exit 1
fi

jq --slurpfile spec "$SPEC" '
  (map({key: .id, value: .}) | from_entries) as $by
  | ([$spec[0][].merged_from[]]) as $gone
  | [$spec[0][] as $g
      | $by[$g.keep] + {
          body: ($g.body // $by[$g.keep].body),
          lens: ([$g.merged_from[] | $by[.].lens | split(",")[]] | unique | join(",")),
          merged_from: $g.merged_from}]
    + map(select(.id | IN($gone[]) | not))' \
  "$FINDINGS" > "$STATE_DIR/merged-findings.json"

echo "Findings: $(jq length "$FINDINGS") -> $(jq length "$STATE_DIR/merged-findings.json") (groups: $(jq length "$SPEC"))"
