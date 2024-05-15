alias start='gio open 2>/dev/null'
alias firefox="/home/beams/NMARKS/.local/bin/firefox/firefox"
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
alias newest="ls -Art | tail -n 1"
alias libcheck="ldconfig -p | grep ${1}"
alias pyenvinit='source ~/.pyenv/pyenv_init.bash'
alias clipboard='xclip -selection clipboard'

if [[ $TERM == "xterm-kitty" ]]; then
    if [[ $(hostname) == *ymir-ln* ]]; then
        alias cat="bat --paging=never"
        alias ls="lsd"
        alias icat="kitty +kitten icat"
    fi
fi
