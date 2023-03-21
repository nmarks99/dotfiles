alias start='gio open 2>/dev/null'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias icat="kitty +kitten icat"
alias map="telnet mapscii.me"
alias devs="df -h"

# Replace vim with neovim
alias vim='nvim'
alias vi='nvim'

# lsd doesn't work in vscode integrated terminal 
# only alias ls for it when not in vscode 
if [ "$TERM_PROGRAM" != "vscode" ]; then
    alias ls="lsd"
fi

# rust bat to replace cat
alias cat="bat --paging=never --style=plain"


