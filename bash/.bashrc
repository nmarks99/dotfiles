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
# PS1='[\u@\h \W]\$ ' # simple
git_branch() {
    if [ -d ".git/" ]; then
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)
        if [ -n "$(git status --porcelain)" ]; then
            echo -e " \x1b[31m($branch*)\x1b[0m" # working directory is dirty
        else
            echo -e " \x1b[32m($branch)\x1b[0m"  # working directory is clean
        fi
    fi
}
# this will work without additional fonts or dependencies except for git:
PS1='\[\e[1;34m\]┌──(\[\e[1;36m\]\u\[\e[1;34m\]@\[\e[1;35m\]\h\[\e[1;34m\])-[\[\e[1;37m\]\w\[\e[1;34m\]]\[\e[1;33m\]$(git_branch)\n\[\e[1;34m\]└─$\[\e[0m\] '

# pipx
eval "$(register-python-argcomplete pipx)"
