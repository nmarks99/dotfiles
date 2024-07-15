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
# Use starship if GLIBC version is compatible
glibc_version=$(ldd --version | head -n 1 | awk '{print $NF}')
req_version="2.29"
if [ "$(printf '%s\n' "$glibc_version" "$req_version" | sort -V | head -n 1)" == "$req_version" ]; then
    eval "$(starship init bash)"
else 
    alias ls='ls --color'
    export PROMPT_DIRTRIM=3
    PS1="[\[\e[31m\]\u\[\e[m\]@\[\e[33m\]\h\[\e[m\]:\w]\\$"
    # source ~/.config/pureline/pureline ~/.config/pureline/pureline.conf
fi

# Source cargo env
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Add platformio binaries to PATH
export PATH="$PATH:~/.platformio/penv/bin/"

# directory for local python modules
export PYTHONPATH="$PYTHONPATH:$HOME/.local/lib/local_python_modules/"

# ymir-ln specific configuration
if [[ $(hostname) == *ymir-ln* ]]; then
    export EPICS_HOST_ARCH="rhel9-x86_64"

    ## CPATH set to find EPICS base and synApps libraries
    # this shouldn't be needed, use "bear -- make"
    # to generete compile_commands.json
    # source /home/beams/NMARKS/.epics_env/env_epics.bash
fi

# SPDLOG C++ library logging level
export SPDLOG_LEVEL=debug,mylogger=trace

# fzf
FZF_ALT_C_COMMAND=
FZF_CTRL_T_COMMAND=
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
