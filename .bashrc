# Alias definitions in ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Add ~/bin to path
PATH="$HOME/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"

# Set editor to neovim
export EDITOR='nvim'

# Set font colors for directories displayed with ls
LS_COLORS=$LS_COLORS:'di=0;35:' ; export LS_COLORS

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add platformio core to path
export PATH=$PATH:~/.platformio/penv/bin

# EPICS bin path
export PATH=$PATH:/usr/local/epics/bin

# Source pureline or starship configuration
# Don't use pureline in vscode integrated terminal or default gnome terminal
if [[ $TERM != "linux" ]]; then
    # source ~/.config/pureline/pureline ~/.config/pureline/pureline.conf
    eval "$(starship init bash)"
fi

# Source cargo 
. "$HOME/.cargo/env"

# Raspberry Pi Pico SDK
export PICO_SDK_PATH="/home/nick/.local/pico-dev/pico-sdk"

# Source ROS2 Iron
# source /opt/ros/iron/setup.bash
# export PYTHONWARNINGS=ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources

# nvm node version manager (SLOW)
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install Ruby Gems to ~/.gems
# export GEM_HOME="$HOME/.gems"
# export PATH="$HOME/.gems/bin:$PATH"
