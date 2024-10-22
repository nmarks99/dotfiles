alias start='gio open 2>/dev/null'
alias firefox="${HOME}/.local/bin/firefox/firefox"
alias dotfiles="/usr/bin/git --git-dir=${HOME}/.dotfiles --work-tree=${HOME}"
# alias newest="ls -Art | tail -n 1"
alias newest="ls -lt | head -1 | awk '{print \$NF}'"
alias libcheck="ldconfig -p | grep ${1}"
alias clipboard='tr -d "\n" | xclip -selection clipboard'
# alias pyenvinit='source ~/.pyenv/pyenv_init.bash'

alias ls='ls --color'

# TODO: make this better...
if [ -f /etc/redhat-release ]; then
    release_info=$(cat /etc/redhat-release)
    major_version=$(echo $release_info | grep -oE '[0-9]+' | head -n 1)
    if [ "$major_version" -gt 8 ]; then
        if which "lsd" &> /dev/null; then
            alias ls="lsd"
        fi
        if which "bat" &> /dev/null; then
            alias cat="bat --paging=never"
        fi
    fi
fi
