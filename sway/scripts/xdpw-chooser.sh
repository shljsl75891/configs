#!/bin/sh
# xdpw dmenu chooser. Chromium asks twice (preview, then real share);
# replay the last pick once within TTL so the menu shows only once.
c="${XDG_RUNTIME_DIR:-/tmp}/xdpw-choice"
ttl=60
in=$(cat)
if [ -f "$c" ] && [ $(( $(date +%s) - $(stat -c %Y "$c") )) -lt $ttl ]; then
	prev=$(cat "$c"); rm -f "$c"
	case $prev in
		"Window: "*) hit=$(printf '%s\n' "$in" | grep -F -- " (${prev##* (}" | head -n1) ;;
		*)           hit=$(printf '%s\n' "$in" | grep -Fx -- "$prev") ;;
	esac
	[ -n "$hit" ] && { printf '%s\n' "$hit"; exit 0; }
fi
choice=$(printf '%s\n' "$in" | "$(dirname "$0")/menu.sh" -b -l 10) || exit 1
[ -n "$choice" ] && printf '%s\n' "$choice" > "$c"
printf '%s\n' "$choice"
