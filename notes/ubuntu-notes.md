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

## Arduino on Ubuntu (22.04)
*This note explains how to setup an Arduino development environment on Ubuntu.*  
*Last Updated: 9-5-2024*

1. Install PlatformIO Core and PlatformIO udev rules
2. Remove brltty with `sudo apt remove brltty` to fix conflict with CH341 driver
3. The following platformio.ini file works for Arduino nano (clone). Using "nanoatmega328"
instead of "nanoatmega328new" will cause weird AVR dude errors.

```bash
### File: platformio.ini
[env:nanoatmega328]
platform = atmelavr
board = nanoatmega328new
framework = arduino
extra_scripts = pre:compiledb.py
```

4. Generate compile_commands.json with the following "compiledb.py" script:
```python
### File: compiledb.py
import os
Import("env")

# include toolchain paths
env.Replace(COMPILATIONDB_INCLUDE_TOOLCHAIN=True)

# override compilation DB path
env.Replace(COMPILATIONDB_PATH=os.path.join("$BUILD_DIR", "compile_commands.json"))
```
To generate compile_commands.json in the .pio/build/TARGET, run `pio run -t compiledb`

## Firefox scroll speed
- Type about:config
- Search for `mousewheel.default.delta_multiplier_y` and decrease it

## Make audio better
Improve audio with this [https://medium.com/@gamunu/enable-high-quality-audio-on-linux-6f16f3fe7e1f](https://medium.com/@gamunu/enable-high-quality-audio-on-linux-6f16f3fe7e1f)

## VirtualBox with UEFI Secure Boot
This [link](https://stackoverflow.com/questions/61248315/sign-virtual-box-modules-vboxdrv-vboxnetflt-vboxnetadp-vboxpci-centos-8) is helpful to sign the vbox modules.

## Use xrandr to mirror display
Have not tried this but this link seems helpful: https://unix.stackexchange.com/questions/371793/how-to-duplicate-desktop-in-linux-with-xrandr
