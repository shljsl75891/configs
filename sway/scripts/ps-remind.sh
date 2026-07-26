#!/usr/bin/env bash

URL="https://sourcefuse.peoplestrong.com/oneweb/#/home"
PROFILE="Profile 2"

exec 9>/tmp/ps-remind.lock
flock -n 9 || exit 0

remind() {
    mon=$(mktemp)
    gdbus monitor --session --dest org.freedesktop.Notifications >"$mon" 2>/dev/null &
    monpid=$!

    id=$(gdbus call --session --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        ps-remind 0 alarm-symbolic "$1" "Click to open portal" \
        "['default','Open portal']" "{'urgency': <byte 2>}" 0 \
        | sed -n 's/.*uint32 \([0-9]\+\).*/\1/p')

    for _ in $(seq 1 900); do
        if grep -q "ActionInvoked (uint32 $id, 'default')" "$mon"; then
            swaymsg workspace number 1
            brave-origin --new-window --profile-directory="$PROFILE" "$URL" &
            break
        fi
        sleep 2
    done

    kill "$monpid" 2>/dev/null
    rm -f "$mon"
}

while true; do
    day=$(date +%F); dow=$((10#$(date +%u))); now=$((10#$(date +%H%M)))
    if ((dow <= 5)); then
        if ((now >= 1030 && now < 1500)) && [[ $in_day != "$day" ]]; then
            in_day=$day; remind "Punch In" &
        fi
        if ((now >= 1900 && now < 2359)) && [[ $out_day != "$day" ]]; then
            out_day=$day; remind "Punch Out" &
        fi
    fi
    sleep 60
done
