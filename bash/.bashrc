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
LS_COLORS=$LS_COLORS:'di=0;35:';export LS_COLORS

# Set default editor to neovim if nvim binary is available
export EDITOR=$(which nvim &> /dev/null && echo nvim || echo vi)

# Determine what terminal emulator we are running
export TERM_PROGRAM=$(ps -o comm= -p $PPID)

# Prompt
export USE_STARSHIP="${USE_STARSHIP:-false}"
case $TERM_PROGRAM in
  "kitty" | "sshd" | "zellij" )
    if command -v starship &> /dev/null && [ "$USE_STARSHIP" = "true" ]; then
        eval "$(starship init bash)"
    else
        export PROMPT_DIRTRIM=3
        # PS1="\[\e[34m\]\u\[\e[m\]@\[\e[37m\]\h\[\e[m\]:\[\e[32m\]\w\[\e[m\]\\$"
        PS1='\[\e[1;34m\]┌──(\[\e[1;36m\]\u\[\e[1;34m\]@\[\e[1;35m\]\h\[\e[1;34m\])-[\[\e[1;37m\]\w\[\e[1;34m\]]\[\e[1;33m\]\n\[\e[1;34m\]└─$\[\e[0m\] '
    fi
    ;;
*)
    export PROMPT_DIRTRIM=3
    # PS1="\[\e[34m\]\u\[\e[m\]@\[\e[37m\]\h\[\e[m\]:\[\e[32m\]\w\[\e[m\]\\$"
    PS1='\[\e[1;34m\]┌──(\[\e[1;36m\]\u\[\e[1;34m\]@\[\e[1;35m\]\h\[\e[1;34m\])-[\[\e[1;37m\]\w\[\e[1;34m\]]\[\e[1;33m\]\n\[\e[1;34m\]└─$\[\e[0m\] '
esac

# Source cargo env
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Add platformio binaries to PATH
if [ -d "$HOME/.platformio" ]; then
    export PATH="$PATH:~/.platformio/penv/bin/"
fi

# add directory for local python modules to PATH
if [ -d "$HOME/.local/lib/local_python_modules" ]; then
    export PYTHONPATH="$PYTHONPATH:$HOME/.local/lib/local_python_modules/"
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# set EPICS_HOST_ARCH based on redhat version
if [ -f /etc/redhat-release ]; then
    release_info=$(cat /etc/redhat-release)
    major_version=$(echo $release_info | grep -oE '[0-9]+' | head -n 1)
    if [ -n "$major_version" ]; then
        export EPICS_HOST_ARCH="rhel${major_version}-x86_64"
    fi
    # echo "EPICS_HOST_ARCH=${EPICS_HOST_ARCH}"
fi

# SPDLOG C++ library logging level
export SPDLOG_LEVEL=debug,mylogger=trace

# fzf
FZF_ALT_C_COMMAND=
FZF_CTRL_T_COMMAND=
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
