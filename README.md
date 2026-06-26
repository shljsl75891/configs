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

### Tools which I use to enhance my development workflow

- Linux (Ubuntu 26.04 LTS)
- Neovim configured from scratch (ref: [Primeagen's video](https://www.youtube.com/watch?v=w7i4amO_zaE))
- Sway (Wayland) — migrated from Hyprland / Awesome WM
- VSCode with VIM Extension configured

## Sway Setup (Ubuntu 26.04 / Wayland)

### Session

Log out of GNOME → at GDM login screen, click the gear icon → select **Sway**.
Sway cannot be launched from inside a running GNOME session.

### Symlink configs

```bash
# Sway + scripts
ln -sf ~/personal/configs/sway       ~/.config/sway

# Swaylock
ln -sf ~/personal/configs/swaylock   ~/.config/swaylock

# Waybar
ln -sf ~/personal/configs/waybar     ~/.config/waybar

# Mako (notifications)
ln -sf ~/personal/configs/mako       ~/.config/mako

# Qt5 theme (dark theme for Qt apps e.g. CopyQ)
ln -sf ~/personal/configs/qt5ct      ~/.config/qt5ct

# GTK fonts (3 + 4)
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
ln -sf ~/personal/configs/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini
ln -sf ~/personal/configs/gtk-4.0/settings.ini ~/.config/gtk-4.0/settings.ini

# Fontconfig (Qt / system-wide font aliases)
mkdir -p ~/.config/fontconfig
ln -sf ~/personal/configs/fontconfig/fonts.conf ~/.config/fontconfig/fonts.conf
fc-cache -f

# xsettingsd (legacy GTK/XWayland font/theme propagation)
ln -sf ~/personal/configs/fontconfig/xsettingsd.conf ~/.config/xsettingsd/xsettingsd.conf

# hyprvoice (voice-to-text dictation)
ln -sf ~/personal/configs/hyprvoice ~/.config/hyprvoice
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

**Symlink config** (already covered in Symlink configs section above):
```bash
ln -sf ~/personal/configs/hyprvoice ~/.config/hyprvoice
```

**Usage:**
- `Super+d` — start recording (speak); press again to stop and transcribe → text injected at cursor
- `Super+Shift+d` — cancel/discard

### Caveats vs Hyprland / Awesome WM

- **No blur or rounded corners**: standard Sway has none; use SwayFX fork if needed.
- **No maximize**: Sway has no native maximize command; `Super+f` toggles fullscreen.
- **autotiling for layout**: master-stack behavior via the `autotiling` script (alternating splits).
- **No pin/always-on-top**: Sway has no equivalent; use `sticky toggle` to make a window visible on all workspaces.
- **picom not needed**: Sway is its own Wayland compositor.
- **Touchpad config**: managed via `input type:touchpad {}` block in `sway/config`.

## Fix Screen Tearing

- [Reference](https://christitus.com/fix-screen-tearing-linux/) - [Chris Titus Video](https://www.youtube.com/watch?v=rVBq6d3c1gM)

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

- Edit the file `~/.config/mimeapps.list`. For example, for `pcmanfm` as default file manager.

The current content in this file

```dosini
[Added Associations]
text/plain=nvim.desktop;
inode/directory=org.gnome.Nautilus.desktop;
application/json=nvim.desktop;
application/vnd.appimage=gnome-disk-image-writer.desktop;
image/svg+xml=nvim.desktop;

[Default Applications]
text/html=brave-browser.desktop
x-scheme-handler/http=brave-browser.desktop
x-scheme-handler/https=brave-browser.desktop
x-scheme-handler/about=brave-browser.desktop
x-scheme-handler/unknown=brave-browser.desktop
x-scheme-handler/webcal=brave-browser.desktop
x-scheme-handler/postman=Postman.desktop
```

## Screenshots

#### Awesome WM

![](/assets/2025-05-14-06-57-57.png)

![](/assets/2025-05-14-06-58-17.png)
