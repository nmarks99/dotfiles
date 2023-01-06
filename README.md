# Linux configuration files and scripts

## Disable Graphical Boot

### Gnome on Xorg

Disable graphical boot by default by running 
`sudo systemctl set-default multi-user`

.xinitrc should contain:
```
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
exec gnome-session
```

### Qtile
`exec qtile start`

## Settings/Tweaks

### Touchpad fix in Qtile
When using Qtile, for some reason the touchpad does not use natural 
scrolling and does not allow tapping. To enable this with libinput, 
I edited /usr/share/X11/xorg.conf.d/40-libinput.conf.

### Firefox scroll speed
- Type about:config
- Search for `mousewheel.default.delta_multiplier_y` and decrease it

### DNS
Apparently Google DNS server is faster: [https://developers.google.com/speed/public-dns](https://developers.google.com/speed/public-dns)

### Make audio better
Improve audio with this [https://medium.com/@gamunu/enable-high-quality-audio-on-linux-6f16f3fe7e1f](https://medium.com/@gamunu/enable-high-quality-audio-on-linux-6f16f3fe7e1f)


### VirtualBox with UEFI Secure Boot
This [link](https://stackoverflow.com/questions/61248315/sign-virtual-box-modules-vboxdrv-vboxnetflt-vboxnetadp-vboxpci-centos-8) is helpful to sign the vbox modules.


## Programs

- [qtile](http://www.qtile.org/): tiling window manager written/configured in python
- [tstock](https://github.com/Gbox4/tstock): stock charts in terminal
- [bitwise](https://github.com/mellowcandle/bitwise): bitwise calculations and conversions
- preload: quickstart apps with RAM
- [TLP](https://linrunner.de/tlp/installation/ubuntu.html): battery saver
- [ksuperkey](https://github.com/hanschen/ksuperkey): remap windows key
- [kitty](https://github.com/kovidgoyal/kitty): terminal emulator
- [spotifytui](https://github.com/Rigellute/spotify-tui): spotify player in terminal
- [spotifyd](https://github.com/Spotifyd/spotifyd): spotify client as a unix daemon
- [cava](https://github.com/karlstav/cava): terminal audio visualizer
- [neofetch](https://github.com/dylanaraps/neofetch): display system info
- [onefetch](https://github.com/o2sh/onefetch): display github repo info
- [bottom](https://github.com/ClementTsang/bottom): display cpu stats etc.
- [cowsay](https://github.com/piuccio/cowsay): print messages said by a cow
- [cmatrix](https://github.com/abishekvashok/cmatrix): display matrix animation
- [onedrive](https://github.com/abraunegg/onedrive): cli OneDrive client
- [polybar](https://github.com/polybar/polybar): highly customizable top status bar
- [GTK Title Bar](https://extensions.gnome.org/extension/1732/gtk-title-bar/): hide title bars in gnome/mutter
- [neovim](https://github.com/neovim/neovim): vim editor but better
- [pureline](https://github.com/chris-marsh/pureline): terminal prompt that looks cool
- [zathura](https://pwmt.org/projects/zathura/): pdf reader
- [rofi](https://github.com/davatorium/rofi): app launcher
- [spicetify](https://github.com/spicetify/spicetify-cli): customize spotify client
- [Pywal](https://github.com/dylanaraps/pywal): wallpaper/theme setter
- [figlet](https://github.com/cmatsuoka/figlet): ASCII text banners in terminal


## Appearence/Themes
- [Layan dark theme](https://www.gnome-look.org/p/1309214/)
