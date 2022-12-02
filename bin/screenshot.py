#!/usr/bin/env python3
import subprocess
import datetime

screenshot_dir_path = "/home/nick/Pictures/Screenshots/"

# Create a timestamp
stamp = datetime.datetime.now()
stamp = stamp.strftime("%m-%d-%Y_%I-%M-%S")
name = "".join([screenshot_dir_path,"screenshot_",stamp,".png"])

subprocess.call(["import",name]) # screenshot with imagemagick
