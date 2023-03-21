#!/usr/bin/env python3
# Note: Requies imagemagick and xclip
import subprocess
import datetime

screenshot_dir_path = "/home/nick/Pictures/Screenshots/"

# Create a timestamp
stamp = datetime.datetime.now()
stamp = stamp.strftime("%m-%d-%Y_%I-%M-%S")
name = "".join([screenshot_dir_path,"screenshot_",stamp,".png"])

# screenshot with imagemagick
subprocess.call(["import",name])

# Get the most recent screenshot
result = subprocess.Popen(
    ["ls -t /home/nick/Pictures/Screenshots/*.png | head -1"],
    shell=True,
    stdout=subprocess.PIPE
)

# copy the image to the clipboard
file = result.stdout.read().decode("utf-8")
file = file.rstrip('\n')
assert result.wait() == 0
result = subprocess.Popen([f"cat {file} | xclip -selection clipboard -target image/png -i"],shell=True)
assert result.wait() == 0

