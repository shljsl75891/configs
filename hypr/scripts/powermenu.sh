#!/usr/bin/env bash
# powermenu.sh — replaces logout-menu-widget (awesome/bar.lua)
# Preserves the punch-out mpv reminder on poweroff (autostart.sh behaviour)
# Requires: wofi, hyprlock, hyprctl, mpv, systemctl

LOCK="  Lock"
LOGOUT="  Logout"
REBOOT="  Reboot"
POWEROFF="  Poweroff"

CHOICE=$(printf "%s\n%s\n%s\n%s" "$LOCK" "$LOGOUT" "$REBOOT" "$POWEROFF" \
    | wofi \
        --dmenu \
        --insensitive \
        --prompt "Power" \
        --width 220 \
        --height 186 \
        --cache-file /dev/null)

case "$CHOICE" in
    "$LOCK")
        hyprlock
        ;;
    "$LOGOUT")
        hyprctl dispatch exit
        ;;
    "$REBOOT")
        systemctl reboot
        ;;
    "$POWEROFF")
        # Punch-out reminder (mirrors autostart.sh onpoweroff behaviour)
        mpv --no-resume-playback "$HOME/personal/configs/mpv/sound.mp3" &
        sleep 6
        systemctl poweroff
        ;;
esac
