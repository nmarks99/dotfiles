# Bluetooth
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

# Sinks
In theory much of this should handle itself automatically
or you should be able to do it through pavucontrol, but
pavucontrol always seems to freeze my computer

After headphones are connected:
```
$ pactl list short sinks
53	alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI3__sink	PipeWire	s24-32le 2ch 48000Hz	SUSPENDED
54	alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI2__sink	PipeWire	s24-32le 2ch 48000Hz	SUSPENDED
55	alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI1__sink	PipeWire	s24-32le 2ch 48000Hz	SUSPENDED
56	alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink	PipeWire	s32le 2ch 48000Hz	SUSPENDED
92	bluez_output.C8_7B_23_A5_B5_7C.1	PipeWire	s16le 2ch 48000Hz	SUSPENDED
```

Set headphones to default sink:
```
$ pactl set-default-sink bluez_output.C8_7B_23_A5_B5_7C.1
```

Test them:
```
$ speaker-test -t wav -c 2
```

Move existing audio streams to the headphones sink. I think this should be done
automatically if the stream is restarted but that didn't seem to work for me.
```
$ pactl list short sink-inputs
165	92	141	PipeWire	float32le 2ch 48000Hz

$ pactl move-sink-input 165 bluez_output.C8_7B_23_A5_B5_7C.1 
```


