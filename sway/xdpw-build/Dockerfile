FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive
ARG XDPW_TAG=v0.8.2
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources \
  && apt-get update && apt-get install -y git ca-certificates \
  meson ninja-build pkg-config scdoc dpkg-dev \
  && apt-get build-dep -y xdg-desktop-portal-wlr
RUN git clone --depth 1 --branch ${XDPW_TAG} https://github.com/emersion/xdg-desktop-portal-wlr /src
WORKDIR /src
RUN meson setup build --prefix=/usr --libexecdir=libexec && ninja -C build
RUN DESTDIR=/pkg ninja -C build install
# Runtime deps: those of apt's package. Higher version replaces distro 0.8.1.
RUN apt-cache depends xdg-desktop-portal-wlr | awk '/^  Depends:/ {print $2}' | paste -sd, > /deps
RUN mkdir /pkg/DEBIAN && printf '%s\n' \
  "Package: xdg-desktop-portal-wlr" "Version: ${XDPW_TAG#v}" "Architecture: $(dpkg --print-architecture)" \
  "Maintainer: local <local@localhost>" "Depends: $(cat /deps)" \
  "Description: xdg-desktop-portal backend for wlroots (local upstream build)" > /pkg/DEBIAN/control \
  && dpkg-deb --build /pkg /xdg-desktop-portal-wlr_${XDPW_TAG#v}_amd64.deb
