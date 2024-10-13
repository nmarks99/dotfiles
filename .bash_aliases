alias start='gio open 2>/dev/null'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias icat="kitty +kitten icat"
alias map="telnet mapscii.me"
alias devs="df -h"
alias clock="tty-clock -s -t -S -b -c -C 4"
alias newest="ls -Art | tail -n 1"
alias cat="bat --paging=never --style=plain"
alias ls="lsd"
alias clipboard='tr -d "\n" | xclip -selection clipboard'

# Replace vim with neovim
alias vim='nvim'

# only in kitty terminal
if [[ $TERM == "xterm-kitty" ]]; then
    alias kitty-ssh="kitty +kitten ssh"
    alias icat="kitty +kitten icat"
fi
