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
LS_COLORS='di=0;35:ow=01;35;40';export LS_COLORS

# Set default editor to neovim if nvim binary is available
export EDITOR=$(which nvim &> /dev/null && echo nvim || echo vi)
export VIEWER=${EDITOR}
export NVIM_THEME="lackluster"
export NVIM_TRANSPARENCY="false"

# Prompt
source ~/.bash_prompt

# Source cargo env
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# golang
PATH="$HOME/.local/go/bin:$PATH"
if [ -d "$HOME/go/bin" ]; then
    PATH="$HOME/go/bin:$PATH"
fi

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

# pvtui
export PATH="/home/beams/NMARKS/devel/pvtui/build/bin":${PATH}

export PATH="/home/beams0/NMARKS/.nvm/versions/node/v21.4.0/bin":${PATH}
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
