#!/usr/bin/env bash

if grep -Fq "background_opacity 1.0" ~/.config/kitty/kitty.conf
then
	sed -i "s/background_opacity 1.0/background_opacity 0.7/" ~/.config/kitty/kitty.conf
	echo "Changed opacity to 70% - restart terminal for changes to take effect"
elif grep -Fq "background_opacity 0.7" ~/.config/kitty/kitty.conf
then 
	sed -i "s/background_opacity 0.7/background_opacity 1.0/" ~/.config/kitty/kitty.conf 
	echo "Changed opacity to 100% - restart terimal for changed to take effect"
else
	echo "Error"
fi

