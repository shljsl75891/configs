# My Dotfiles

```console
git clone --recurse-submodules https://github.com/shljsl75891/configs.git
```

> **History note:** this machine ran Sway, moved to awesome/X11 because of a touchpad/cursor
> stutter (root cause partly fixed by an I²C runtime-PM udev rule,
> `/etc/udev/rules.d/90-i2c-no-runtime-pm.rules`), then came back to Sway because the stutter
> also happened on X11. If you see `WLR_DRM_NO_ATOMIC` or `WLR_NO_HARDWARE_CURSORS` anywhere,
> those were dead-end workarounds from that investigation. Do not reintroduce them.

# Dependencies

```console
sudo apt install zsh tmux sway waybar mako-notifier wmenu swaylock swaybg grim slurp \
  wf-recorder wl-clipboard ffmpeg brightnessctl playerctl copyq pcmanfm \
  network-manager-gnome bluez blueman xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
  ghostty qt5ct wtype jq ncal tealdeer cmake libnotify-bin intel-media-va-driver-non-free vainfo
```

## Sway Setup

### Session

At the LightDM login screen, click the session-type gear icon → select **sway**.

### Symlink configs

```bash
ln -sfn ~/personal/configs/sway    ~/.config/sway
ln -sfn ~/personal/configs/waybar  ~/.config/waybar
ln -sfn ~/personal/configs/mako    ~/.config/mako
ln -sfn ~/personal/configs/qt5ct   ~/.config/qt5ct
ln -sfn ~/personal/configs/hyprvoice ~/.config/hyprvoice

mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.config/fontconfig
ln -sfn ~/personal/configs/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini
ln -sfn ~/personal/configs/gtk-4.0/settings.ini ~/.config/gtk-4.0/settings.ini
ln -sfn ~/personal/configs/fontconfig/fonts.conf ~/.config/fontconfig/fonts.conf
fc-cache -f

# Sway has no env directive. LightDM reads ~/.profile before it starts the session.
echo '. ~/.config/sway/env' >> ~/.profile
```

### Input

`sway/config` sets the touchpad and mouse (`input type:touchpad`, `input type:pointer`).
`scroll_factor` sets the scroll speed: 1 is normal, higher is faster. Use
`swaymsg -t get_inputs` to see device names if you need a per-device block.

### Multi-monitor

```bash
swaymsg -t get_outputs
swaymsg output HDMI-A-1 pos 1920 0
```


### Voice Dictation (hyprvoice)

Voice-to-text via [hyprvoice](https://github.com/leonardotrapani/hyprvoice) + Groq cloud (whisper-large-v3-turbo, ~200ms latency). Injects text via `wtype` (native Wayland, fast).

**One-time setup on a fresh machine:**

```bash
# 1. Install binary
mkdir -p ~/.local/bin
wget -O ~/.local/bin/hyprvoice \
  https://github.com/leonardotrapani/hyprvoice/releases/download/v1.0.2/hyprvoice-linux-x86_64
chmod +x ~/.local/bin/hyprvoice

# 2. wtype is installed with the dependencies above

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
PassEnvironment=XDG_RUNTIME_DIR WAYLAND_DISPLAY

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

Config lives at `~/.config/hyprvoice/config.toml` — `[injection] backends = ["wtype"]`.
`sway/config` imports `WAYLAND_DISPLAY` into the systemd user manager and restarts hyprvoice on
each sway start. Without it, wtype fails with "WAYLAND_DISPLAY not set".

**Usage:**

- `Super+d` — start recording (speak); press again to stop and transcribe → text injected at cursor
- `Super+Shift+d` — cancel/discard

## Screen Capture

- `Super+s` — `grim` + `slurp` region capture piped to the clipboard, with a notify-send on completion.
- `Super+Shift+s` — toggles screen recording (`sway/scripts/recording.sh`, `wf-recorder` with
  VAAPI hardware encoding via the Intel iGPU). Saves to `~/Videos/Recordings/`, with a
  notify-send on start/stop.

#### Set Default Applications

Edit `~/.config/mimeapps.list` to set per-MIME defaults (e.g. `pcmanfm` for directories, `nvim` for text).

## pi extension tests

Some extensions under `pi/extensions/` ship `*.test.ts` files. They use Node's built-in test
runner and its native type stripping, so there is nothing to install:

```bash
node --test pi/extensions/question-tool/*.test.ts
```

Run them from a directory where `@earendil-works/pi-tui` resolves if a test imports an extension
entry point.

## Screenshots

#### Previous setup (Awesome WM)

![](/assets/2025-05-14-06-57-57.png)

![](/assets/2025-05-14-06-58-17.png)
