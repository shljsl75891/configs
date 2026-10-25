#!/bin/sh
# wmenu with gruvbox look; usage: menu.sh [wmenu args]; run: menu.sh -r
if [ "$1" = -r ]; then shift; exec wmenu-run -f 'NotoSans Nerd Font 10' -N 1d2021 -n d4be98 -S 689d6a -s 1d2021 -M 689d6a -m 1d2021 "$@"; fi
exec wmenu -i -f 'NotoSans Nerd Font 10' -N 1d2021 -n d4be98 -S 689d6a -s 1d2021 -M 689d6a -m 1d2021 "$@"
