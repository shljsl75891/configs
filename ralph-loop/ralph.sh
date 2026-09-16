#!/usr/bin/env bash

set -euo pipefail

RALPH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PI_CODING_AGENT_DIR="${RALPH_DIR%/*}/pi-yolo"

[ -f PROMPT.md ] || { echo "PROMPT.md missing in $PWD" >&2; exit 1; }
[ -f TODO.md ] || { echo "TODO.md missing in $PWD" >&2; exit 1; }

while :; do
  pi -p "$(cat PROMPT.md)" --approve | tee -a ralph.log

  if ! grep -qi '| *queued *|' TODO.md; then
    echo "No queued tasks remaining in TODO.md. Stopping." | tee -a ralph.log
    break
  fi

  sleep 5
done
