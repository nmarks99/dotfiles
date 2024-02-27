# automatically source .bashrc when in interactive
# shell on host ymir-ln
if [ -n "$BASH_VERSION" -a -n "$PS1" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        if [[ $(hostname) == *ymir-ln* ]]; then
            . "$HOME/.bashrc"
        fi
    fi
fi
