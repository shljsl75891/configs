#!/usr/bin/env bash
# screenshot.sh — replaces: maim -sDo | xclip -selection clipboard -t image/png
# Requires: grim, slurp, wl-clipboard

grim -g "$(slurp)" - | wl-copy -t image/png
