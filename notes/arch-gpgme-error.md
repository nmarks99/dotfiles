This error came up randomly when running `sudo pacman -Sy`:
```
error: GPGME error: No data
error: GPGME error: No data
error: GPGME error: No data
error: failed to synchronize all databases (invalid or corrupted database (PGP signature))
```

To fix it do the following:

1. Regenerate a pacman mirror list from here: https://archlinux.org/mirrorlist/

2. Replace /etc/pacman.d/mirrorlist with the generated mirror list. Uncomment each server

3. Regenerate the keys for pacman by deleting the stored secrets:
```
sudo rm -rf /etc/pacman.d/gnupg
sudo rm -R /var/lib/pacman/sync

sudo pacman-key --init
sudo pacman-key --populate
```

Source: https://vadosware.io/post/fixing-gpgme-error-on-arch/
