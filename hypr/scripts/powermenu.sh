#!/usr/bin/env bash
# powermenu.sh — replaces logout-menu-widget (awesome/bar.lua)
# Preserves the punch-out mpv reminder on poweroff (autostart.sh behaviour)
# Requires: rofi, hyprlock, hyprctl, mpv, systemctl

LOCK="  Lock"
LOGOUT="  Logout"
REBOOT="  Reboot"
POWEROFF="  Poweroff"

CHOICE=$(printf "%s\n%s\n%s\n%s" "$LOCK" "$LOGOUT" "$REBOOT" "$POWEROFF" \
    | rofi \
        -dmenu \
        -i \
        -p "Power" \
        -theme-str 'window { width: 220px; }' \
        -no-custom)

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
