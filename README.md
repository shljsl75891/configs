# My Dotfiles

```console
git clone --recurse-submodules https://github.com/shljsl75891/configs.git
```

> **History note:** this machine ran Sway (Wayland) for a while. It was abandoned after a
> long-running touchpad/cursor stutter investigation — the root cause turned out to be I²C
> runtime-PM suspending the touchpad's PCI controller (fixed via a udev rule, see
> `/etc/udev/rules.d/90-i2c-no-runtime-pm.rules`), but the stutter persisted under Wayland even
> after that fix. Rather than keep chasing it, the setup moved back to awesome/X11. If you ever
> see `WLR_DRM_NO_ATOMIC` or `WLR_NO_HARDWARE_CURSORS` referenced anywhere, those were dead-end
> Wayland cursor-rendering workarounds from that investigation — not needed on X11, don't
> reintroduce them.

# Dependencies

```console
sudo apt install zsh tmux libx11-dev libxft-dev libxrandr-dev libxinerama-dev build-essential \
  awesome ffmpeg xclip picom brightnessctl pamixer playerctl copyq pcmanfm maim \
  network-manager-gnome bluez xdg-desktop-portal-gtk ghostty \
  qt5ct xsettingsd ydotool tealdeer cmake \
  fd-find x11-utils libnotify-bin blueman alsa-utils
```

`dmenu` and `slock` are vendored as suckless source builds in this repo (`dmenu/`, `slock/`) —
build them yourself, see below.

## Awesome Setup

### Session

At the LightDM login screen, click the session-type gear icon → select **awesome**.

### Symlink configs

```bash
ln -sf ~/personal/configs/awesome        ~/.config/awesome
ln -sf ~/personal/configs/picom          ~/.config/picom
ln -sf ~/personal/configs/qt5ct          ~/.config/qt5ct
ln -sf ~/personal/configs/hyprvoice      ~/.config/hyprvoice
ln -sf ~/personal/configs/X11/xsessionrc ~/.xsessionrc

mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.config/fontconfig
ln -sf ~/personal/configs/gtk-3.0/settings.ini   ~/.config/gtk-3.0/settings.ini
ln -sf ~/personal/configs/gtk-4.0/settings.ini   ~/.config/gtk-4.0/settings.ini
ln -sf ~/personal/configs/fontconfig/fonts.conf   ~/.config/fontconfig/fonts.conf
ln -sf ~/personal/configs/fontconfig/xsettingsd.conf ~/.config/xsettingsd/xsettingsd.conf
fc-cache -f
```

### Cursor theme

GTK apps read `gtk-cursor-theme-name` above, but the root window (desktop background,
awesome's own cursor) falls back to `~/.icons/default/index.theme`. Keep both pointed at the
same theme or you'll get a different cursor over the desktop vs. over windows:

```bash
mkdir -p ~/.icons/default
cat > ~/.icons/default/index.theme << 'EOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Bibata-Modern-Classic
EOF
```

`X11/xsessionrc` (symlinked above) also exports `XCURSOR_THEME`/`XCURSOR_SIZE` so Xlib and Qt
apps agree too. Takes effect on next login.

### Build dmenu and slock

```bash
sudo make -C ~/personal/configs/dmenu install
sudo make -C ~/personal/configs/slock install
```

### Touchpad config

```bash
sudo install -Dm644 ~/personal/configs/awesome/40-touchpad.conf /etc/X11/xorg.conf.d/40-touchpad.conf
```

### Multi-monitor

List outputs:

```bash
xrandr
```

Then set positions, e.g.:

```bash
xrandr --output eDP-1 --primary --auto --output HDMI-1 --auto --right-of eDP-1
```

### Voice Dictation (hyprvoice)

Voice-to-text via [hyprvoice](https://github.com/leonardotrapani/hyprvoice) + Groq cloud (whisper-large-v3-turbo, ~200ms latency). Injects text via `ydotool` (uinput-based, works under X11).

**One-time setup on a fresh machine:**

```bash
# 1. Install binary
mkdir -p ~/.local/bin
wget -O ~/.local/bin/hyprvoice \
  https://github.com/leonardotrapani/hyprvoice/releases/download/v1.0.2/hyprvoice-linux-x86_64
chmod +x ~/.local/bin/hyprvoice

# 2. Install ydotool and start its daemon (needs /dev/uinput access via the `input` group)
sudo apt install ydotool
sudo usermod -aG input "$USER"   # log out/in to pick up the group
systemctl --user enable --now ydotool.service

# 3. Install systemd user service for hyprvoice
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/hyprvoice.service << 'EOF'
[Unit]
Description=hyprvoice voice-to-text daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/hyprvoice serve
Restart=on-failure
RestartSec=3
PassEnvironment=XDG_RUNTIME_DIR XDG_SESSION_TYPE DISPLAY

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

# 4. Set Groq API key (get free key at console.groq.com)
#    Add to ~/.zshenv:
#      export GROQ_API_KEY=gsk_...
#    Then inject into the service:
mkdir -p ~/.config/systemd/user/hyprvoice.service.d
cat > ~/.config/systemd/user/hyprvoice.service.d/env.conf << 'EOF'
[Service]
Environment=GROQ_API_KEY=<your-key-here>
EOF

# 5. Enable and start
systemctl --user daemon-reload
systemctl --user enable --now hyprvoice
```

Config lives at `~/.config/hyprvoice/config.toml` — `[injection] backends = ["ydotool"]`,
`ydotool_timeout = "30s"` (default 3s is too short and kills mid-injection on longer
transcriptions).

**Usage:**

- `Super+d` — start recording (speak); press again to stop and transcribe → text injected at cursor
- `Super+Shift+d` — cancel/discard

## Screen Capture

- `Super+s` — maim region capture piped to the clipboard, with a notify-send on completion.
- `Super+Shift+s` — toggles screen recording (`awesome/scripts/recording.sh`, ffmpeg x11grab).
  Saves to `~/Videos/Recordings/`, with a notify-send on start/stop.

## Fix Screen Tearing (X11)

##### Keep `vsync` on

In `picom/picom.conf`:

```bash
vsync = true;
```

#### Intel / AMD X11 Config

File to Edit/Add: `/etc/X11/xorg.conf.d/20-intel.conf` or `20-amd.conf`

```xf86conf
Section "Device"
    Identifier  "Intel Graphics" / "AMD Graphics"
    Driver      "intel" / "amdgpu"
    Option      "DRI"  "3"
    Option      "Backlight"  "intel_backlight"
    Option      "TearFree" "true"
EndSection
```

Note: There are extra options that can help like: Option "AccelMethod" "uxa" or Option "TripleBuffer" "true"

#### Set Default Applications

Edit `~/.config/mimeapps.list` to set per-MIME defaults (e.g. `pcmanfm` for directories, `nvim` for text).

## Screenshots

#### Awesome WM

![](/assets/2025-05-14-06-57-57.png)

![](/assets/2025-05-14-06-58-17.png)
