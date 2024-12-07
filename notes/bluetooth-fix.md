Sometimes with `bluetoothctl` I get the error:
"No defaul controller available"

Using the below commands or some combination of them,
I got it to work again:
- `rmmod btusb` (maybe wait a few seconds after running)
- `modprobe btusb`

Enable and restart the bluetooth service
- `systemctl enable bluetooth`
- `systemctl start bluetooth`
- `systemctl restart bluetooth`

Also might have to unblock bluetooth with `rfkill`
