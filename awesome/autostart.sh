#!/usr/bin/env bash
# Autostart for awesome (X11).

# Start $1 only if it is not already running.
run_once() {
  local cmd="$1"
  local bin="${cmd%% *}"
  command -v "$bin" >/dev/null 2>&1 || return 0
  pgrep -u "$USER" -fx "$cmd" >/dev/null 2>&1 || $cmd &
}

# Compositor — X11 has none built in, unlike sway. Needed for the 0.95 window
# opacity set in rc.lua's default rule, and to stop screen tearing.
run_once "picom"

run_once "nm-applet --indicator"
run_once "blueman-applet"
run_once "copyq"
run_once "xsettingsd"
