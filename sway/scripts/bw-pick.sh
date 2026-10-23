#!/usr/bin/env bash
set -euo pipefail
rbw unlocked >/dev/null 2>&1 || rbw unlock
sel=$(rbw list --fields name,user | fuzzel --dmenu --prompt 'bw> ') || exit 0
name=${sel%%$'\t'*}; user=${sel#*$'\t'}; [[ $user == "$sel" ]] && user=
rbw get "$name" ${user:+"$user"} | wl-copy
(sleep 10; wl-copy --clear) >/dev/null 2>&1 &
