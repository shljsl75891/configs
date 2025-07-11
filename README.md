# My Dotfiles

```console
git clone --recurse-submodules https://github.com/shljsl75891/configs.git
```

# Dependencies

```console
zsh tmux libx11-dev libxft-dev libxrandr-dev libxinerama-dev build-essential awesome maim ffmpegthumbnailer mpv cmake
```

### Tools which I use to enhance my development workflow

- Linux (Debian Based for stability)
- Neovim configured from scratch (ref: [Primeagen's video](https://www.youtube.com/watch?v=w7i4amO_zaE))
- Awesome WM configured from scratch
- VSCode with VIM Extension configured

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

## Multi monitor conf - `/etc/X11/xorg.conf.d/30-monitors.conf`

```conf
Section "Monitor"
   Identifier "eDP1"
   Option "PreferredMode" "1920x1080"
   Option "TargetRefresh" "60"
   Option "LeftOf" "HDMI1"
   Option "Position" "0 0"
EndSection

Section "Monitor"
   Identifier "HDMI1"
   Option "PreferredMode" "1920x1080"
   Option "TargetRefresh" "60"
   Option "RightOf" "eDP1"
   Option "Position" "1920 0"
EndSection
```

## MAC Useful Commands

- Command to make yourself `Administrator` in MacOS

```sh
sudo dseditgroup -o edit -a $USER -t user admin
```

- Enable Quitting MAC finder

```sh
defaults write com.apple.finder QuitMenuItem -bool true; killall Finder
```
