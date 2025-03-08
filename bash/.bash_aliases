alias start='xdg-open 2>/dev/null'
alias devs="df -h"
alias newest="ls -Art | tail -n 1"
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias qtdesigner='/usr/lib/qt6/bin/designer'
alias diskusage="df -h | grep nvme | head -1"

if [[ $XDG_SESSION_TYPE == "wayland" ]]; then
    alias clipboard='wl-copy'
else
    alias clipboard='tr -d "\n" | xclip -selection clipboard'
fi

if [[ $XDG_CURRENT_DESKTOP == "Hyprland" ]]; then
    alias display_normal="hyprctl keyword monitor eDP-1,preferred,auto,1.0,transform,0"
    alias display_inverted="hyprctl keyword monitor eDP-1,preferred,auto,1.0,transform,2"
fi

if [[ $TERM == "xterm-kitty" ]]; then
    alias kitty-ssh="kitty +kitten ssh"
    alias icat="kitty +kitten icat"
fi
