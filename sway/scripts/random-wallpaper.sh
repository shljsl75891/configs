#!/usr/bin/env bash

LOCKFILE="/tmp/random-wallpaper.lock"
exec 200>"$LOCKFILE"
flock -n 200 || exit 0

WALLPAPER_DIR="$HOME/gitprojects/wallpapers"

swaybg -i $(find $WALLPAPER_DIR -type f -path '*.jpg' | shuf -n1) -m stretch &
OLD_PID=$!
while true; do
    sleep 3600
    swaybg -i $(find $WALLPAPER_DIR -type f -path '*.jpg' | shuf -n1) -m stretch &
    NEXT_PID=$!
    sleep 5
    kill $OLD_PID
    OLD_PID=$NEXT_PID
done
