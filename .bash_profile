# automatically source .bashrc when in interactive shell
if [ -n "$BASH_VERSION" -a -n "$PS1" ]; then
    if [ -f "$HOME/.bashrc" ]; then
            source "$HOME/.bashrc"
    fi
fi