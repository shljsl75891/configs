#!/usr/bin/env bash
# pr-reviewer: Step 2 mechanics — worktree, diff, hunks, groups, existing comments.
# Usage: scripts/prepare.sh <pr-number>
# Precondition: cwd is inside a clone of the PR's own repo (its `origin` remote
# must be that repo — `gh repo view` resolves the repo from cwd, not from an argument).
set -euo pipefail

PR_NUM="${1:?usage: prepare.sh <pr-number>}"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "ERROR: not inside a git working tree. cd into a clone of the PR's repo first." >&2
  exit 1
}

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner) || {
  echo "ERROR: 'gh repo view' failed — cwd's origin is not a GitHub repo gh can resolve." >&2
  exit 1
}

HEAD_SHA=$(gh pr view "$PR_NUM" --json headRefOid -q .headRefOid)
BASE_REF=$(gh pr view "$PR_NUM" --json baseRefName -q .baseRefName)
GH_CHANGED_FILES=$(gh pr view "$PR_NUM" --json changedFiles -q .changedFiles)

case "$HEAD_SHA" in
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*) ;;
  *) echo "ERROR: could not resolve a head SHA for $REPO#$PR_NUM (got '$HEAD_SHA')." >&2; exit 1 ;;
esac

STATE_DIR="/tmp/pr-review/${REPO//\//-}-${PR_NUM}"
SRC_DIR="$STATE_DIR/src"
OUT_DIR="$STATE_DIR/out"
mkdir -p "$OUT_DIR"

# `gh pr view` has no baseRefOid field. Fetch base and head to explicit local refs —
# works the same in a bare-repo worktree layout, a plain clone, or a fork PR.
# --no-tags: some repos (lerna monorepos) have hundreds of release tags; we never need them.
git fetch --no-tags origin \
  "+$BASE_REF:refs/pr-review/$PR_NUM-base" \
  "+refs/pull/$PR_NUM/head:refs/pr-review/$PR_NUM-head"
BASE_SHA=$(git rev-parse "refs/pr-review/$PR_NUM-base")

# NOTE: never use "git -C" in this codebase's environment — a permission rule denies it
# unconditionally. Use "(cd DIR && git ...)" instead.

# Prune stale worktree registrations unconditionally. Without this, a directory that
# went missing outside git (e.g. /tmp was wiped) leaves git believing the worktree still
# exists, and `git worktree add` below fails with "missing but already registered worktree".
git worktree prune

CURRENT_HEAD=""
if [ -d "$SRC_DIR" ]; then
  CURRENT_HEAD=$(cd "$SRC_DIR" && git rev-parse HEAD 2>/dev/null) || CURRENT_HEAD=""
fi
if [ -d "$SRC_DIR" ] && [ "$CURRENT_HEAD" != "$HEAD_SHA" ]; then
  # Also covers a broken worktree (missing .git, CURRENT_HEAD empty) — rebuild it clean.
  git worktree remove --force "$SRC_DIR" 2>/dev/null || rm -rf "$SRC_DIR"
  git worktree prune
  rm -rf "${OUT_DIR:?}"/*
fi
[ -d "$SRC_DIR" ] || git worktree add --detach "$SRC_DIR" "$HEAD_SHA"

MERGE_BASE=$(cd "$SRC_DIR" && git merge-base "$BASE_SHA" "$HEAD_SHA")
(cd "$SRC_DIR" && git diff --no-color "$MERGE_BASE" "$HEAD_SHA") > "$STATE_DIR/pr.diff"
# Do NOT use `gh pr diff --patch` — it returns one patch per commit, so line numbers
# repeat and are wrong on any multi-commit PR.

LOCAL_FILES=$(grep -c '^diff --git' "$STATE_DIR/pr.diff" || true)
if [ "$LOCAL_FILES" != "$GH_CHANGED_FILES" ]; then
  echo "WARNING: local diff has $LOCAL_FILES files, GitHub reports $GH_CHANGED_FILES — check the merge-base before trusting line numbers." >&2
fi

# hunks.tsv columns: path, side, start, end (1-indexed, inclusive).
# LEFT rows use the pre-image path (so a fully deleted file still gets LEFT rows);
# RIGHT rows use the post-image path. Modified files: both are normally the same path.
awk '
/^diff --git/ { file=""; dfile="" }
/^--- / { p=$0; sub(/^--- /,"",p); if (p=="/dev/null") dfile=""; else { sub(/^a\//,"",p); dfile=p }; next }
/^\+\+\+ / { p=$0; sub(/^\+\+\+ /,"",p); if (p=="/dev/null") file=""; else { sub(/^b\//,"",p); file=p }; next }
/^@@/ {
  split($2,o,","); split($3,n,",")
  ostart=substr(o[1],2)+0; ocount=(o[2]=="")?1:o[2]+0
  nstart=substr(n[1],2)+0; ncount=(n[2]=="")?1:n[2]+0
  f = (file!="") ? file : dfile
  if (f=="") next
  if (ocount>0) print f "\tLEFT\t" ostart "\t" (ostart+ocount-1)
  if (ncount>0) print f "\tRIGHT\t" nstart "\t" (nstart+ncount-1)
}' "$STATE_DIR/pr.diff" > "$STATE_DIR/hunks.tsv"

cut -f1 "$STATE_DIR/hunks.tsv" | LC_ALL=C sort -u > "$STATE_DIR/files.txt"
FILE_COUNT=$(wc -l < "$STATE_DIR/files.txt")

# Groups: one group unless the PR is large. Split by file, largest-changed-file-first,
# greedily balanced by changed-line volume, so a lens run never splits one file across
# groups and two groups never share a path (no cross-group dedup needed later).
if [ "$FILE_COUNT" -gt 100 ]; then
  awk -F'\t' '$2=="RIGHT"{sum[$1]+=($4-$3+1)} END{for(f in sum) print sum[f]"\t"f}' "$STATE_DIR/hunks.tsv" \
    | LC_ALL=C sort -rn \
    | awk -F'\t' '{if(b1<=b2){print $2"\tG1";b1+=$1}else{print $2"\tG2";b2+=$1}}' > "$STATE_DIR/file-groups.tsv"
else
  awk '{print $0"\tG1"}' "$STATE_DIR/files.txt" > "$STATE_DIR/file-groups.tsv"
fi

PR_GROUPS=$(cut -f2 "$STATE_DIR/file-groups.tsv" | LC_ALL=C sort -u)
for g in $PR_GROUPS; do
  awk -F'\t' -v g="$g" '$2==g{print $1}' "$STATE_DIR/file-groups.tsv" > "$STATE_DIR/files-$g.txt"
  awk -F'\t' -v g="$g" 'NR==FNR{if($2==g)want[$1]=1;next}($1 in want)' \
    "$STATE_DIR/file-groups.tsv" "$STATE_DIR/hunks.tsv" > "$STATE_DIR/hunks-$g.tsv"
done

gh api "repos/$REPO/pulls/$PR_NUM/comments" -H "X-GitHub-Api-Version: 2022-11-28" --paginate \
  --jq '.[] | {path,line,original_line,body:.body[0:200]}' > "$STATE_DIR/existing-comments.jsonl" \
  2>/dev/null || echo -n "" > "$STATE_DIR/existing-comments.jsonl"

echo "REPO=$REPO PR=$PR_NUM HEAD_SHA=$HEAD_SHA BASE_SHA=$BASE_SHA"
echo "STATE_DIR=$STATE_DIR"
echo "files=$FILE_COUNT groups=$(echo "$PR_GROUPS" | tr '\n' ' ')"
