#!/usr/bin/env bash 
DIR=${PWD##*/}
MATCH="GitHub"

if [ "$DIR" = "$MATCH" ]; then
   xdg-open "https://www.github.com" 
else
   xdg-open $(git config remote.origin.url)
fi

