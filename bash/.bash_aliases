alias start='gio open 2>/dev/null'
alias firefox="${HOME}/.local/bin/firefox/firefox"
alias dotfiles="/usr/bin/git --git-dir=${HOME}/.dotfiles --work-tree=${HOME}"
alias newest="ls -lt | head -1 | awk '{print \$NF}'"
alias libcheck="ldconfig -p | grep ${1}"
alias clipboard='tr -d "\n" | xclip -selection clipboard'
alias screen="TERM=xterm-256color screen" # FIX: xterm-kitty doesn't work
# alias pyenvinit='source ~/.pyenv/pyenv_init.bash'

# TODO: make this better...
if [[ $HOSTNAME == "ymir-ln.xray.aps.anl.gov" ]]; then
    alias ls='lsd'
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
