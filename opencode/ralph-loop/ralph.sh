#!/usr/bin/env bash

set -euo pipefail

AGENT="${1:-build}"

[ -f PROMPT.md ] || { echo "PROMPT.md missing in $PWD" >&2; exit 1; }
[ -f TODO.md ] || { echo "TODO.md missing in $PWD" >&2; exit 1; }

while :; do
  opencode run "$(cat PROMPT.md)" --agent "$AGENT" --auto | tee -a ralph.log

  if ! grep -qi '| *queued *|' TODO.md; then
    echo "No queued tasks remaining in TODO.md. Stopping." | tee -a ralph.log
    break
  fi

  sleep 5
done
