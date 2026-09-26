#!/usr/bin/env bash

set -euo pipefail

[ -f PROMPT.md ] || { echo "PROMPT.md missing in $PWD" >&2; exit 1; }
[ -f TODO.md ] || { echo "TODO.md missing in $PWD" >&2; exit 1; }

# Writes only the final assistant answer of each iteration to ralph.log.
LOG_FILTER='
  if .type == "agent_end" then
    ( .messages | map(select(.role == "assistant")) | last ) as $m
    | ( ($m.content // []) | map(select(.type == "text") | .text) | join("\n") ) as $t
    | if ($t | length) > 0 then $t + "\n" else empty end
  else empty end
'

# Live terminal view: whole text blocks, one line per tool call (no blank
# lines between calls), dimmed 5-line tool-result preview, red on error,
# a [done] footer per iteration.
DISPLAY_FILTER='
  if .type == "message_end" and .message.role == "assistant" then
    (.message.content // [])[]
    | if .type == "text" then
        "\(.text)\n"
      elif .type == "toolCall" then
        (.arguments // {}) as $a
        | (if .name == "bash" then ($a.command // "")
           else ($a.path // $a.file_path // $a.filePath // $a.name // "")
           end) as $target
        | "\u001b[35m\u25b6 [\(.name)]\(if $target != "" then " " + $target else "" end)\u001b[0m"
      else empty end
  elif .type == "message_end" and .message.role == "toolResult" then
    ( (.message.content // []) | map(select(.type == "text") | .text) | join("\n") | rtrimstr("\n") ) as $out
    | ( $out | split("\n") | .[0:3] | map("    " + .) | join("\n") ) as $preview
    | ( if ($out | length) > 0 then "\u001b[90m\($preview)\u001b[0m" else empty end ),
      ( if .message.isError then "\u001b[31m    error\u001b[0m" else empty end )
  elif .type == "agent_end" then
    ( .messages | map(select(.role == "assistant")) ) as $asst
    | ( $asst | length ) as $turns
    | ( [$asst[].usage.totalTokens // 0] | add // 0 ) as $tokens
    | "\u001b[90m[done] \($turns) turns, \($tokens) tokens\u001b[0m\n"
  else empty end
'

while :; do
  pi --no-session --mode json --approve "$(cat PROMPT.md)" \
    | tee >(jq -r "$LOG_FILTER" >> ralph.log) \
    | jq --unbuffered -r "$DISPLAY_FILTER"

  if ! grep -qi '| *queued *|' TODO.md; then
    echo "No queued tasks remaining in TODO.md. Stopping." | tee -a ralph.log
    break
  fi

  sleep 5
done
