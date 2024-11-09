# Linux configuration files and scripts
*Arch Linux*

GNU stow is used to manage dotfiles. Simply run `stow <package>` to
symlink a package to its correct location. E.g. `stow kitty` will create a
symbolic link in ~/.config/kitty/kitty.conf -> dotfiles/kitty/.config/kitty/kitty.conf
