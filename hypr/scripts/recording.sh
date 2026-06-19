#!/usr/bin/env bash
# recording.sh — toggle full-screen recording
pidfile=/tmp/recording.pid

if [ -f "$pidfile" ]; then
    kill "$(cat "$pidfile")"
    rm "$pidfile"
    notify-send "Recording stopped"
else
    file=~/Videos/Recordings/$(date +%F_%H-%M-%S).mp4
    mkdir -p ~/Videos/Recordings
    wf-recorder -f "$file" &
    echo $! > "$pidfile"
    notify-send "Recording started" "$file"
fi
