#!/usr/bin/env bash
# pr-reviewer: RE-REVIEW mechanics — fetch review threads, reply to one, resolve one.
# Usage:
#   scripts/threads.sh fetch   <pr-number>
#   scripts/threads.sh reply   <pr-number> <thread-id> <body-file>
#   scripts/threads.sh resolve <pr-number> <thread-id>
# Precondition: cwd is inside a clone of the PR's own repo (same rule as prepare.sh).
# Reply before a pending review exists: a reply sent while one exists joins that pending review.
set -euo pipefail

CMD="${1:?usage: threads.sh fetch|reply|resolve <pr-number> ...}"
PR_NUM="${2:?usage: threads.sh $CMD <pr-number> ...}"
PR_NUM="${PR_NUM//[^0-9]/}"   # keep digits only: users may type "#N" or "N,"
[ -n "$PR_NUM" ] || { echo "ERROR: PR number has no digits: '$2'" >&2; exit 1; }

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/pr-review/${REPO//\//-}-${PR_NUM}"
mkdir -p "$STATE_DIR"
GH_VER=(-H "X-GitHub-Api-Version: 2022-11-28")

case "$CMD" in
  fetch)
    gh api graphql "${GH_VER[@]}" --paginate \
      -F owner="${REPO%/*}" -F name="${REPO#*/}" -F pr="$PR_NUM" -f query='
      query($owner:String!,$name:String!,$pr:Int!,$endCursor:String){
        repository(owner:$owner,name:$name){pullRequest(number:$pr){
          reviewThreads(first:100,after:$endCursor){pageInfo{hasNextPage endCursor}
            nodes{id isResolved isOutdated path line originalLine
              comments(first:50){nodes{databaseId author{login} body createdAt}}}}}}}' \
      | jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[]]' > "$STATE_DIR/threads.json"
    jq -r '"threads=\(length) unresolved=\([.[]|select(.isResolved|not)]|length) outdated_unresolved=\([.[]|select((.isResolved|not) and .isOutdated)]|length)",
      "unresolved by starter: \([.[]|select(.isResolved|not)|.comments.nodes[0].author.login]|group_by(.)|map("\(.[0])=\(length)")|join(" "))"' \
      "$STATE_DIR/threads.json"
    echo "THREADS=$STATE_DIR/threads.json"
    ;;
  reply)
    THREAD="${3:?usage: threads.sh reply <pr-number> <thread-id> <body-file>}"
    BODY_FILE="${4:?usage: threads.sh reply <pr-number> <thread-id> <body-file>}"
    gh api graphql "${GH_VER[@]}" -f t="$THREAD" -F b=@"$BODY_FILE" -f query='
      mutation($t:ID!,$b:String!){addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$t,body:$b}){comment{state url}}}' \
      --jq '.data.addPullRequestReviewThreadReply.comment | "\(.state) \(.url)"'
    sleep 1.2   # GitHub: >=1s between mutative requests; 80 content items/min
    ;;
  resolve)
    THREAD="${3:?usage: threads.sh resolve <pr-number> <thread-id>}"
    gh api graphql "${GH_VER[@]}" -f t="$THREAD" -f query='
      mutation($t:ID!){resolveReviewThread(input:{threadId:$t}){thread{isResolved}}}' \
      --jq '"resolved=\(.data.resolveReviewThread.thread.isResolved)"'
    sleep 1.2
    ;;
  *) echo "ERROR: unknown command '$CMD' (fetch|reply|resolve)" >&2; exit 1 ;;
esac
