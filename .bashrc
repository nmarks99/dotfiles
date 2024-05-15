# directories: drwxrwsr-x 
# files: .rw-rw-r--
umask 2

# Alias definitions in ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Set font colors for directories displayed with ls
LS_COLORS=$LS_COLORS:'di=0;33:';export LS_COLORS

# Set default editor to neovim
export EDITOR='nvim'

# Add ~/bin and ~/.local/bin to path
export PATH="$PATH:~/bin"
export PATH="$PATH:~/.local/bin"

# Prompt
if [[ $(hostname) == *ymir-ln* ]]; then
    eval "$(starship init bash)"
else 
    alias ls='ls --color'
    export PROMPT_DIRTRIM=3
    PS1="[\[\e[31m\]\u\[\e[m\]@\[\e[33m\]\h\[\e[m\]:\w]\\$ "
    # source ~/.config/pureline/pureline ~/.config/pureline/pureline.conf
fi

# Source cargo env
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Add platformio binaries to PATH
# TODO: reinstall. currently points to /local/nmarks
# export PATH="$PATH:~/.platformio/penv/bin/"

if [[ $(hostname) == *ymir-ln* ]]; then
    # Setup EPICS environment
    export EPICS_HOST_ARCH="rhel9-x86_64"
    
    # directory for local python modules
    export PYTHONPATH="$PYTHONPATH:$HOME/.local/lib/local_python_modules/"
fi

## CPATH set to find EPICS base and synApps libraries
# this shouldn't be needed, use "bear -- make"
# to generete compile_commands.json
# source /home/beams/NMARKS/.epics_env/env_epics.bash

# SPDLOG C++ library logging level
export SPDLOG_LEVEL=debug,mylogger=trace
