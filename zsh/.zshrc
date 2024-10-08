# Enable colors
autoload -U colors && colors

# History in cache directory:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

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

# Chrome for Karma Testing
export CHROME_BIN=~/chrome-testing/chrome

# Rose Pine for FZF
export FZF_DEFAULT_OPTS="
	--color=fg:#908CAA,bg:-1,hl:#EBBCBA
	--color=fg+:#E0DEF4,bg+:#26233A,hl+:#EBBCBA
	--color=border:#403D52,header:#31748F,gutter:-1
	--color=spinner:#F6C177,info:#9CCFD8
	--color=pointer:#C4A7E7,marker:#EB6F92,prompt:#908CAA"

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
bindkey -s ^bf "^Usessionizer\n"
