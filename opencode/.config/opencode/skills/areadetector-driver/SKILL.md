---
name: areadetector-driver
description: Write EPICS areaDetector camera/detector drivers -- ADDriver subclasses, NDArray allocation and lifecycle, acquisition thread patterns, image modes, shutter control, and iocsh registration
---

# areaDetector Driver Skill

You are an expert at writing EPICS areaDetector drivers for cameras and imaging detectors. An areaDetector driver is a C++ class that inherits from `ADDriver` (which inherits from `asynNDArrayDriver`, which inherits from `asynPortDriver`). It acquires image data from hardware and publishes it as `NDArray` objects to downstream plugins.

---

## 1. Class Hierarchy

```
asynPortDriver           (asyn parameter library, virtual read/write methods)
  └── asynNDArrayDriver   (NDArrayPool, file I/O, array attributes, common params)
        └── ADDriver       (detector-specific: gain, binning, ROI, image mode, shutter)
              └── YourDriver  (hardware-specific implementation)
```

---

## 2. Headers and Linking

```cpp
#include "ADDriver.h"
```

```makefile
# In src/Makefile:
LIBRARY_IOC += myDetector

LIB_SRCS += myDetector.cpp

INC += myDetector.h

DBD += myDetectorSupport.dbd

include $(ADCORE)/ADApp/commonDriverMakefile
```

The `commonDriverMakefile` handles linking against ADCore, asyn, and all required support libraries. You do NOT need to manually list `_LIBS` for ADCore dependencies.

DBD file:
```
registrar(myDetectorRegister)
```

---

## 3. NDArray Data Types and Color Modes

### 3.1 Data Types (NDDataType_t)

| Enum | Value | C Type | Bytes |
|------|-------|--------|-------|
| `NDInt8` | 0 | epicsInt8 | 1 |
| `NDUInt8` | 1 | epicsUInt8 | 1 |
| `NDInt16` | 2 | epicsInt16 | 2 |
| `NDUInt16` | 3 | epicsUInt16 | 2 |
| `NDInt32` | 4 | epicsInt32 | 4 |
| `NDUInt32` | 5 | epicsUInt32 | 4 |
| `NDInt64` | 6 | epicsInt64 | 8 |
| `NDUInt64` | 7 | epicsUInt64 | 8 |
| `NDFloat32` | 8 | epicsFloat32 | 4 |
| `NDFloat64` | 9 | epicsFloat64 | 8 |

### 3.2 Color Modes (NDColorMode_t)

| Enum | Description | Dimensions |
|------|-------------|------------|
| `NDColorModeMono` | Monochrome | [SizeX, SizeY] (2D) |
| `NDColorModeRGB1` | RGB pixel-interleaved | [3, SizeX, SizeY] (3D) |
| `NDColorModeRGB2` | RGB row-interleaved | [SizeX, 3, SizeY] (3D) |
| `NDColorModeRGB3` | RGB plane-interleaved | [SizeX, SizeY, 3] (3D) |
| `NDColorModeBayer` | Bayer mosaic | [SizeX, SizeY] (2D) |
| `NDColorModeYUV444` | YUV 4:4:4 | [3, SizeX, SizeY] (3D) |
| `NDColorModeYUV422` | YUV 4:2:2 | [2, SizeX, SizeY] (3D) |
| `NDColorModeYUV411` | YUV 4:1:1 | [SizeX, SizeY] (2D) |

---

## 4. Key ADDriver Parameters

### 4.1 Acquisition Control

| Parameter String | Type | Description |
|-----------------|------|-------------|
| `ADAcquire` | Int32 | Start (1) / Stop (0) acquisition |
| `ADAcquireBusy` | Int32 | Busy flag during acquisition |
| `ADImageMode` | Int32 | Single (0), Multiple (1), Continuous (2) |
| `ADTriggerMode` | Int32 | Internal (0), External (1) |
| `ADNumExposures` | Int32 | Exposures per image |
| `ADNumImages` | Int32 | Total images to acquire (Multiple mode) |
| `ADAcquireTime` | Float64 | Exposure time (seconds) |
| `ADAcquirePeriod` | Float64 | Period between images (seconds) |
| `ADNumExposuresCounter` | Int32 | Current exposure count (read-only) |
| `ADNumImagesCounter` | Int32 | Current image count (read-only) |
| `ADTimeRemaining` | Float64 | Time remaining in exposure |

### 4.2 Detector Configuration

| Parameter String | Type | Description |
|-----------------|------|-------------|
| `ADGain` | Float64 | Detector gain |
| `ADBinX` / `ADBinY` | Int32 | Binning factors |
| `ADMinX` / `ADMinY` | Int32 | ROI start position |
| `ADSizeX` / `ADSizeY` | Int32 | ROI size |
| `ADMaxSizeX` / `ADMaxSizeY` | Int32 | Maximum detector size |
| `ADReverseX` / `ADReverseY` | Int32 | Flip image axes |
| `ADFrameType` | Int32 | Normal (0), Background (1), FlatField (2), DblCorrelation (3) |
| `ADTemperature` | Float64 | Set temperature |
| `ADTemperatureActual` | Float64 | Actual temperature (read-only) |

### 4.3 Status

| Parameter String | Type | Description |
|-----------------|------|-------------|
| `ADStatus` | Int32 | Detector state (ADStatus_t enum) |
| `ADStatusMessage` | Octet | Status message string |
| `ADStringToServer` | Octet | Last command sent to hardware |
| `ADStringFromServer` | Octet | Last response from hardware |

**ADStatus_t values:** `ADStatusIdle` (0), `ADStatusAcquire` (1), `ADStatusReadout` (2), `ADStatusCorrect` (3), `ADStatusSaving` (4), `ADStatusAborting` (5), `ADStatusError` (6), `ADStatusWaiting` (7), `ADStatusInitializing` (8), `ADStatusDisconnected` (9), `ADStatusAborted` (10).

### 4.4 Shutter Control

| Parameter String | Type | Description |
|-----------------|------|-------------|
| `ADShutterMode` | Int32 | None (0), EPICS PV (1), Detector (2) |
| `ADShutterControl` | Int32 | Open (1), Close (0) |
| `ADShutterControlEPICS` | Int32 | EPICS shutter PV control |
| `ADShutterStatus` | Int32 | Open (1), Closed (0) |
| `ADShutterOpenDelay` | Float64 | Delay after open (seconds) |
| `ADShutterCloseDelay` | Float64 | Delay after close (seconds) |

### 4.5 Array/NDArray Common Parameters (from asynNDArrayDriver)

| Parameter String | Type | Description |
|-----------------|------|-------------|
| `NDArraySizeX` / `Y` / `Z` | Int32 | Actual array dimensions |
| `NDArraySize` | Int32 | Total array size in bytes |
| `NDDataType` | Int32 | NDDataType_t enum |
| `NDColorMode` | Int32 | NDColorMode_t enum |
| `NDArrayCounter` | Int32 | Image counter |
| `NDArrayCallbacks` | Int32 | Enable (1) / Disable (0) array callbacks |
| `NDUniqueId` | Int32 | Unique array ID |
| `NDTimeStamp` | Float64 | Array timestamp |
| `NDNDimensions` | Int32 | Number of dimensions |
| `NDFilePath` | Octet | File save path |
| `NDFileName` | Octet | File name base |
| `NDFileNumber` | Int32 | File number |
| `NDAttributesFile` | Octet | XML attributes file path |
| `NDPoolMaxMemory` | Float64 | Max pool memory (bytes) |
| `NDPoolUsedMemory` | Float64 | Used pool memory (bytes) |

---

## 5. NDArray Lifecycle

### 5.1 Allocating an NDArray

```cpp
/* 2D monochrome image */
int ndims = 2;
size_t dims[2];
dims[0] = sizeX;
dims[1] = sizeY;

NDArray *pArray = this->pNDArrayPool->alloc(ndims, dims, NDUInt16, 0, NULL);
if (!pArray) {
    asynPrint(pasynUserSelf, ASYN_TRACE_ERROR,
              "%s: error allocating NDArray\n", driverName);
    setIntegerParam(ADStatus, ADStatusError);
    callParamCallbacks();
    return asynError;
}
```

For RGB images:
```cpp
/* RGB1: pixel-interleaved [3, SizeX, SizeY] */
int ndims = 3;
size_t dims[3] = {3, sizeX, sizeY};
NDArray *pArray = this->pNDArrayPool->alloc(ndims, dims, NDUInt8, 0, NULL);
```

### 5.2 Filling the NDArray

```cpp
/* Copy raw data from hardware buffer into NDArray */
memcpy(pArray->pData, hardwareBuffer, dataSize);

/* Or fill directly */
epicsUInt16 *pData = (epicsUInt16 *)pArray->pData;
for (int y = 0; y < sizeY; y++) {
    for (int x = 0; x < sizeX; x++) {
        pData[y * sizeX + x] = readPixel(x, y);
    }
}
```

### 5.3 Setting Array Metadata

```cpp
/* Set unique ID and timestamps */
pArray->uniqueId = imageCounter;
pArray->timeStamp = startTime;
updateTimeStamp(&pArray->epicsTS);

/* Get array info (sets colorMode, dimension info, etc.) */
NDArrayInfo_t arrayInfo;
pArray->getInfo(&arrayInfo);

/* Set array-level parameters */
setIntegerParam(NDArraySize,  (int)arrayInfo.totalBytes);
setIntegerParam(NDArraySizeX, (int)dims[0]);
setIntegerParam(NDArraySizeY, (int)dims[1]);
setIntegerParam(NDDataType,   NDUInt16);
setIntegerParam(NDColorMode,  NDColorModeMono);
setIntegerParam(NDUniqueId,   pArray->uniqueId);
setDoubleParam(NDTimeStamp,   pArray->timeStamp);
```

### 5.4 Adding Attributes

```cpp
/* Attributes loaded from XML file are added automatically via: */
getAttributes(pArray->pAttributeList);

/* Add driver-specific attributes manually */
double temperature;
getDoubleParam(ADTemperatureActual, &temperature);
pArray->pAttributeList->add("Temperature", "Detector temperature",
                             NDAttrFloat64, &temperature);
```

### 5.5 Publishing to Plugins (Callbacks)

```cpp
/* Update counters */
int imageCounter;
getIntegerParam(NDArrayCounter, &imageCounter);
imageCounter++;
setIntegerParam(NDArrayCounter, imageCounter);
setIntegerParam(ADNumImagesCounter, imageCounter);

/* Publish the array to all registered plugins */
callParamCallbacks();
doCallbacksGenericPointer(pArray, NDArrayData, 0);

/* Release the array (decrement reference count) */
pArray->release();
```

**CRITICAL:** Always call `pArray->release()` after `doCallbacksGenericPointer()`. Plugins that need the array will call `reserve()` to increment the reference count. When the reference count reaches 0, the array is returned to the pool.

---

## 6. Acquisition Thread Pattern

```cpp
static void acquireTaskC(void *drvPvt)
{
    myDetector *pPvt = (myDetector *)drvPvt;
    pPvt->acquireTask();
}

void myDetector::acquireTask()
{
    int acquire, imageMode, numImages, imageCounter;
    double acquireTime, acquirePeriod, elapsedTime, delay;
    epicsTimeStamp startTime, endTime;
    int status = asynSuccess;

    lock();

    while (1) {
        /* Wait for the acquire command */
        while (1) {
            getIntegerParam(ADAcquire, &acquire);
            if (acquire) break;
            unlock();
            epicsEventWait(startEventId_);
            lock();
        }

        /* Get acquisition parameters */
        getIntegerParam(ADImageMode, &imageMode);
        getIntegerParam(ADNumImages, &numImages);
        getDoubleParam(ADAcquireTime, &acquireTime);
        getDoubleParam(ADAcquirePeriod, &acquirePeriod);

        /* Reset counters */
        setIntegerParam(ADNumImagesCounter, 0);
        setIntegerParam(ADStatus, ADStatusAcquire);
        callParamCallbacks();

        /* Acquisition loop */
        while (1) {
            epicsTimeGetCurrent(&startTime);

            /* === Acquire one image from hardware === */
            unlock();
            status = acquireImage(acquireTime);
            lock();

            if (status != asynSuccess) {
                setIntegerParam(ADAcquire, 0);
                setIntegerParam(ADStatus, ADStatusError);
                setStringParam(ADStatusMessage, "Acquisition error");
                callParamCallbacks();
                break;
            }

            /* Allocate, fill, and publish the NDArray (see Section 5) */
            publishImage();

            /* Check if acquisition is complete */
            getIntegerParam(ADNumImagesCounter, &imageCounter);
            getIntegerParam(ADAcquire, &acquire);

            if (!acquire) break;  /* User stopped acquisition */

            if (imageMode == ADImageSingle) break;
            if (imageMode == ADImageMultiple && imageCounter >= numImages) break;
            /* ADImageContinuous: continue forever */

            /* Inter-frame delay */
            epicsTimeGetCurrent(&endTime);
            elapsedTime = epicsTimeDiffInSeconds(&endTime, &startTime);
            delay = acquirePeriod - elapsedTime;
            if (delay > 0.0) {
                unlock();
                epicsEventWaitWithTimeout(stopEventId_, delay);
                lock();
            }
        }

        /* Acquisition complete */
        setIntegerParam(ADAcquire, 0);
        setIntegerParam(ADStatus, ADStatusIdle);
        callParamCallbacks();
    }
}
```

---

## 7. Constructor Pattern

```cpp
myDetector::myDetector(const char *portName, const char *commPort,
                       int maxSizeX, int maxSizeY, NDDataType_t dataType,
                       int maxBuffers, size_t maxMemory,
                       int priority, int stackSize)
    : ADDriver(
        portName,          /* Port name */
        1,                 /* maxAddr */
        NUM_MY_PARAMS,     /* Number of additional parameters */
        maxBuffers,        /* Max NDArray buffers in pool (0 = unlimited) */
        maxMemory,         /* Max NDArray pool memory (0 = unlimited) */
        asynGenericPointerMask,  /* Additional interface mask */
        asynGenericPointerMask,  /* Additional interrupt mask */
        ASYN_CANBLOCK,     /* asynFlags (CANBLOCK for blocking I/O) */
        1,                 /* autoConnect */
        priority,          /* Priority (0 = default) */
        stackSize)         /* Stack size (0 = default) */
{
    /* Create driver-specific parameters */
    createParam("MY_PARAM", asynParamFloat64, &myParam_);

    /* Set detector information */
    setStringParam(ADManufacturer, "My Company");
    setStringParam(ADModel, "Model X");
    setIntegerParam(ADMaxSizeX, maxSizeX);
    setIntegerParam(ADMaxSizeY, maxSizeY);
    setIntegerParam(ADSizeX, maxSizeX);
    setIntegerParam(ADSizeY, maxSizeY);
    setIntegerParam(NDDataType, dataType);
    setIntegerParam(NDColorMode, NDColorModeMono);
    setIntegerParam(ADImageMode, ADImageContinuous);
    setIntegerParam(ADStatus, ADStatusIdle);

    /* Create events for acquisition thread synchronization */
    startEventId_ = epicsEventCreate(epicsEventEmpty);
    stopEventId_  = epicsEventCreate(epicsEventEmpty);

    /* Connect to hardware (if network-based) */
    pasynOctetSyncIO->connect(commPort, 0, &pasynUserComm_, NULL);

    /* Create the acquisition thread */
    epicsThreadCreate("myDetAcquire",
        epicsThreadPriorityMedium,
        epicsThreadGetStackSize(epicsThreadStackMedium),
        acquireTaskC, this);

    callParamCallbacks();
}
```

---

## 8. writeInt32 Override

```cpp
asynStatus myDetector::writeInt32(asynUser *pasynUser, epicsInt32 value)
{
    int function = pasynUser->reason;
    asynStatus status = asynSuccess;

    /* Set the parameter value in the library */
    status = ADDriver::writeInt32(pasynUser, value);

    if (function == ADAcquire) {
        if (value) {
            /* Start acquisition -- signal the acquire thread */
            epicsEventSignal(startEventId_);
        } else {
            /* Stop acquisition -- signal the stop event */
            epicsEventSignal(stopEventId_);
        }
    }
    else if (function == ADImageMode) {
        /* Handle image mode change */
    }
    else if (function == myParam_) {
        /* Handle driver-specific parameter */
    }

    callParamCallbacks();
    return status;
}
```

---

## 9. Shutter Control

```cpp
void myDetector::setShutter(int open)
{
    /* Call base class to handle EPICS PV shutter and delays */
    ADDriver::setShutter(open);

    int shutterMode;
    getIntegerParam(ADShutterMode, &shutterMode);

    if (shutterMode == ADShutterModeDetector) {
        /* Control hardware shutter directly */
        if (open) {
            sendCommand("SHUTTER OPEN");
        } else {
            sendCommand("SHUTTER CLOSE");
        }
    }
    /* For ADShutterModeEPICS, the base class handles it via PV */
    /* For ADShutterModeNone, nothing to do */
}
```

---

## 10. Database Template

```
# myDetector.template
include "ADBase.template"

# Driver-specific records
record(ao, "$(P)$(R)MyParam") {
    field(DTYP, "asynFloat64")
    field(OUT,  "@asyn($(PORT),$(ADDR=0),$(TIMEOUT=1))MY_PARAM")
    field(PREC, "3")
    field(PINI, "YES")
    info(autosaveFields, "VAL")
}

record(ai, "$(P)$(R)MyParam_RBV") {
    field(DTYP, "asynFloat64")
    field(INP,  "@asyn($(PORT),$(ADDR=0),$(TIMEOUT=1))MY_PARAM")
    field(PREC, "3")
    field(SCAN, "I/O Intr")
}
```

The `include "ADBase.template"` line pulls in all standard detector records (acquire, image mode, gain, binning, ROI, status, shutter, temperature, etc.).

---

## 11. IOC Shell Registration

```cpp
extern "C" {

int myDetectorConfig(const char *portName, const char *commPort,
                      int maxSizeX, int maxSizeY, int dataType,
                      int maxBuffers, int maxMemory,
                      int priority, int stackSize)
{
    new myDetector(portName, commPort, maxSizeX, maxSizeY,
                   (NDDataType_t)dataType, maxBuffers, (size_t)maxMemory,
                   priority, stackSize);
    return asynSuccess;
}

static const iocshArg arg0 = {"Port name",     iocshArgString};
static const iocshArg arg1 = {"Comm port",     iocshArgString};
static const iocshArg arg2 = {"Max X size",    iocshArgInt};
static const iocshArg arg3 = {"Max Y size",    iocshArgInt};
static const iocshArg arg4 = {"Data type",     iocshArgInt};
static const iocshArg arg5 = {"Max buffers",   iocshArgInt};
static const iocshArg arg6 = {"Max memory",    iocshArgInt};
static const iocshArg arg7 = {"Priority",      iocshArgInt};
static const iocshArg arg8 = {"Stack size",    iocshArgInt};
static const iocshArg *args[] = {&arg0, &arg1, &arg2, &arg3,
                                  &arg4, &arg5, &arg6, &arg7, &arg8};
static const iocshFuncDef configDef = {"myDetectorConfig", 9, args};

static void configCallFunc(const iocshArgBuf *args) {
    myDetectorConfig(args[0].sval, args[1].sval, args[2].ival, args[3].ival,
                      args[4].ival, args[5].ival, args[6].ival, args[7].ival,
                      args[8].ival);
}

static void myDetectorRegister(void) {
    iocshRegister(&configDef, configCallFunc);
}

epicsExportRegistrar(myDetectorRegister);

}
```

---

## 12. Key Rules and Pitfalls

1. **Always call `pArray->release()`** after `doCallbacksGenericPointer()`. Failure to release causes pool exhaustion and acquisition stops.

2. **Hold the driver lock** when accessing parameters and NDArrayPool, but **release it during blocking I/O** (e.g., waiting for hardware readout). The lock/unlock pattern around blocking calls prevents the entire IOC from stalling.

3. **Set `ADStatus` appropriately**: Idle when not acquiring, Acquire during exposure, Readout during data transfer, Error on failure. Plugins and GUIs rely on this.

4. **Set `ADAcquire = 0`** when acquisition completes (Single/Multiple modes) or on error. The motor record pattern of "done when idle" applies here too.

5. **The `maxBuffers` and `maxMemory` constructor arguments** limit the NDArrayPool size. Set to 0 for unlimited (but beware of memory exhaustion with fast cameras).

6. **Use `getAttributes(pArray->pAttributeList)`** to load attributes from the XML file configured by the user. Call this before `doCallbacksGenericPointer()`.

7. **`doCallbacksGenericPointer(pArray, NDArrayData, 0)`** is the function that pushes the NDArray to all connected plugins. The third argument (0) is the address.

8. **Image dimensions** must be set correctly: `NDArraySizeX`, `NDArraySizeY`, `NDArraySizeZ` (for RGB), `NDDataType`, `NDColorMode`. Plugins use these to configure themselves.

9. **Use `commonDriverMakefile`** instead of manually listing ADCore/asyn libraries. It handles all platform-specific library dependencies.

10. **The `startEventId_` / `stopEventId_` pattern** is standard for acquisition thread control. Signal `startEventId_` from `writeInt32(ADAcquire, 1)` and `stopEventId_` from `writeInt32(ADAcquire, 0)`.
