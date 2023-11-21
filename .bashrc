# Alias definitions in ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Add ~/bin and ~/.local/bin to path
export PATH="$PATH:~/bin"
export PATH="$PATH:~/.local/bin"

# symlink to Kitty binaries
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
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
export PATH="$PATH:/local/nmarks/.platformio/penv/bin/"

# Set default editor to neovim
export EDITOR='nvim'

# Set font colors for directories displayed with ls
LS_COLORS=$LS_COLORS:'di=0;35:' ; export LS_COLORS

# uncrustify
export UNCRUSTIFY_CONFIG="/local/nmarks/.config/uncrustify/uncrustify.cfg"

# Setup EPICS environment:
# - EPICS_HOST_ARCH = rhel9-x86_64
# - CPATH set to find EPICS base and synApps libraries
source /local/nmarks/.epics_env/env_epics.bash

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# local python modules
export PYTHONPATH="$PYTHONPATH:/local/nmarks/.local/lib/local-pymodules/"
