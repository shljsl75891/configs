# ALIASES
alias ls='lsd -lh --color=auto'
alias ll='lsd -alh --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias cd..='cd ..'
alias cd..='cd ..'
alias cd...='cd ../..'
alias cd....='cd ../../..'
alias cd.....='cd ../../../..'
alias tmux='tmux -u2'
alias tk='tmux kill-server'

# Prompt
eval "$(starship init zsh)"

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Plugins
source $HOME/personal/configs/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/personal/configs/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
