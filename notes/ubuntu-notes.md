# Ubuntu Notes (22.04)

## Fonts
Fonts are stored in /usr/share/fonts/ 

Here is are the fonts that are needed for now
- JetBrainsMono Nerd Font
- Iosevka Nerd Font
- Monoid Nerd Font

## Fix clangd missing C++ headers
On Ubuntu 22.04, clangd in neovim couldn't find the system headers.
`sudo apt install libstdc++-12-dev` seemed to fix the issue.

## Fix CH341 Drivers
This driver should be already installed on ubuntu 22.04, but there is a bug
that causes the braille display program `brltty` which is also preinstalled
to break it. To fix it you should just be able to do `sudo apt remove brltty`.
See this stack exchange post: [https://askubuntu.com/questions/1403705/dev-ttyusb0-not-present-in-ubuntu-22-04](https://askubuntu.com/questions/1403705/dev-ttyusb0-not-present-in-ubuntu-22-04)

## Fix bluetooth controller missing
[https://askubuntu.com/questions/1486697/cannot-toggle-bluetooth-at-all-in-ubuntu-22-04](https://askubuntu.com/questions/1486697/cannot-toggle-bluetooth-at-all-in-ubuntu-22-04)

`sudo uname -r`

`sudo apt install --reinstall linux-modules-extra-6.5.0-26-generic`

`sudo modprobe -v btusb`

`sudo modprobe -r btusb && sleep 10 && sudo modprobe btusb reset=1`

## Firefox scroll speed
- Type about:config
- Search for `mousewheel.default.delta_multiplier_y` and decrease it

## Make audio better
Improve audio with this [https://medium.com/@gamunu/enable-high-quality-audio-on-linux-6f16f3fe7e1f](https://medium.com/@gamunu/enable-high-quality-audio-on-linux-6f16f3fe7e1f)

## VirtualBox with UEFI Secure Boot
This [link](https://stackoverflow.com/questions/61248315/sign-virtual-box-modules-vboxdrv-vboxnetflt-vboxnetadp-vboxpci-centos-8) is helpful to sign the vbox modules.

## Use xrandr to mirror display
Have not tried this but this link seems helpful: https://unix.stackexchange.com/questions/371793/how-to-duplicate-desktop-in-linux-with-xrandr
