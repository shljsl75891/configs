FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive
ARG SWAYFX_TAG=0.6.1
ARG WLROOTS_TAG=0.20.2
ARG SCENEFX_TAG=0.5
# Build deps = those of the distro sway/wlroots packages, plus tools to pack a deb.
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources \
 && apt-get update && apt-get install -y git ca-certificates \
    meson ninja-build pkg-config scdoc dpkg-dev \
 && apt-get build-dep -y sway wlroots
# swayfx 0.6 needs wlroots 0.20 and scenefx 0.5 (no distro packages). Install
# them to the image for the build and into the deb. Distro libwlroots-0.19 is untouched.
RUN git clone --depth 1 --branch ${WLROOTS_TAG} https://gitlab.freedesktop.org/wlroots/wlroots.git /wlroots \
 && cd /wlroots && meson setup build --prefix=/usr && ninja -C build \
 && ninja -C build install && DESTDIR=/pkg ninja -C build install
RUN git clone --depth 1 --branch ${SCENEFX_TAG} https://github.com/wlrfx/scenefx /scenefx \
 && cd /scenefx && meson setup build --prefix=/usr && ninja -C build \
 && ninja -C build install && DESTDIR=/pkg ninja -C build install
RUN git clone --depth 1 --branch ${SWAYFX_TAG} https://github.com/WillPower3309/swayfx /src
WORKDIR /src
RUN meson setup build --prefix=/usr -Dsd-bus-provider=libsystemd && ninja -C build
RUN DESTDIR=/pkg ninja -C build install
# Runtime deps: those of apt's sway, minus wlroots (bundled).
RUN apt-cache depends sway | awk '/Depends:/ {print $2}' | grep -v -e '^<' -e wlroots | paste -sd, > /deps
RUN mkdir /pkg/DEBIAN && printf '%s\n' \
  "Package: swayfx" "Version: ${SWAYFX_TAG}" "Architecture: $(dpkg --print-architecture)" \
  "Maintainer: local <local@localhost>" "Provides: sway" "Conflicts: sway" "Replaces: sway" \
  "Depends: $(cat /deps),libxcb-errors0" "Description: SwayFX, sway with eye candy" > /pkg/DEBIAN/control \
 && dpkg-deb --build /pkg /swayfx_${SWAYFX_TAG}_amd64.deb
