alias start='gio open 2>/dev/null'
alias firefox="/local/nmarks/.local/bin/firefox/firefox"
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
alias newest="ls -Art | tail -n 1"

# Replace vim with neovim
# vi is still regular vim
alias vim='nvim'

# only in kitty terminal
if [[ $TERM == "xterm-kitty" ]]; then
    alias cat="bat --paging=never"
    alias ls="lsd"
    alias kitty-ssh="kitty +kitten ssh"
    alias icat="kitty +kitten icat"
fi

# dserv synapps directories
alias s4dserv="cd /net/s4dserv/xorApps/epics/synApps_6_2_1/"
alias s8iddserv="cd /net/s8iddserv/xorApps/epics/synApps_6_2_1/"
alias s20dserv="cd /net/s20dserv/xorApps/epics/synApps_6_2_1/"
