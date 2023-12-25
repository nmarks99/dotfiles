# ~/.bashrc: executed by bash(-1) for non-login shells.

# Alias definitions in ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Add ~/bin to path
PATH="$HOME/bin:$PATH"

# Set editor to neovim
export EDITOR='nvim'

# Set font colors for directories displayed with ls
LS_COLORS=$LS_COLORS:'di=0;35:' ; export LS_COLORS

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add platformio core to path
export PATH=$PATH:~/.platformio/penv/bin

# Source pureline or starship configuration
# Don't use pureline in vscode integrated terminal or default gnome terminal
if [[ $TERM != "linux" ]]; then
    # source ~/.config/pureline/pureline ~/.config/pureline/pureline.conf
    eval "$(starship init bash)"
fi

# Source cargo 
. "$HOME/.cargo/env"

# nvm node version manager (SLOW)
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Add path to MiKTeX binaries
# export PATH=$PATH:/usr/local/bin/MiKTeX

# AVR toolchain
# export PATH="$PATH:/opt/avr8-gnu-toolchain-linux_x86_64/bin"

# ARM toolchain
# export PATH="$PATH:/opt/arm-gnu-toolchain-12.2.mpacbti-rel1-x86_64-arm-none-eabi/bin"

# ROS (SLOW)
# source /opt/ros/humble/setup.bash
# export PYTHONWARNINGS=ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources
# export GZ_VERSION=fortress
# source ~/rosws/nuws/install/setup.bash

# Install Ruby Gems to ~/.gems
# export GEM_HOME="$HOME/.gems"
# export PATH="$HOME/.gems/bin:$PATH"

# deno javascript runtime
# export DENO_INSTALL="/home/nick/.deno"
# export PATH="$DENO_INSTALL/bin:$PATH"
# export OPENAI_API_KEY=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

# ESP toolchain
# export LIBCLANG_PATH="/home/$USER/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-16.0.0-20230516/esp-clang/lib"
# export PATH="/home/$USER/.rustup/toolchains/esp/xtensa-esp32-elf/esp-12.2.0_20230208/xtensa-esp32-elf/bin:$PATH"
# export PATH="/home/$USER/.rustup/toolchains/esp/xtensa-esp32s2-elf/esp-12.2.0_20230208/xtensa-esp32s2-elf/bin:$PATH"
# export PATH="/home/$USER/.rustup/toolchains/esp/xtensa-esp32s3-elf/esp-12.2.0_20230208/xtensa-esp32s3-elf/bin:$PATH"
# export PATH="/home/$USER/.rustup/toolchains/esp/riscv32-esp-elf/esp-12.2.0_20230208/riscv32-esp-elf/bin:$PATH"
#

# export LIBCLANG_PATH="/home/nick/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-16.0.4-20231113/esp-clang/lib"
# export PATH="/home/nick/.rustup/toolchains/esp/xtensa-esp-elf/esp-13.2.0_20230928/xtensa-esp-elf/bin:$PATH"
