# Alias definitions in ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Add ~/bin and ~/.local/bin to path
export PATH="$PATH:~/bin"
export PATH="$PATH:~/.local/bin"

# Soruce cargo env
. "$HOME/.cargo/env"

# Starship prompt
# if [ "$TERM" != "linux" ] && [ "$TERM" != "xterm-256color" ]; then
if [ "$TERM" != "linux" ]; then
    eval "$(starship init bash)"
    # source ~/.config/pureline/pureline ~/.config/pureline/pureline.conf
else
  PS1="[\u@\h \W]\\$ "
fi

# Add platformio binaries to PATH
export PATH="$PATH:~/.platformio/penv/bin/"

# Set default editor to neovim
export EDITOR='nvim'

# Set font colors for directories displayed with ls
LS_COLORS=$LS_COLORS:'di=0;35:' ; export LS_COLORS

# Setup EPICS environment:
# - EPICS_HOST_ARCH = rhel9-x86_64
# - CPATH set to find EPICS base and synApps libraries
source /home/beams/NMARKS/.epics_env/env_epics.bash

# nvm (slow!)
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
