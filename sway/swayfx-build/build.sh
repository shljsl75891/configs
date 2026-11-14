#!/bin/sh
# Build swayfx .deb in docker; output to ./out. Then:
#   sudo apt install ./out/swayfx_*.deb   (replaces apt sway; waybar/swaybg stay)
set -e
cd "$(dirname "$0")"
docker build -t swayfx-build .
mkdir -p out
docker run --rm -v "$PWD/out:/out" swayfx-build sh -c 'cp /swayfx_*.deb /out/'
dpkg-deb -I out/swayfx_*.deb
