## Arduino on Linux
*This note explains how to setup an Arduino development environment on Linux.*  
*Last Updated: 9-5-2024*  
*Tested on Ubuntu 22.04*  

1. Install PlatformIO Core and PlatformIO udev rules
2. If on Ubuntu, may need to remove brltty with `sudo apt remove brltty` to fix conflict with CH341 driver
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
