# My Dotfiles

```console
git clone --recurse-submodules https://github.com/shljsl75891/configs.git
```

# Dependencies

### Awesome WM (X11 — legacy)

```console
zsh tmux libx11-dev libxft-dev libxrandr-dev libxinerama-dev build-essential awesome maim ffmpegthumbnailer mpv cmake
```

### Sway (Wayland — Ubuntu 26.04+)

```console
sudo apt install sway waybar grim slurp wl-clipboard wtype swaybg swaylock \
  mako-notifier brightnessctl pamixer playerctl copyq pcmanfm \
  network-manager-gnome bluez xdg-desktop-portal-gtk ghostty \
  qt5ct xsettingsd autotiling wmenu
```

## Sway Setup (Ubuntu 26.04 / Wayland)

### Session

Log out of GNOME → at GDM login screen, click the gear icon → select **Sway**.
Sway cannot be launched from inside a running GNOME session.

### Symlink configs

```bash
ln -sf ~/personal/configs/sway       ~/.config/sway
ln -sf ~/personal/configs/swaylock   ~/.config/swaylock
ln -sf ~/personal/configs/waybar     ~/.config/waybar
ln -sf ~/personal/configs/mako       ~/.config/mako
ln -sf ~/personal/configs/qt5ct      ~/.config/qt5ct
ln -sf ~/personal/configs/hyprvoice  ~/.config/hyprvoice

mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.config/fontconfig
ln -sf ~/personal/configs/gtk-3.0/settings.ini   ~/.config/gtk-3.0/settings.ini
ln -sf ~/personal/configs/gtk-4.0/settings.ini   ~/.config/gtk-4.0/settings.ini
ln -sf ~/personal/configs/fontconfig/fonts.conf   ~/.config/fontconfig/fonts.conf
ln -sf ~/personal/configs/fontconfig/xsettingsd.conf ~/.config/xsettingsd/xsettingsd.conf
fc-cache -f
```

### Multi-monitor (Wayland)

List outputs:

```bash
swaymsg -t get_outputs
```

Edit `sway/config` — replace the generic output line with explicit entries:

```
output eDP-1    resolution 1920x1080 position 0,0    scale 1
output HDMI-A-1 resolution 1920x1080 position 1920,0 scale 1
```

### Voice Dictation (hyprvoice)

Voice-to-text via [hyprvoice](https://github.com/leonardotrapani/hyprvoice) + Groq cloud (whisper-large-v3-turbo, ~200ms latency).

**One-time setup on a fresh machine:**

```bash
# 1. Install binary
wget -O ~/.local/bin/hyprvoice \
  https://github.com/leonardotrapani/hyprvoice/releases/download/v1.0.2/hyprvoice-linux-x86_64
chmod +x ~/.local/bin/hyprvoice

# 2. Install systemd user service
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
PassEnvironment=WAYLAND_DISPLAY XDG_RUNTIME_DIR XDG_SESSION_TYPE DISPLAY

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

# 3. Set Groq API key (get free key at console.groq.com)
#    Add to ~/.zshenv:
#      export GROQ_API_KEY=gsk_...
#    Then inject into the service:
mkdir -p ~/.config/systemd/user/hyprvoice.service.d
cat > ~/.config/systemd/user/hyprvoice.service.d/env.conf << 'EOF'
[Service]
Environment=GROQ_API_KEY=<your-key-here>
EOF

# 4. Enable and start
systemctl --user daemon-reload
systemctl --user enable --now hyprvoice
```

**Usage:**
- `Super+d` — start recording (speak); press again to stop and transcribe → text injected at cursor
- `Super+Shift+d` — cancel/discard

### Cursor Smoothness Fix (Wayland vs X11)

wlroots uses atomic KMS commits, coupling the cursor plane to compositor frame timing. X11 moves the cursor via an unsynchronized DRM ioctl — hence the difference. Fix: disable atomic KMS.

Add to `/etc/environment` (requires sudo, read by PAM for all sessions including lightdm):

```sh
WLR_DRM_NO_ATOMIC=1
```

Add to `sway/config`:

```conf
input type:pointer {
    accel_profile flat
    pointer_accel 0
}

output * max_render_time off
```

Reboot for `/etc/environment` to take effect. Verify the var is live in Sway's process:

```bash
cat /proc/$(pidof sway)/environ | tr '\0' '\n' | grep WLR
```

> Note: `~/.config/environment.d/` is loaded by systemd user manager but **not** inherited by Sway when launched via lightdm. `/etc/environment` is the reliable path.

### Caveats vs Hyprland / Awesome WM

- **No blur or rounded corners**: standard Sway has none; use SwayFX fork if needed.
- **No maximize**: Sway has no native maximize command; `Super+f` toggles fullscreen.
- **autotiling for layout**: master-stack behavior via the `autotiling` script (alternating splits).
- **No pin/always-on-top**: Sway has no equivalent; use `sticky toggle` to make a window visible on all workspaces.
- **picom not needed**: Sway is its own Wayland compositor.
- **Touchpad config**: managed via `input type:touchpad {}` block in `sway/config`.

## Fix Screen Tearing (X11 / Legacy)

> Wayland compositors like Sway handle this natively. These steps apply to X11 only (awesome WM etc.).


##### Keep `vsync` on

In `picom.conf`

```bash
vsync = true;
```

#### Intel / AMD X11 Config

File to Edit/Add: /etc/X11/xorg.conf.d/20-intel.conf or 20-amd.conf

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
