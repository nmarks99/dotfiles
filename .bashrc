# ~/.bashrc: executed by bash(-1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
PATH="$HOME/bin:$PATH"

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions in ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


# Source cargo 
. "$HOME/.cargo/env"

# Add platformio core to path
export PATH=$PATH:~/.platformio/penv/bin

# Source pureline or starship configuration
# Don't use pureline in vscode integrated terminal or default gnome terminal
if [ "$TERM" != "linux" ] && [ "$TERM" != "xterm-256color" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
    # source ~/.config/pureline/pureline ~/.config/pureline/pureline.conf
    eval "$(starship init bash)"
fi

# Set editor to neovim. vi and vim are aliased to nvim in .bash_aliases
export EDITOR='nvim'

# nvm node version manager (SLOW)
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Set font colors for directories displayed with ls
LS_COLORS=$LS_COLORS:'di=0;35:' ; export LS_COLORS

# Add path to MiKTeX binaries
export PATH=$PATH:/usr/local/bin/MiKTeX

# spicetify 
# export SPICETIFY_INSTALL="/home/nick/.spicetify"
# export PATH="$SPICETIFY_INSTALL:$PATH"

# AVR toolchain
export PATH="$PATH:/opt/avr8-gnu-toolchain-linux_x86_64/bin"

# ARM toolchain
export PATH="$PATH:/opt/arm-gnu-toolchain-12.2.mpacbti-rel1-x86_64-arm-none-eabi/bin"

# ROS (SLOW)
# source /opt/ros/humble/setup.bash
# export PYTHONWARNINGS=ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources
# export GZ_VERSION=fortress
# source ~/rosws/nuws/install/setup.bash

# Install Ruby Gems to ~/.gems
export GEM_HOME="$HOME/.gems"
export PATH="$HOME/.gems/bin:$PATH"

# deno javascript runtime
export DENO_INSTALL="/home/nick/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
export OPENAI_API_KEY=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

# ESP toolchain
export LIBCLANG_PATH="/home/$USER/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-16.0.0-20230516/esp-clang/lib"
export PATH="/home/$USER/.rustup/toolchains/esp/xtensa-esp32-elf/esp-12.2.0_20230208/xtensa-esp32-elf/bin:$PATH"
export PATH="/home/$USER/.rustup/toolchains/esp/xtensa-esp32s2-elf/esp-12.2.0_20230208/xtensa-esp32s2-elf/bin:$PATH"
export PATH="/home/$USER/.rustup/toolchains/esp/xtensa-esp32s3-elf/esp-12.2.0_20230208/xtensa-esp32s3-elf/bin:$PATH"
export PATH="/home/$USER/.rustup/toolchains/esp/riscv32-esp-elf/esp-12.2.0_20230208/riscv32-esp-elf/bin:$PATH"
