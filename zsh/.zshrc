# Enable colors
autoload -U colors && colors

# History in cache directory:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
export EDITOR=nvim
export SUDO_EDITOR=nvim

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.

# ALIASES
alias ls='lsd -l'
alias ll='lsd -Al'
alias vim='nvim'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias btconnect="bluetoothctl power on && bluetoothctl connect 8E:95:F1:F5:5B:D2"
alias btdisconnect="bluetoothctl disconnect 8E:95:F1:F5:5B:D2 && bluetoothctl power off"

# Prompt
eval "$(starship init zsh)"
export STARSHIP_CONFIG=$HOME/.config/starship/gruvbox.toml

# Increase JS Heap memory
export NODE_OPTIONS=--max-old-space-size=8096

# Chrome for Karma Testing
export CHROME_BIN='/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing'

# Rose Pine in FZF
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
	--color=fg:#908CAA,bg:-1,hl:#EBBCBA
	--color=fg+:#E0DEF4,bg+:#26233A,hl+:#EBBCBA
	--color=border:#403D52,header:#31748F,gutter:-1
	--color=spinner:#F6C177,info:#9CCFD8
	--color=pointer:#C4A7E7,marker:#EB6F92,prompt:#908CAA
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="󱞩 "
  --layout="default" --info="right"'

# Gruvbox for FZF
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
	--color=fg:#EBDBB2,bg:-1,hl:#8EC07C
	--color=fg+:#FBF1C7,bg+:#282828,hl+:#8EC07C
	--color=border:#665C54,header:#83A598,gutter:-1
	--color=spinner:#FE8019,info:#FABD2F
	--color=pointer:#62693e,marker:#D79921,prompt:#427B58
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="󱞩 "
  --layout="default" --info="right"'

# Node Version Manager
FNM_PATH="/home/sahil.jassal/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/sahil.jassal/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

# Plugins
source $HOME/personal/configs/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/personal/configs/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_HIGHLIGHT_STYLES[comment]="fg=white,bold"

# Force emacs mode to avoid vi mode
bindkey -e

# arrow keys
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
bindkey '^H' backward-kill-word
bindkey '5~' kill-word
bindkey -s ^bf "^Usessionizer\n"


. "$HOME/.cargo/env"

## MAC OS :(
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(fnm env --shell zsh)"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# Update homebrew every 5 days
export HOMEBREW_AUTO_UPDATE_SECS=$((60 * 60 * 24 * 7))
