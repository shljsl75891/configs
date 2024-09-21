# My Dotfiles

### Tools which I use to enhance my development workflow

- Linux (Debian Based for stability)
- Neovim configured from scratch (ref: [Primeagen's video](https://www.youtube.com/watch?v=w7i4amO_zaE))
- Awesome WM configured from scratch
- VSCode with VIM Extension configured

# Dependencies

```console
zsh tmux libx11-dev libxft-dev libxrandr-dev libxinerama-dev build-essential awesome maim ffmpegthumbnailer mpv
```

![image](https://github.com/user-attachments/assets/bfc1f97d-aa1f-4695-8941-744d6be04ecd)

![image](https://github.com/user-attachments/assets/1ac6b7e3-2152-46a3-96c5-89b1f0852eba)

![image](https://github.com/user-attachments/assets/f18b83e5-8614-4cd3-a042-6fd57d5f9fc2)

# How to change cursor theme

1. In `.icons/default/index.theme`

```
# This file is written by LXAppearance. Do not edit.
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=BreezeX-RosePineDawn-Linux
```

2. And do change `gtk-cursor-theme-name` attribute in `~/.gtkrc-2.0` and `~/.config/gtk-3.0/settings.ini`
