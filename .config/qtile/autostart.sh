#!/usr/bin/env bash 

# Enable tapping and natural scrolling
xinput set-prop "MSFT0001:00 06CB:CD3E Touchpad" "libinput Natural Scrolling Enabled" 1
xinput set-prop "MSFT0001:00 06CB:CD3E Touchpad" "libinput Tapping Enabled" 1

# Start picom compositor
picom -b &

# Start udiskie to automount USB
udiskie &
