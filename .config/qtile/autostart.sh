#!/usr/bin/env bash 

# Enable tapping and natural scrolling
xinput set-prop "MSFT0001:00 06CB:CD3E Touchpad" "libinput Natural Scrolling Enabled" 1
xinput set-prop "MSFT0001:00 06CB:CD3E Touchpad" "libinput Tapping Enabled" 1

# Start picom compositor
picom -b &

# Start udiskie to automount USB
udiskie &

# Toggle wifi on and off to get it to work for some reason
nmcli radio wifi off
nmcli radio wifi on
