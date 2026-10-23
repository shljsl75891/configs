#!/usr/bin/env bash
# Emits waybar custom-module JSON: current date/time text + cal -3 style
# 3-month tooltip, today's date highlighted via reverse-video (pty forces
# ncal to emit the same ANSI reverse-video it would in a real terminal).
text=$(date '+%a %d %B %Y  %I:%M %p')
raw=$(TERM=xterm script -qc "ncal -C -3" /dev/null | tr -d '\r')
escaped=$(printf '%s' "$raw" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
today=$(printf '%s' "$escaped" | perl -pe 's/\x1b\[7m(.*?)\x1b\[27m/<span background="#d4be98" foreground="#1d2021">$1<\/span>/g')
jq -nc --arg text "$text" --arg tooltip "<tt>${today}</tt>" '{text:$text, tooltip:$tooltip}'
