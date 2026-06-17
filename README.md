# My Dotfiles

```console
git clone --recurse-submodules https://github.com/shljsl75891/configs.git
```

# Dependencies

### Awesome WM (X11 — legacy)

```console
zsh tmux libx11-dev libxft-dev libxrandr-dev libxinerama-dev build-essential awesome maim ffmpegthumbnailer mpv cmake
```

### Hyprland (Wayland — Ubuntu 26.04+)

```console
sudo apt install hyprland waybar rofi grim slurp wl-clipboard swaybg \
  hyprlock mako-notifier brightnessctl pamixer playerctl copyq pcmanfm \
  network-manager-gnome blueman xdg-desktop-portal-hyprland ghostty \
  qt5ct azote
```

### Tools which I use to enhance my development workflow

- Linux (Ubuntu 26.04 LTS)
- Neovim configured from scratch (ref: [Primeagen's video](https://www.youtube.com/watch?v=w7i4amO_zaE))
- Hyprland (Wayland) — migrated from Awesome WM
- VSCode with VIM Extension configured

## Hyprland Setup (Ubuntu 26.04 / Wayland)

### Session

Log out of GNOME → at GDM login screen, click the gear icon → select **Hyprland**.
Hyprland cannot be launched from inside a running GNOME session.

### Symlink configs

```bash
# Hyprland + scripts
ln -sf ~/personal/configs/hypr       ~/.config/hypr

# Waybar
ln -sf ~/personal/configs/waybar     ~/.config/waybar

# Rofi (launcher)
ln -sf ~/personal/configs/rofi       ~/.config/rofi

# Mako (notifications)
mkdir -p ~/.config/mako
ln -sf ~/personal/configs/mako/config ~/.config/mako/config

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
```

### Multi-monitor (Wayland)

Edit `hypr/hyprland.conf` — replace the generic monitor line with explicit entries:

```ini
monitor = eDP-1,  1920x1080@60, 0x0,    1
monitor = HDMI-A-1, 1920x1080@60, 1920x0, 1
```

Run `hyprctl monitors` to confirm output names.

### Keybinding cheat-sheet

| Key | Action |
|---|---|
| `Super+Return` | ghostty terminal |
| `Super+r` | rofi app launcher |
| `Super+e` | pcmanfm file manager |
| `Super+b` / `Super+Shift+b` | brave (work / personal) |
| `Super+Shift+o` | obsidian |
| `Super+p` | CopyQ clipboard history |
| `Print` | screenshot → clipboard |
| `Super+h/j/k/l` | focus left/down/up/right |
| `Super+Shift+j/k` | swap window next/prev |
| `Super+Shift+Return` | swap with master |
| `Super+=` / `Super+-` | add/remove master |
| `Super+Ctrl+=` / `Super+Ctrl+-` | cycle layout orientation |
| `Super+Tab` | focus next monitor |
| `Super+u` | jump to urgent window |
| `Super+f` | fullscreen |
| `Super+m` | maximize |
| `Super+q` | close window |
| `Super+o` | toggle floating |
| `Super+t` | pin (always visible) |
| `Super+n` | minimize → special workspace |
| `Super+Shift+n` | restore minimized |
| `Super+arrows` | resize window |
| `Alt+arrows` | move floating window |
| `Super+x` | toggle waybar |
| `Super+BackSpace` | dismiss all notifications |
| `Super+Ctrl+r` | reload hyprland config |
| `Super+1..9` | switch workspace |
| `Super+Shift+1..9` | move window to workspace |
| `XF86MonBrightness*` | brightness ±5% |
| `XF86Audio*` | volume / mute (wpctl) |
| `Super+LMB drag` | move window |
| `Super+RMB drag` | resize window |

### Caveats vs Awesome WM

- **No true minimize**: `Super+n` moves to `special:min` workspace; `Super+Shift+n` restores.
- **No multi-tag toggle** (`Super+Ctrl+#` / `Super+Ctrl+Shift+#`): not supported in Hyprland.
- **Lua widgets not portable**: waybar native modules used (cpu/mem/net/audio/battery/backlight/clock/tray + power menu).
- **picom not needed**: Hyprland is its own compositor.
- **xinput touchpad**: replaced by `input {}` block in hyprland.conf.

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
inode/directory=pcmanfm.desktop;
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

## ScreenShots

![](/assets/2025-05-14-06-57-57.png)

![](/assets/2025-05-14-06-58-17.png)
