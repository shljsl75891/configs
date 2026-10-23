#!/usr/bin/env bash
# Usage: lint.sh [file]   (reads stdin when no file)
# Prints hits as "line: kind: text". Exit 1 when any hit.
set -u
tier1='delve|utilize|utilise|leverage|leveraging|facilitate|elucidate|embark|endeavor|encompass|multifaceted|tapestry|testament|paradigm|synergy|holistic|catalyze|juxtapose|realm|myriad|plethora|ever-evolving|crucial|additionally|garner|interplay|intricate|pivotal|showcase|underscore|vibrant|fostering'
filler="it's worth noting that|it's important to note that|importantly|notably|interestingly|in order to|due to the fact that|let's dive in|here's the kicker"
src=$(cat "${1:-/dev/stdin}")
hits=$(
  {
    grep -inoE "\b($tier1)\b" <<<"$src" | sed 's/:/: tier1: /'
    grep -inoE "($filler)" <<<"$src" | sed 's/:/: filler: /'
    grep -n '—' <<<"$src" | sed 's/:/: em-dash: /'
    grep -nE '[“”‘’]' <<<"$src" | sed 's/:/: curly-quote: /'
  } | sort -t: -k1,1n
)
words=$(wc -w <<<"$src")
count=$(grep -c . <<<"$hits")
[ -n "$hits" ] && printf '%s\n' "$hits"
echo "hits: $count / words: $words"
[ -z "$hits" ]
