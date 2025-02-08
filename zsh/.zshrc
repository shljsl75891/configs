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
export NODE_OPTIONS=--max-old-space-size=8096

# Chrome for Karma Testing
export CHROME_BIN=~/chrome-testing/chrome

# Rose Pine for FZF
export FZF_DEFAULT_OPTS="
	--color=fg:#908CAA,bg:-1,hl:#EBBCBA
	--color=fg+:#E0DEF4,bg+:#26233A,hl+:#EBBCBA
	--color=border:#403D52,header:#31748F,gutter:-1
	--color=spinner:#F6C177,info:#9CCFD8
	--color=pointer:#C4A7E7,marker:#EB6F92,prompt:#908CAA"

# Gruvbox for FZF
export FZF_DEFAULT_OPTS="
	--color=fg:#EBDBB2,bg:-1,hl:#8EC07C
	--color=fg+:#FBF1C7,bg+:#282828,hl+:#8EC07C
	--color=border:#665C54,header:#83A598,gutter:-1
	--color=spinner:#FE8019,info:#FABD2F
	--color=pointer:#62693e,marker:#D79921,prompt:#FABD2F"


# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Plugins
source $HOME/personal/configs/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/personal/configs/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_HIGHLIGHT_STYLES[comment]="fg=white,bold"

# arrow keys
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
bindkey '^H' backward-kill-word
bindkey '5~' kill-word
bindkey -s ^bf "^Usessionizer\n"
