alias start='gio open 2>/dev/null'
alias firefox="${HOME}/.local/bin/firefox/firefox"
alias dotfiles="/usr/bin/git --git-dir=${HOME}/.dotfiles --work-tree=${HOME}"
alias newest="ls -lt | head -1 | awk '{print \$NF}'"
alias libcheck="ldconfig -p | grep ${1}"
alias clipboard='tr -d "\n" | xclip -selection clipboard'
# alias darkmode='gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark'
# alias pyenvinit='source ~/.pyenv/pyenv_init.bash'
alias screen="TERM=xterm-256color screen" # FIX: xterm-kitty doesn't work
alias vme_console="pio device monitor --raw --eol=CR"
# alias vme_console="screen /dev/ttyUSB0"

# Pass terminfo files for kitty through ssh so colors etc. work.
# if in kitty window
if [ -n "$KITTY_WINDOW_ID" ]; then
    # if connected over ssh already, use TERM=xterm-256color
    if [[ -n "$SSH_CONNECTION" && -n "$SSH_CLIENT" && -n "$SSH_TTY" ]]; then
	alias ssh="env TERM=xterm-256color ssh"
    # if local connection use kitten ssh
    else
	alias ssh="kitten ssh"
    fi
fi

# TODO: make this better...
if [[ $HOSTNAME == "ymir-ln.xray.aps.anl.gov" ]]; then
    alias ls='lsd'
    alias icat='kitten icat'
else
    alias ls='ls --color=auto'
fi
if [ -f /etc/redhat-release ]; then
    release_info=$(cat /etc/redhat-release)
    major_version=$(echo $release_info | grep -oE '[0-9]+' | head -n 1)
    if [ "$major_version" -gt 8 ]; then
        # if which "lsd" &> /dev/null; then
            # alias ls="lsd"
        # fi
        if which "bat" &> /dev/null; then
            alias cat="bat --theme=1337"
        fi
    fi
fi

