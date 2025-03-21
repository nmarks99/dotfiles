# directories: drwxrwsr-x 
# files: .rw-rw-r--
umask 2

# Add ~/bin and ~/.local/bin to path
export PATH="$PATH:~/bin"
export PATH="$PATH:~/.local/bin"

# Alias definitions in ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Set font colors for directories displayed with ls
# LS_COLORS=$LS_COLORS:'di=0;34:';export LS_COLORS
# export LS_COLORS="ow=01;34;40:$LS_COLORS"
LS_COLORS='di=0;34:ow=01;34;40';export LS_COLORS

# Set default editor to neovim if nvim binary is available
export EDITOR=$(which nvim &> /dev/null && echo nvim || echo vi)
export NVIM_THEME="ashen"
export NVIM_TRANSPARENCY="false"

# Prompt
source ~/.bash_prompt

# Source cargo env
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# golang
PATH="$HOME/.local/go/bin:$PATH"

# add directory for local python modules to PATH
if [ -d "$HOME/.local/lib/local_python_modules" ]; then
    export PYTHONPATH="$PYTHONPATH:$HOME/.local/lib/local_python_modules/"
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# # set EPICS_HOST_ARCH based on redhat version
# if [ -f /etc/redhat-release ]; then
    # release_info=$(cat /etc/redhat-release)
    # major_version=$(echo $release_info | grep -oE '[0-9]+' | head -n 1)
    # if [ -n "$major_version" ]; then
        # export EPICS_HOST_ARCH="rhel${major_version}-x86_64"
    # fi
    # # echo "EPICS_HOST_ARCH=${EPICS_HOST_ARCH}"
# fi

# SPDLOG C++ library logging level
export SPDLOG_LEVEL=debug,mylogger=trace

# fzf
FZF_ALT_C_COMMAND=
# FZF_CTRL_T_COMMAND=
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
