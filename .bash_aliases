alias start='gio open 2>/dev/null'
alias firefox="/home/beams/NMARKS/.local/bin/firefox/firefox"
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
alias newest="ls -Art | tail -n 1"
alias libcheck="ldconfig -p | grep ${1}"
alias pyenvinit='source ~/.pyenv/pyenv_init.bash'

# only in kitty terminal
if [[ $TERM == "xterm-kitty" ]]; then
    if [[ $(hostname) == *ymir-ln* ]]; then
        alias cat="bat --paging=never"
        alias ls="lsd"
    fi
    alias icat="kitty +kitten icat"
    # alias ssh="kitty +kitten ssh"
fi
