alias start='gio open 2>/dev/null'
alias firefox="${HOME}/.local/bin/firefox/firefox"
alias dotfiles="/usr/bin/git --git-dir=${HOME}/.dotfiles --work-tree=${HOME}"
alias newest="ls -Art | tail -n 1"
alias libcheck="ldconfig -p | grep ${1}"
alias clipboard='tr -d "\n" | xclip -selection clipboard'
# alias pyenvinit='source ~/.pyenv/pyenv_init.bash'

if which "lsd" &> /dev/null; then
    alias ls="lsd"
else
    alias ls='ls --color'
fi

if which "bat" &> /dev/null; then
    alias cat="bat --paging=never"
fi

if [[ $TERM == "xterm-kitty" ]]; then
    if [[ $(hostname) == *ymir-ln* ]]; then
        alias ssh="kitty +kitten ssh"
        alias icat="kitty +kitten icat"
    fi
fi
