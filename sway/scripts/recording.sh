#!/usr/bin/env bash
# Toggle screen recording via wf-recorder with VAAPI hardware encode.

pidfile="${XDG_RUNTIME_DIR:-/tmp}/recording.pid"

is_our_recording() {
	local pid="$1"
	[[ "$pid" =~ ^[0-9]+$ ]] || return 1
	kill -0 "$pid" 2>/dev/null || return 1
	grep -qa "wf-recorder" "/proc/$pid/cmdline" 2>/dev/null
}

stopped=0
if [ -f "$pidfile" ]; then
	pid=$(cat "$pidfile")
	if is_our_recording "$pid"; then
		# SIGINT lets wf-recorder finish the mp4 file.
		kill -INT "$pid"
		notify-send "Recording" "Recording stopped"
		stopped=1
	fi
	rm -f "$pidfile"
fi

if [ "$stopped" -eq 0 ]; then
	file="$HOME/Videos/Recordings/$(date +%F_%H-%M-%S).mp4"
	mkdir -p "$(dirname "$file")"
	wf-recorder -c h264_vaapi -d /dev/dri/renderD128 -f "$file" &
	pid=$!
	sleep 1
	if kill -0 "$pid" 2>/dev/null; then
		echo "$pid" >"$pidfile"
		notify-send "Recording" "Recording started: $file"
	else
		notify-send -u critical "Recording" "wf-recorder failed to start"
	fi
fi
