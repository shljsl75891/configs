#!/usr/bin/env bash
# Waybar custom module: attendance status as JSON.
# Red: no punch today or the user must act. Orange: punched in. Yellow: punched out.

dir=$(dirname "$(readlink -f "$0")")
status=$("$dir/peoplestrong/mark-attendance" status 2>/dev/null)

if [[ $status =~ ^([0-9]{2}:[0-9]{2})→(.*)$ ]]; then
	from=${BASH_REMATCH[1]}
	to=${BASH_REMATCH[2]}
	[[ $to =~ ^[0-9]{2}:[0-9]{2}$ ]] && class=out || class=in
	[[ $class == out ]] && text="$from    $to" || text="$from    --"
else
	class=none text="Attendance"
fi

jq -nc --arg text "󱑆 $text" --arg class "$class" \
	'{text:$text, class:$class}'
