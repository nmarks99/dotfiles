alias start='gio open 2>/dev/null'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias icat="kitty +kitten icat"
alias map="telnet mapscii.me"
alias devs="df -h"

# source ESP-IDF tools
alias get_idf='source $HOME/.esp/esp-idf/export.sh'

# Replace vim with neovim
alias vim='nvim'

# only in kitty terminal
if [[ $TERM == "xterm-kitty" ]]; then
    alias cat="bat --paging=never --style=plain"
    alias ls="lsd"
    alias kitty-ssh="kitty +kitten ssh"
    alias icat="kitty +kitten icat"
fi

