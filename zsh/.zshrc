# Enable colors
autoload -U colors && colors

# History in cache directory:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/history

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.

# ALIASES
alias ls='lsd -l'
alias ll='lsd -Al'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Prompt
eval "$(starship init zsh)"

# Increase JS Heap memory
export NODE_OPTIONS=--max-old-space-size=16384

# Bun  
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Plugins
source $HOME/personal/configs/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/personal/configs/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# arrow keys
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
bindkey '^H' backward-kill-word
bindkey '5~' kill-word
bindkey -s ^bf "^U~/.config/tmux/sessionizer\n"
