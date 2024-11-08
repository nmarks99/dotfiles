alias start='xdg-open 2>/dev/null'
alias map="telnet mapscii.me"
alias devs="df -h"
alias clock="tty-clock -s -t -S -b -c -C 4"
alias newest="ls -Art | tail -n 1"
alias clipboard='tr -d "\n" | xclip -selection clipboard'
alias grep='grep --color=auto'
alias ls='ls --color=auto'

if [[ $XDG_CURRENT_DESKTOP == "Hyprland" ]]; then
    alias set_display_normal="hyprctl keyword monitor eDP-1,preferred,auto,1.0,transform,0"
    alias set_display_inverted="hyprctl keyword monitor eDP-1,preferred,auto,1.0,transform,2"
fi

# Replace vim with neovim
alias vim='nvim'

# only in kitty terminal
if [[ $TERM == "xterm-kitty" ]]; then
    alias kitty-ssh="kitty +kitten ssh"
    alias icat="kitty +kitten icat"
fi
