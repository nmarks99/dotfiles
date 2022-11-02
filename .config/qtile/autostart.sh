#!/usr/bin/env bash 
picom -b & # start picom
autorandr -c # run autorandr to autodetect monitor
~/.config/polybar/launch.sh --shapes # start polybar

