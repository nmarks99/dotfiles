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
PS1='\[\e[1;34m\]┌──(\[\e[1;36m\]\u\[\e[1;34m\]@\[\e[1;35m\]\h\[\e[1;34m\])-[\[\e[1;37m\]\w\[\e[1;34m\]]\[\e[1;33m\]\n\[\e[1;34m\]└─$\[\e[0m\] '

# go
PATH="/usr/local/go/bin:$PATH"

# pipx
eval "$(register-python-argcomplete pipx)"

# Add platformio binaries to path
PATH="$HOME/.platformio/penv/bin:$PATH"
