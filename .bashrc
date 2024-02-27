cd; # initially starts in /home/beams0/NMARKS?

# directories: drwxrwsr-x 
# files: .rw-rw-r--
umask 2

# Alias definitions in ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Add ~/bin and ~/.local/bin to path
export PATH="$PATH:~/bin"
export PATH="$PATH:~/.local/bin"

# Source cargo env
. "$HOME/.cargo/env"

# Prompt
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

# Setup EPICS environment
# CPATH set to find EPICS base and synApps libraries
export EPICS_HOST_ARCH="rhel9-x86_64"
# source /home/beams/NMARKS/.epics_env/env_epics.bash
