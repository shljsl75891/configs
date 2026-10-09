#!/usr/bin/env bash
# Linux: authorize the first USB device blocked by Scalefusion tux-agent
# (authorized_default=0). Run BEFORE plugging in; blocked devices drop ~4s after attach.
# Usage: usb-authorize (self-elevates via sudo)

[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

# 1200 x 0.05s = ~60s
for _ in $(seq 1 1200); do
  for f in /sys/bus/usb/devices/*/authorized; do
    d=${f%/authorized}
    # skip interfaces (1-2:1.0) and root hubs (usbN)
    case "$d" in *:*|*/usb[0-9]*) continue ;; esac
    if [ "$(cat "$f")" = 0 ]; then
      echo 1 >"$f" && echo "authorized $d"
      exit 0
    fi
  done
  sleep 0.05
done
echo "timeout: no blocked device seen" >&2
exit 1
