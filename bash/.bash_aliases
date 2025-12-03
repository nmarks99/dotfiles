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

# temporarily using nvim on /local/nmarks since NFS is slow!
#function nvim() {
#   export XDG_CONFIG_HOME="/local/nmarks/local-nvim/config"
#   export XDG_DATA_HOME="/local/nmarks/local-nvim/share"
#   /local/nmarks/local-nvim/nvim-bin "$@"
# }

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
            alias cat="bat --theme=base16"
        fi
    fi
fi

