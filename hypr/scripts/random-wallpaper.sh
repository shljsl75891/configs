#!/usr/bin/env bash
# random-wallpaper.sh — replaces nitrogen --set-scaled --random
# Requires: swaybg

WALLPAPER_DIR="$HOME/gitprojects/wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper dir not found: $WALLPAPER_DIR" >&2
    exit 1
fi

WALL=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)

if [ -z "$WALL" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

# Kill any existing swaybg instance before spawning a new one
pkill -x swaybg 2>/dev/null; sleep 0.1

swaybg -i "$WALL" -m stretch &
