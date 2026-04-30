---
name: areadetector-ioc
description: Configure and deploy EPICS areaDetector IOCs -- plugin chain configuration, database templates, commonPlugins.cmd, file writing patterns, st.cmd startup scripts, and build configuration
---

# areaDetector IOC Skill

You are an expert at configuring and deploying EPICS areaDetector IOCs. You understand the plugin chain architecture, all standard database templates, the commonPlugins.cmd pattern, file writing configuration, and build system dependencies.

---

## 1. Plugin Architecture Overview

An areaDetector IOC consists of:
1. **One detector driver** -- produces NDArrays (images)
2. **Multiple plugins** -- process, analyze, display, or save the images
3. **Plugin chains** -- plugins connect to the detector or to upstream plugins via port name

```
Detector (PORT=DET1)
  ├── NDStdArrays (Image1)     → waveform PVs for live display
  ├── NDStats (Stats1)         → statistics (min, max, mean, centroid)
  ├── NDROI (ROI1)             → region of interest
  │     └── NDStats (Stats2)   → statistics on the ROI
  ├── NDProcess (Proc1)        → background subtraction, flat field
  ├── NDFileHDF5 (HDF1)        → HDF5 file writer
  ├── NDFileTIFF (TIFF1)       → TIFF file writer
  ├── NDOverlay (Over1)        → graphical overlays
  └── NDPva (Pva1)             → PV Access image output
```

Each plugin's `NDArrayPort` parameter specifies which upstream port it receives data from.

---

## 2. Plugin Configuration Commands

All plugins follow a consistent configuration pattern in st.cmd:

```
PluginConfigure("portName", queueSize, blockingCallbacks, "NDArrayPort", NDArrayAddr, maxBuffers, maxMemory, priority, stackSize)
```

### 2.1 Standard Plugin Configure Commands

| Plugin | Configure Command | Purpose |
|--------|------------------|---------|
| NDStdArrays | `NDStdArraysConfigure` | Waveform PV output for live display |
| NDStats | `NDStatsConfigure` | Image statistics (min/max/mean/sigma/centroid/histogram) |
| NDROI | `NDROIConfigure` | Region of interest extraction |
| NDROIStat | `NDROIStatConfigure` | Multiple ROIs with statistics |
| NDProcess | `NDProcessConfigure` | Background subtraction, flat field, filtering |
| NDTransform | `NDTransformConfigure` | Image rotation and mirroring |
| NDOverlay | `NDOverlayConfigure` | Graphical overlays (cross, rectangle, text) |
| NDColorConvert | `NDColorConvertConfigure` | Color mode conversion |
| NDCodec | `NDCodecConfigure` | Compression/decompression (JPEG, Blosc, LZ4) |
| NDFFT | `NDFFTConfigure` | Fast Fourier Transform |
| NDTimeSeries | `NDTimeSeriesConfigure` | Time series data collection |
| NDCircularBuff | `NDCircularBuffConfigure` | Pre/post-trigger circular buffer |
| NDPluginAttribute | `NDAttrConfigure` | Extract attribute values |
| NDAttrPlot | `NDAttrPlotConfigure` | Plot attribute values |
| NDBadPixel | `NDBadPixelConfigure` | Bad pixel correction |
| NDScatter | `NDScatterConfigure` | Round-robin scatter to multiple plugins |
| NDGather | `NDGatherConfigure` | Gather from multiple sources |
| NDPosPlugin | `NDPosPluginConfigure` | Position tagging |
| NDFileHDF5 | `NDFileHDF5Configure` | HDF5 file writer |
| NDFileTIFF | `NDFileTIFFConfigure` | TIFF file writer |
| NDFileJPEG | `NDFileJPEGConfigure` | JPEG file writer |
| NDFileNetCDF | `NDFileNetCDFConfigure` | NetCDF file writer |
| NDFileNexus | `NDFileNexusConfigure` | NeXus file writer |
| NDFileMagick | `NDFileMagickConfigure` | GraphicsMagick multi-format writer |
| NDPva | `NDPvaConfigure` | PV Access NTNDArray output |

### 2.2 Configure Command Arguments

| # | Argument | Typical Value | Description |
|---|----------|---------------|-------------|
| 1 | portName | `"Image1"` | Unique asyn port name for this plugin |
| 2 | queueSize | 20 | Input queue depth for NDArrays |
| 3 | blockingCallbacks | 0 | 0=non-blocking, 1=blocking |
| 4 | NDArrayPort | `"DET1"` | Port name of upstream data source |
| 5 | NDArrayAddr | 0 | Address on upstream port |
| 6 | maxBuffers | 0 | Max output buffers (0=unlimited) |
| 7 | maxMemory | 0 | Max output memory (0=unlimited) |
| 8 | priority | 0 | Thread priority (0=default) |
| 9 | stackSize | 0 | Thread stack size (0=default) |

Some plugins have additional arguments. For example:
```
NDStdArraysConfigure("Image1", 3, 0, "DET1", 0, 0, 0, 0, 0)
NDStatsConfigure("Stats1", 20, 0, "DET1", 0, 0, 0, 0, 0, 0, 0)
NDROIConfigure("ROI1", 20, 0, "DET1", 0, 0, 0, 0, 0, 0)
NDFileHDF5Configure("HDF1", 20, 0, "DET1", 0, 0, 0, 0, 0)
```

---

## 3. Database Template Reference

### 3.1 Template Hierarchy

```
NDArrayBase.template         (common to all -- array params, pool stats, callbacks)
  ├── ADBase.template         (detector-specific: gain, binning, ROI, shutter, status)
  │     └── myDetector.template   (driver-specific: include "ADBase.template")
  └── NDPluginBase.template   (plugin-specific: upstream port, queue, threading)
        ├── NDStats.template
        ├── NDROI.template
        ├── NDStdArrays.template
        ├── NDProcess.template
        ├── NDFileHDF5.template (also includes NDFile.template)
        └── ... (all plugin templates)
```

### 3.2 Common Template Macros

All templates use these macros:

| Macro | Description | Example |
|-------|-------------|---------|
| `P` | PV prefix | `"13SIM1:"` |
| `R` | PV record prefix | `"cam1:"` |
| `PORT` | Plugin/driver asyn port name | `"DET1"` |
| `ADDR` | asyn address | `0` |
| `TIMEOUT` | asyn timeout (seconds) | `1` |

Plugin templates add:

| Macro | Description | Example |
|-------|-------------|---------|
| `NDARRAY_PORT` | Upstream data source port | `"DET1"` |
| `NDARRAY_ADDR` | Upstream address | `0` |
| `ENABLED` | Enable callbacks at startup | `1` |

### 3.3 Loading Templates in st.cmd

```bash
## Detector
dbLoadRecords("$(MYDETECTOR)/db/myDetector.template",
    "P=$(PREFIX),R=cam1:,PORT=$(PORT),ADDR=0,TIMEOUT=1")

## NDStdArrays -- waveform for live image display
dbLoadRecords("$(ADCORE)/db/NDStdArrays.template",
    "P=$(PREFIX),R=image1:,PORT=Image1,ADDR=0,TIMEOUT=1,NDARRAY_PORT=$(PORT),TYPE=Int16,FTVL=SHORT,NELEMENTS=$(NELEMENTS)")

## NDStats -- image statistics
dbLoadRecords("$(ADCORE)/db/NDStats.template",
    "P=$(PREFIX),R=Stats1:,PORT=Stats1,ADDR=0,TIMEOUT=1,NDARRAY_PORT=$(PORT),NCHANS=$(NCHANS),XSIZE=$(XSIZE),YSIZE=$(YSIZE)")

## NDROI -- region of interest
dbLoadRecords("$(ADCORE)/db/NDROI.template",
    "P=$(PREFIX),R=ROI1:,PORT=ROI1,ADDR=0,TIMEOUT=1,NDARRAY_PORT=$(PORT)")

## NDFileHDF5 -- HDF5 file writer
dbLoadRecords("$(ADCORE)/db/NDFileHDF5.template",
    "P=$(PREFIX),R=HDF1:,PORT=HDF1,ADDR=0,TIMEOUT=1,NDARRAY_PORT=$(PORT)")

## NDOverlay -- overlays
dbLoadRecords("$(ADCORE)/db/NDOverlay.template",
    "P=$(PREFIX),R=Over1:,PORT=Over1,ADDR=0,TIMEOUT=1,NDARRAY_PORT=$(PORT)")
dbLoadRecords("$(ADCORE)/db/NDOverlayN.template",
    "P=$(PREFIX),R=Over1:,NAME=ROI1,SHAPE=1,O=Over1:,XPOS=$(P)$(R)ROI1:MinX_RBV,YPOS=$(P)$(R)ROI1:MinY_RBV,XSIZE=$(P)$(R)ROI1:SizeX_RBV,YSIZE=$(P)$(R)ROI1:SizeY_RBV,PORT=Over1,ADDR=0,TIMEOUT=1")
```

### 3.4 NDStdArrays Macros

| Macro | Description | Values |
|-------|-------------|--------|
| `TYPE` | asyn array type suffix | `Int8`, `Int16`, `Int32`, `Int64`, `Float32`, `Float64` |
| `FTVL` | Waveform field type | `CHAR`, `SHORT`, `LONG`, `FLOAT`, `DOUBLE` |
| `NELEMENTS` | Waveform max elements | `XSIZE * YSIZE` (mono) or `XSIZE * YSIZE * 3` (RGB) |

---

## 4. Complete st.cmd Example

```bash
#!../../bin/linux-x86_64/myDetectorApp

< envPaths

dbLoadDatabase("$(TOP)/dbd/myDetectorApp.dbd")
myDetectorApp_registerRecordDeviceDriver(pdbbase)

#-----------------------------------------------------------------------
# Environment variables
#-----------------------------------------------------------------------
epicsEnvSet("PREFIX",    "13DET1:")
epicsEnvSet("PORT",      "DET1")
epicsEnvSet("QSIZE",     "20")
epicsEnvSet("XSIZE",     "1024")
epicsEnvSet("YSIZE",     "1024")
epicsEnvSet("NCHANS",    "2048")
epicsEnvSet("NELEMENTS", "1048576")  # XSIZE * YSIZE

#-----------------------------------------------------------------------
# Create the detector driver
#-----------------------------------------------------------------------
myDetectorConfig("$(PORT)", "commPort", $(XSIZE), $(YSIZE), 0, 0, 0, 0, 0)
dbLoadRecords("$(MYDETECTOR)/db/myDetector.template",
    "P=$(PREFIX),R=cam1:,PORT=$(PORT),ADDR=0,TIMEOUT=1")

#-----------------------------------------------------------------------
# Load standard plugins via commonPlugins.cmd
#-----------------------------------------------------------------------
< $(ADCORE)/iocBoot/commonPlugins.cmd

#-----------------------------------------------------------------------
# Custom plugin configuration (beyond commonPlugins)
#-----------------------------------------------------------------------
# Additional ROI on the first ROI output
NDROIConfigure("ROI2", $(QSIZE), 0, "ROI1", 0, 0, 0)
dbLoadRecords("$(ADCORE)/db/NDROI.template",
    "P=$(PREFIX),R=ROI2:,PORT=ROI2,ADDR=0,TIMEOUT=1,NDARRAY_PORT=ROI1")

#-----------------------------------------------------------------------
# IOC init
#-----------------------------------------------------------------------
cd "${TOP}/iocBoot/${IOC}"
iocInit

#-----------------------------------------------------------------------
# Post-init commands
#-----------------------------------------------------------------------
# Autosave restore
< save_restore.cmd
```

---

## 5. commonPlugins.cmd

Most areaDetector IOCs include `$(ADCORE)/iocBoot/commonPlugins.cmd`, which creates a standard set of plugins using environment variables:

**Required environment variables:**
- `PREFIX` -- PV prefix
- `PORT` -- detector port name
- `QSIZE` -- queue size for plugins
- `XSIZE`, `YSIZE` -- image dimensions
- `NCHANS` -- number of histogram/time-series channels
- `NELEMENTS` -- waveform array size (XSIZE * YSIZE)

**Plugins created by commonPlugins.cmd:**
- `Image1` (NDStdArrays) -- 8-bit image waveform
- `Stats1`-`Stats5` (NDStats)
- `ROI1`-`ROI4` (NDROI)
- `Proc1` (NDProcess)
- `Trans1` (NDTransform)
- `Over1` (NDOverlay) with 8 overlay instances
- `CC1`, `CC2` (NDColorConvert)
- `TIFF1` (NDFileTIFF)
- `JPEG1` (NDFileJPEG)
- `Nexus1` (NDFileNexus)
- `HDF1` (NDFileHDF5)
- `Magick1` (NDFileMagick)
- `NetCDF1` (NDFileNetCDF)
- `FFT1` (NDFFT)
- `Codec1` (NDCodec)
- `Pva1` (NDPva) -- if WITH_PVA=YES
- `CB1` (NDCircularBuff)
- `Attr1` (NDPluginAttribute)
- `BadPix1` (NDBadPixel)
- `Scatter1` (NDScatter)

---

## 6. File Writing Configuration

### 6.1 Key File Template Fields

| PV Suffix | Field | Description |
|-----------|-------|-------------|
| `FilePath` | Octet | Directory path (must exist, use CreateDirectory to auto-create) |
| `FileName` | Octet | Base file name |
| `FileNumber` | Int32 | Current file number |
| `FileTemplate` | Octet | C printf format string (e.g., `"%s%s_%4.4d.h5"`) |
| `FullFileName_RBV` | Octet | Complete constructed file path (read-only) |
| `AutoIncrement` | Bo | Auto-increment FileNumber (Yes/No) |
| `AutoSave` | Bo | Auto-save after each acquire (Yes/No) |
| `FileWriteMode` | Mbbo | `Single`, `Capture`, `Stream` |
| `NumCapture` | Longout | Number of frames to capture (Capture/Stream mode) |
| `Capture` | Busy | Start capture/stream (1=start, 0=stop) |
| `WriteFile` | Busy | Write single file |
| `ReadFile` | Busy | Read a file into NDArray |
| `LazyOpen` | Bo | Delay file open until first frame |
| `TempSuffix` | Stringout | Temporary suffix during write (e.g., `.tmp`) |
| `CreateDirectory` | Longout | Auto-create directory depth (-1=all, 0=none, N=N levels) |

### 6.2 FileTemplate Format

The `FileTemplate` uses C printf format with three arguments: `(FilePath, FileName, FileNumber)`:

```
%s%s_%4.4d.h5        → /data/test_0001.h5
%s%s_%6.6d.tif       → /data/image_000001.tif
%s%s.h5              → /data/myfile.h5  (no number)
```

### 6.3 File Write Modes

| Mode | Behavior |
|------|----------|
| `Single` | Write one frame per file when WriteFile=1 or AutoSave=Yes |
| `Capture` | Buffer NumCapture frames in memory, write all to one file |
| `Stream` | Write frames continuously to one file as they arrive |

### 6.4 HDF5-Specific Features

```
dbLoadRecords("$(ADCORE)/db/NDFileHDF5.template",
    "P=$(PREFIX),R=HDF1:,PORT=HDF1,ADDR=0,TIMEOUT=1,NDARRAY_PORT=$(PORT)")
```

HDF5 adds: SWMR mode (simultaneous read/write), dataset chunking, compression (zlib, szip, blosc, LZ4, BSLZ4), XML layout files for custom HDF5 structure, attribute datasets, and ND attribute storage.

---

## 7. Build Configuration

### 7.1 IOC Makefile (src/Makefile)

```makefile
TOP = ../..
include $(TOP)/configure/CONFIG

PROD_IOC = myDetectorApp

DBD += myDetectorApp.dbd
myDetectorApp_DBD += base.dbd
myDetectorApp_DBD += myDetectorSupport.dbd

# ADCore plugins and support (using the commonDriverMakefile pattern)
include $(ADCORE)/ADApp/commonDriverMakefile

myDetectorApp_SRCS += myDetectorApp_registerRecordDeviceDriver.cpp
myDetectorApp_SRCS_DEFAULT += myDetectorAppMain.cpp
myDetectorApp_SRCS_vxWorks += -nil-

myDetectorApp_LIBS += myDetector

include $(TOP)/configure/RULES
```

### 7.2 configure/RELEASE

```makefile
# Required
ADCORE    = /path/to/ADCore
ADSUPPORT = /path/to/ADSupport
ASYN      = /path/to/asyn

# Optional (for commonPlugins.cmd features)
AUTOSAVE    = /path/to/autosave
BUSY        = /path/to/busy
CALC        = /path/to/calc
SSCAN       = /path/to/sscan
DEVIOCSTATS = /path/to/devIocStats

EPICS_BASE = /path/to/base
```

### 7.3 CONFIG_SITE.local -- Feature Flags

```makefile
# Enable/disable optional features
WITH_PVA  = YES       # PV Access support (NDPluginPva, pvaDriver)
WITH_HDF5 = YES       # HDF5 file plugin
WITH_JPEG = YES       # JPEG file plugin
WITH_TIFF = YES       # TIFF file plugin
WITH_NETCDF = YES     # NetCDF file plugin
WITH_NEXUS = YES      # NeXus file plugin
WITH_GRAPHICSMAGICK = YES  # GraphicsMagick file plugin
WITH_BLOSC = YES      # Blosc compression for HDF5
WITH_ZLIB = YES       # zlib compression
WITH_SZIP = YES       # SZIP compression
WITH_JSON = YES       # JSON support (for bad pixel files)

# Use external system libraries (YES) or build from ADSupport (NO)
HDF5_EXTERNAL = NO
JPEG_EXTERNAL = NO
TIFF_EXTERNAL = NO
XML2_EXTERNAL = NO
ZLIB_EXTERNAL = NO
SZIP_EXTERNAL = NO
```

---

## 8. Plugin Chaining Patterns

### 8.1 ROI → Stats (Statistics on a Region)

```
NDROIConfigure("ROI1", 20, 0, "DET1", 0, 0, 0)
NDStatsConfigure("ROIStat1", 20, 0, "ROI1", 0, 0, 0)
```

Stats plugin reads from ROI plugin output instead of directly from detector.

### 8.2 Process → FileWriter (Save Processed Images)

```
NDProcessConfigure("Proc1", 20, 0, "DET1", 0, 0, 0)
NDFileHDF5Configure("HDF1", 20, 0, "Proc1", 0, 0, 0)
```

### 8.3 Detector → Codec → NDPva (Compressed PVA Output)

```
NDCodecConfigure("Codec1", 20, 0, "DET1", 0, 0, 0)
NDPvaConfigure("Pva1", 20, 0, "Codec1", 0, 0, 0, 0, 0, 0)
```

### 8.4 Dynamic Port Switching

Plugins can change their upstream source at runtime by writing to the `NDArrayPort` PV:

```
caput 13DET1:Stats1:NDArrayPort "ROI1"    # Switch to reading from ROI
caput 13DET1:Stats1:NDArrayPort "DET1"    # Switch back to detector
```

---

## 9. Key Rules and Pitfalls

1. **Set `NELEMENTS` correctly** for NDStdArrays. For monochrome: `XSIZE * YSIZE`. For RGB1: `XSIZE * YSIZE * 3`. Too small causes truncated images; too large wastes memory.

2. **`TYPE` and `FTVL` must match** in NDStdArrays.template. Int8→CHAR, Int16→SHORT, Int32→LONG, Float32→FLOAT, Float64→DOUBLE.

3. **Plugin `NDArrayPort` must match an existing port name.** Typos cause silent failures with "0 arrays received".

4. **`EnableCallbacks` must be set to 1** on each plugin for it to receive data. The `ENABLED` macro in templates defaults to 0 in some configurations.

5. **`blockingCallbacks=0` (non-blocking)** is recommended for most plugins. Use `blockingCallbacks=1` only when the plugin must process every frame and the detector can wait (e.g., file writers in Stream mode with hardware triggering).

6. **Queue size** determines how many frames a plugin can buffer. If the queue fills, frames are dropped (counted in `DroppedArrays`). Increase for slow plugins or fast cameras.

7. **File path must exist** before writing. Use `CreateDirectory=-1` to auto-create the full path, or check `FilePathExists_RBV`.

8. **HDF5 Stream mode** creates one file and appends frames. Set `NumCapture` to the expected total frames. Use `LazyOpen=1` and `Capture=1` before starting acquisition.

9. **commonPlugins.cmd** expects specific environment variables. If any are missing, the IOC fails to load with cryptic macro substitution errors.

10. **The `ADDR` parameter** is typically 0 for all plugins and detector. Multi-address is rarely used in areaDetector (unlike motor drivers).
