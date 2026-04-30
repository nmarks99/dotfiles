---
name: areadetector-plugin
description: Write custom EPICS areaDetector plugins -- NDPluginDriver processing plugins and NDPluginFile file writer plugins with processCallbacks, NDArray handling, multi-threading, and plugin chaining
---

# areaDetector Plugin Skill

You are an expert at writing custom EPICS areaDetector plugins. Plugins process, analyze, transform, or save NDArray image data. There are two base classes:

1. **`NDPluginDriver`** -- Base class for all processing plugins. Override `processCallbacks()`.
2. **`NDPluginFile`** -- Base class for file writer plugins. Override `openFile()`, `writeFile()`, `readFile()`, `closeFile()`.

---

## 1. Plugin Class Hierarchy

```
asynPortDriver
  └── asynNDArrayDriver       (NDArrayPool, file I/O, attributes)
        └── NDPluginDriver      (plugin infrastructure: queue, threading, sorting)
              ├── YourPlugin      (custom processing plugin)
              └── NDPluginFile    (file writer base)
                    └── YourFilePlugin  (custom file writer)
```

---

## 2. Processing Plugin (NDPluginDriver)

### 2.1 Header

```cpp
#include "NDPluginDriver.h"

#define myPluginFirstString "MY_PLUGIN_FIRST"
#define myPluginSecondString "MY_PLUGIN_SECOND"

class myPlugin : public NDPluginDriver {
public:
    myPlugin(const char *portName, int queueSize, int blockingCallbacks,
             const char *NDArrayPort, int NDArrayAddr,
             int maxBuffers, size_t maxMemory,
             int priority, int stackSize);

    /* Pure virtual that MUST be implemented */
    void processCallbacks(NDArray *pArray);

    /* Optional overrides */
    asynStatus writeInt32(asynUser *pasynUser, epicsInt32 value);
    asynStatus writeFloat64(asynUser *pasynUser, epicsFloat64 value);

protected:
    int myPluginFirst_;
    #define FIRST_MY_PLUGIN_PARAM myPluginFirst_
    int myPluginSecond_;
    #define LAST_MY_PLUGIN_PARAM myPluginSecond_
    #define NUM_MY_PLUGIN_PARAMS (&LAST_MY_PLUGIN_PARAM - &FIRST_MY_PLUGIN_PARAM + 1)
};
```

### 2.2 Constructor

```cpp
myPlugin::myPlugin(const char *portName, int queueSize, int blockingCallbacks,
                   const char *NDArrayPort, int NDArrayAddr,
                   int maxBuffers, size_t maxMemory,
                   int priority, int stackSize)
    : NDPluginDriver(
        portName,           /* Plugin port name */
        queueSize,          /* Input queue size */
        blockingCallbacks,  /* 0=non-blocking, 1=blocking */
        NDArrayPort,        /* Upstream data source port */
        NDArrayAddr,        /* Upstream address */
        1,                  /* maxAddr */
        NUM_MY_PLUGIN_PARAMS, /* Additional parameters */
        maxBuffers,         /* Max output buffers */
        maxMemory,          /* Max output memory */
        asynGenericPointerMask,  /* Interface mask */
        asynGenericPointerMask,  /* Interrupt mask */
        0,                  /* asynFlags (0 for plugins) */
        1,                  /* autoConnect */
        priority,           /* Thread priority */
        stackSize)          /* Thread stack size */
{
    /* Create plugin-specific parameters */
    createParam(myPluginFirstString,  asynParamFloat64, &myPluginFirst_);
    createParam(myPluginSecondString, asynParamInt32,   &myPluginSecond_);

    /* Set initial parameter values */
    setDoubleParam(myPluginFirst_, 1.0);
    setIntegerParam(myPluginSecond_, 0);

    /* Set the plugin type for display */
    setStringParam(NDPluginDriverPluginType, "myPlugin");

    callParamCallbacks();
}
```

### 2.3 processCallbacks -- The Core Processing Method

This is called for each incoming NDArray. The base class handles queuing, threading, and sorting.

```cpp
void myPlugin::processCallbacks(NDArray *pArray)
{
    NDArray *pArrayOut = NULL;
    NDArrayInfo_t arrayInfo;
    asynStatus status;

    /* Call the base class method (updates counters, checks for valid array) */
    NDPluginDriver::beginProcessCallbacks(pArray);

    /* Get array info */
    pArray->getInfo(&arrayInfo);

    /* Make a copy if you need to modify the data.
     * If you only read the data, you can use pArray directly. */
    this->pNDArrayPool->copy(pArray, &pArrayOut, 1 /* reserve */);
    if (!pArrayOut) {
        asynPrint(pasynUserSelf, ASYN_TRACE_ERROR,
                  "%s: error copying NDArray\n", driverName);
        NDPluginDriver::endProcessCallbacks(pArray, true /* failure */);
        return;
    }

    /* ---- Your processing code here ---- */

    /* Example: threshold filter */
    double threshold;
    getDoubleParam(myPluginFirst_, &threshold);

    if (arrayInfo.dataType == NDUInt16) {
        epicsUInt16 *pData = (epicsUInt16 *)pArrayOut->pData;
        for (size_t i = 0; i < arrayInfo.nElements; i++) {
            if (pData[i] < (epicsUInt16)threshold) {
                pData[i] = 0;
            }
        }
    }

    /* ---- End processing ---- */

    /* Update output array metadata */
    this->getAttributes(pArrayOut->pAttributeList);
    pArrayOut->pAttributeList->copy(pArray->pAttributeList);

    /* Publish the processed array to downstream plugins */
    NDPluginDriver::endProcessCallbacks(pArrayOut, false /* success */);

    /* Note: endProcessCallbacks calls doCallbacksGenericPointer and
     * releases pArrayOut, so do NOT call release() yourself. */
}
```

### 2.4 Alternative: Read-Only Processing (No Output Array)

If your plugin only computes statistics and does not produce a modified output array:

```cpp
void myStatsPlugin::processCallbacks(NDArray *pArray)
{
    NDPluginDriver::beginProcessCallbacks(pArray);

    /* Compute statistics directly from the input array */
    NDArrayInfo_t info;
    pArray->getInfo(&info);

    double sum = 0;
    if (info.dataType == NDFloat64) {
        double *pData = (double *)pArray->pData;
        for (size_t i = 0; i < info.nElements; i++) {
            sum += pData[i];
        }
    }

    /* Set computed values as parameters */
    setDoubleParam(myPluginFirst_, sum);
    callParamCallbacks();

    /* Pass the unmodified input array downstream */
    NDPluginDriver::endProcessCallbacks(pArray, false);
}
```

### 2.5 Multi-Threaded Processing

Set `maxThreads > 1` in the configure command to enable parallel processing. The base class manages the thread pool. Each `processCallbacks()` invocation runs in its own thread.

When using multiple threads:
- Do NOT access shared mutable state without synchronization.
- Use `lock()`/`unlock()` for parameter access (same as asynPortDriver).
- The `SortMode` parameter controls output ordering:
  - `Sorted` -- reorder output arrays by uniqueId
  - `Unsorted` -- pass through in completion order

---

## 3. File Writer Plugin (NDPluginFile)

### 3.1 Header

```cpp
#include "NDPluginFile.h"

class myFilePlugin : public NDPluginFile {
public:
    myFilePlugin(const char *portName, int queueSize, int blockingCallbacks,
                 const char *NDArrayPort, int NDArrayAddr,
                 int maxBuffers, size_t maxMemory,
                 int priority, int stackSize);

    /* Pure virtual methods -- ALL FOUR must be implemented */
    asynStatus openFile(const char *fileName, NDFileOpenMode_t openMode,
                        NDArray *pArray);
    asynStatus readFile(NDArray **pArray);
    asynStatus writeFile(NDArray *pArray);
    asynStatus closeFile();

private:
    FILE *filePtr_;
    int frameCount_;
};
```

### 3.2 Constructor

```cpp
myFilePlugin::myFilePlugin(const char *portName, int queueSize,
                           int blockingCallbacks, const char *NDArrayPort,
                           int NDArrayAddr, int maxBuffers, size_t maxMemory,
                           int priority, int stackSize)
    : NDPluginFile(
        portName, queueSize, blockingCallbacks,
        NDArrayPort, NDArrayAddr,
        0,                  /* Number of additional params */
        maxBuffers, maxMemory,
        asynGenericPointerMask, asynGenericPointerMask,
        ASYN_CANBLOCK,      /* File I/O is blocking */
        1,                  /* autoConnect */
        priority, stackSize)
    , filePtr_(NULL)
    , frameCount_(0)
{
    /* Set to true if the plugin supports writing multiple arrays to one file */
    this->supportsMultipleArrays = 1;

    setStringParam(NDPluginDriverPluginType, "myFilePlugin");
}
```

### 3.3 openFile

```cpp
asynStatus myFilePlugin::openFile(const char *fileName, NDFileOpenMode_t openMode,
                                   NDArray *pArray)
{
    const char *mode;

    if (openMode & NDFileModeAppend) {
        mode = "ab";
    } else if (openMode & NDFileModeWrite) {
        mode = "wb";
    } else if (openMode & NDFileModeRead) {
        mode = "rb";
    } else {
        return asynError;
    }

    filePtr_ = fopen(fileName, mode);
    if (!filePtr_) {
        asynPrint(pasynUserSelf, ASYN_TRACE_ERROR,
                  "Cannot open file %s\n", fileName);
        return asynError;
    }

    /* Use pArray to get data type and dimensions for file header */
    NDArrayInfo_t info;
    pArray->getInfo(&info);

    /* Write file header based on array info */
    writeHeader(pArray);

    frameCount_ = 0;
    return asynSuccess;
}
```

### 3.4 writeFile

```cpp
asynStatus myFilePlugin::writeFile(NDArray *pArray)
{
    NDArrayInfo_t info;
    pArray->getInfo(&info);

    /* Write the raw pixel data */
    size_t nwritten = fwrite(pArray->pData, 1, info.totalBytes, filePtr_);
    if (nwritten != info.totalBytes) {
        asynPrint(pasynUserSelf, ASYN_TRACE_ERROR,
                  "Write error: wrote %zu of %zu bytes\n", nwritten, info.totalBytes);
        return asynError;
    }

    frameCount_++;
    return asynSuccess;
}
```

### 3.5 readFile

```cpp
asynStatus myFilePlugin::readFile(NDArray **pArray)
{
    /* Read a file and create an NDArray from its contents.
     * This is used by the ReadFile PV. */

    /* Allocate NDArray based on file header */
    size_t dims[2] = {width_, height_};
    *pArray = this->pNDArrayPool->alloc(2, dims, NDUInt16, 0, NULL);
    if (!*pArray) return asynError;

    /* Read pixel data from file */
    fread((*pArray)->pData, 1, dataSize_, filePtr_);

    return asynSuccess;
}
```

### 3.6 closeFile

```cpp
asynStatus myFilePlugin::closeFile()
{
    if (filePtr_) {
        /* Write footer if needed */
        fclose(filePtr_);
        filePtr_ = NULL;
    }
    return asynSuccess;
}
```

### 3.7 supportsMultipleArrays

```cpp
/* In constructor: */
this->supportsMultipleArrays = 1;  /* Supports Capture and Stream modes */
this->supportsMultipleArrays = 0;  /* Only Single mode (one array per file) */
```

When `supportsMultipleArrays = 1`:
- **Capture mode**: `openFile()` called once, `writeFile()` called N times, `closeFile()` called once.
- **Stream mode**: Same as Capture but runs continuously until stopped.

When `supportsMultipleArrays = 0`:
- Only **Single mode**: `openFile()`, `writeFile()` (once), `closeFile()` per frame.

---

## 4. Database Template

### 4.1 Processing Plugin Template

```
# myPlugin.template
include "NDPluginBase.template"

record(ao, "$(P)$(R)Threshold") {
    field(DTYP, "asynFloat64")
    field(OUT,  "@asyn($(PORT),$(ADDR=0),$(TIMEOUT=1))MY_PLUGIN_FIRST")
    field(PREC, "3")
    field(PINI, "YES")
    info(autosaveFields, "VAL")
}

record(ai, "$(P)$(R)Threshold_RBV") {
    field(DTYP, "asynFloat64")
    field(INP,  "@asyn($(PORT),$(ADDR=0),$(TIMEOUT=1))MY_PLUGIN_FIRST")
    field(PREC, "3")
    field(SCAN, "I/O Intr")
}
```

### 4.2 File Writer Plugin Template

```
# myFilePlugin.template
include "NDPluginBase.template"
include "NDFile.template"

# NDFile.template provides: FilePath, FileName, FileNumber, FileTemplate,
# AutoIncrement, AutoSave, WriteFile, ReadFile, FileFormat, FileWriteMode,
# Capture, NumCapture, NumCaptured, WriteStatus, WriteMessage

# Add file-format-specific records here:
record(mbbo, "$(P)$(R)Compression") {
    field(DTYP, "asynInt32")
    field(OUT,  "@asyn($(PORT),$(ADDR=0),$(TIMEOUT=1))MY_COMPRESSION")
    field(ZRST, "None")
    field(ONST, "GZIP")
    field(TWST, "LZ4")
    field(PINI, "YES")
    info(autosaveFields, "VAL")
}
```

---

## 5. IOC Shell Registration

```cpp
extern "C" {

int myPluginConfigure(const char *portName, int queueSize, int blockingCallbacks,
                       const char *NDArrayPort, int NDArrayAddr,
                       int maxBuffers, int maxMemory,
                       int priority, int stackSize)
{
    new myPlugin(portName, queueSize, blockingCallbacks,
                 NDArrayPort, NDArrayAddr,
                 maxBuffers, (size_t)maxMemory, priority, stackSize);
    return asynSuccess;
}

static const iocshArg a0 = {"Port name",          iocshArgString};
static const iocshArg a1 = {"Queue size",         iocshArgInt};
static const iocshArg a2 = {"Blocking callbacks", iocshArgInt};
static const iocshArg a3 = {"NDArray port",       iocshArgString};
static const iocshArg a4 = {"NDArray addr",       iocshArgInt};
static const iocshArg a5 = {"Max buffers",        iocshArgInt};
static const iocshArg a6 = {"Max memory",         iocshArgInt};
static const iocshArg a7 = {"Priority",           iocshArgInt};
static const iocshArg a8 = {"Stack size",         iocshArgInt};
static const iocshArg *args[] = {&a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8};
static const iocshFuncDef configDef = {"myPluginConfigure", 9, args};

static void configCallFunc(const iocshArgBuf *args) {
    myPluginConfigure(args[0].sval, args[1].ival, args[2].ival,
                       args[3].sval, args[4].ival, args[5].ival,
                       args[6].ival, args[7].ival, args[8].ival);
}

static void myPluginRegister(void) {
    iocshRegister(&configDef, configCallFunc);
}

epicsExportRegistrar(myPluginRegister);

}
```

---

## 6. Makefile

```makefile
# Use commonLibraryMakefile for plugins
LIBRARY_IOC += myPlugin

LIB_SRCS += myPlugin.cpp

DBD += myPluginSupport.dbd

include $(ADCORE)/ADApp/commonLibraryMakefile
```

DBD file:
```
registrar(myPluginRegister)
```

---

## 7. Key Rules and Pitfalls

1. **Always call `beginProcessCallbacks(pArray)` at the start** and `endProcessCallbacks(pArrayOut, failed)` at the end of `processCallbacks()`. These handle counter updates, timestamp management, and output array publishing.

2. **Do NOT call `pArrayOut->release()`** after `endProcessCallbacks()`. The base class handles the release. Double-releasing causes crashes.

3. **Use `this->pNDArrayPool->copy()` to make a modifiable copy** of the input array. The input `pArray` may be shared with other plugins and must not be modified in place.

4. **If your plugin does not modify data**, pass the original `pArray` to `endProcessCallbacks(pArray, false)`. It will be forwarded to downstream plugins without copying.

5. **`supportsMultipleArrays` must be set in the constructor** before any file operations. Setting it later has no effect.

6. **File plugins should use `ASYN_CANBLOCK`** in their constructor flags since file I/O is inherently blocking.

7. **Processing plugins should NOT use `ASYN_CANBLOCK`** unless they perform blocking operations. Non-blocking plugins run in the caller's thread context or the plugin's dedicated thread.

8. **The `NDArrayPort` parameter** can be changed at runtime to dynamically switch the upstream data source. Call `connectToArrayPort()` if you need to programmatically change it.

9. **For multi-threaded plugins**, each thread gets its own `processCallbacks()` call. Use the `SortMode` parameter to control whether output is sorted by uniqueId.

10. **`openFile()` receives the first NDArray** as a parameter. Use it to determine the data type, dimensions, and color mode for the file header. Do NOT assume these will be the same for subsequent frames.
