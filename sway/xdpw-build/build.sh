#!/bin/sh
# Build upstream xdg-desktop-portal-wlr .deb in docker; output to ./out. Then:
#   sudo apt install ./out/xdg-desktop-portal-wlr_*.deb
# Needed: Ubuntu 26.04 ships 0.8.1, where single-window capture crashes (LP #2159516).
set -e
cd "$(dirname "$0")"
docker build -t xdpw-build .
mkdir -p out
docker run --rm -v "$PWD/out:/out" xdpw-build sh -c 'cp /xdg-desktop-portal-wlr_*.deb /out/'
dpkg-deb -I out/xdg-desktop-portal-wlr_*.deb
dpkg-deb -c out/xdg-desktop-portal-wlr_*.deb
