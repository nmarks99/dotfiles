# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Alias definitions in ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

## Add ~/bin and ~/.local/bin to path
PATH="$HOME/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"

# Set editor to neovim
export EDITOR='nvim'

# Set font colors for directories displayed with ls
LS_COLORS=$LS_COLORS:'di=0;35:' ; export LS_COLORS

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

## Prompt
# source ~/.config/pureline/pureline ~/.config/pureline/pureline.conf
# eval "$(starship init bash)"
git_branch() {
  git rev-parse --is-inside-work-tree &>/dev/null
  if [ $? -eq 0 ]; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)
    if [ -n "$(git status --porcelain)" ]; then
      echo -e " \x1b[33m($branch*)\x1b[0m" # Red if the working directory is dirty
    else
      echo -e " \x1b[32m($branch)\x1b[0m"  # Green if the working directory is clean
    fi
  fi
}
# this will work without additional fonts or dependencies except for git:
PS1='\[\e[1;34m\]┌──(\[\e[1;36m\]\u\[\e[1;34m\]@\[\e[1;35m\]\h\[\e[1;34m\])-[\[\e[1;37m\]\w\[\e[1;34m\]]\[\e[1;33m\]$(git_branch)\n\[\e[1;34m\]└─$\[\e[0m\] '

# Platformio
# export PATH=$PATH:~/.platformio/penv/bin

# EPICS binaries
# export PATH=$PATH:/usr/local/epics/bin

# cargo 
# . "$HOME/.cargo/env"

# Raspberry Pi Pico SDK
# export PICO_SDK_PATH="/home/nick/.local/pico-dev/pico-sdk"

# rbenv (ruby environment manager)
# eval "$(~/.rbenv/bin/rbenv init - --no-rehash bash)"

# nvm
# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Install Ruby Gems to ~/.gems
# export GEM_HOME="$HOME/.gems"
# export PATH="$HOME/.gems/bin:$PATH"

# Source ROS2 Iron
# source /opt/ros/iron/setup.bash
# export PYTHONWARNINGS=ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources

# nvm node version manager (SLOW)
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
