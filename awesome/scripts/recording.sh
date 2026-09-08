#!/usr/bin/env bash
# Toggle screen recording via ffmpeg x11grab.

pidfile="${XDG_RUNTIME_DIR:-/tmp}/recording.pid"

is_our_recording() {
	local pid="$1"
	[[ "$pid" =~ ^[0-9]+$ ]] || return 1
	kill -0 "$pid" 2>/dev/null || return 1
	grep -qa "ffmpeg" "/proc/$pid/cmdline" 2>/dev/null
}

stopped=0
if [ -f "$pidfile" ]; then
	pid=$(cat "$pidfile")
	if is_our_recording "$pid"; then
		kill "$pid"
		notify-send "Recording" "Recording stopped"
		stopped=1
	fi
	rm -f "$pidfile"
fi

if [ "$stopped" -eq 0 ]; then
	geometry=$(xdpyinfo | awk '/dimensions:/ {print $2}')
	file="$HOME/Videos/Recordings/$(date +%F_%H-%M-%S).mp4"
	mkdir -p "$(dirname "$file")"
	ffmpeg -loglevel error -vaapi_device /dev/dri/renderD128 \
		-f x11grab -framerate 60 -video_size "$geometry" -i "${DISPLAY:-:0}" \
		-vf 'format=nv12,hwupload' -c:v h264_vaapi -qp 20 \
		"$file" &
	echo $! >"$pidfile"
	notify-send "Recording" "Recording started: $file"
fi
