---
name: epics-lua
description: Write Lua scripts and records for EPICS IOCs -- luascriptRecord expressions, Lua shell startup scripts, Lua device support (DTYP "lua"), luaPortDriver definitions, and built-in library usage (epics, asyn, db, osi, event, seq, bytestream)
---

# EPICS Lua Skill

You are an expert at writing Lua-based logic for EPICS IOCs using the lua EPICS module (release 4-0). This module embeds Lua 5.4 into an IOC and exposes four capabilities:

1. **luascriptRecord** -- a scriptable record type (like calcout/scalcout but using Lua)
2. **Lua Device Support (DTYP "lua")** -- standard records (ai, bi, ao, etc.) backed by Lua functions
3. **luaPortDriver** -- generate an asynPortDriver entirely from a Lua script
4. **Lua Shell** -- use Lua as the IOC startup script language (st.lua instead of st.cmd)

All four share a set of built-in Lua libraries: `epics`, `asyn`, `db`, `iocsh`, `osi`, `event`, `seq`, and `bytestream`.

---

## 1. luascriptRecord

The `luascript` record has 10 double input fields (A-J, fetched from INPA-INPJ) and 10 string input fields (AA-JJ, fetched from INAA-INJJ). These are pushed as Lua globals before each execution.

The record has three output values:
- **VAL** (double) -- set when the Lua code returns a number or boolean
- **SVAL** (string, 256 chars) -- set when the Lua code returns a string
- **AVAL** (array) -- set when the Lua code returns a table of numbers; ATYP selects Int/Double/Char element type

When writing to the OUT link, the record chooses VAL, SVAL, or AVAL based on the target field's data type.

### 1.1 CODE Field

The CODE field (120-char limit) accepts either inline Lua or a file reference:

**Inline expression:**
```
field(CODE, "return A + B")
field(CODE, "return AA .. BB")
```

**External file reference:**
```
field(CODE, "@script.lua functionName")
field(CODE, "@script.lua functionName(1, 'foo')")
```

The `@` prefix tells the record to search `LUA_SCRIPT_PATH` (and paths registered via `luaAddPath`/`luaAddModule`) for the file. A space separates the filename from the function name. Parameters in parentheses are passed to the function on each processing.

Use external files for anything beyond trivial one-liners. The 120-character CODE limit makes inline code impractical for real logic, and external files allow persistent state, reusable functions, and `require` for libraries.

### 1.2 RELO Field (Reload Behavior)

Controls when the Lua state is recompiled on CODE changes:

| Value | Behavior |
|-------|----------|
| `Every New File` | Recompile only if the referenced file changes. Changing to a different function in the same file preserves state. |
| `Every New Change` | Recompile on any CODE field change. |
| `Every Processing` | Recompile before every processing. |

The FRLD field forces a one-shot recompile when written with a non-zero value.

### 1.3 Process Condition (POPT / PCAL)

The POPT field controls whether CODE runs every time the record processes or only when a condition is met:

| Value | Behavior |
|-------|----------|
| `Always` | CODE runs every time (default). |
| `Conditional` | CODE runs only when PCAL evaluates to a truthy value. |

The PCAL field holds a Lua expression (no `return` needed) evaluated before CODE. It has access to all input globals (A-J, AA-JJ) and to **changed flags**:

| Changed Flag | True when... |
|--------------|-------------|
| `_A` through `_J` | The corresponding numeric input value changed since last process |
| `_AA` through `_JJ` | The corresponding string input value changed since last process |

For array inputs, the changed flag is always true (no element-level detection).

PCAL is pre-compiled for efficiency and recompiled when PCAL or CODE changes.

**Examples:**
```
field(POPT, "Conditional")
field(PCAL, "_A")
```
Only run CODE when input A changes.

```
field(POPT, "Conditional")
field(PCAL, "_A and A > 0")
```
Run CODE when A changes AND its value is positive.

### 1.4 Output Parameters

| Field | Description |
|-------|-------------|
| OUT | Output link for the result |
| OOPT | When to write: `Every Time`, `On Change`, `When Zero`, `When Non-zero`, `Transition To Zero`, `Transition To Non-zero`, `Never` |
| SYNC | `Sync` (process Lua in the record's thread) or `Async` (process in an EPICS callback thread) |
| IVOA | Invalid output action when Lua fails: `Continue normally` (default), `Don't drive outputs`, `Set output to IVOV` |
| IVOV | Value to write when IVOA is `Set output to IVOV` (applies only to VAL, not SVAL or AVAL) |

### 1.5 Other Fields

| Field | Description |
|-------|-------------|
| ERR | String (256 chars) containing the last Lua error encountered during processing |
| PREC | Display precision for VAL |
| HIHI/HIGH/LOW/LOLO | Alarm limits for VAL |
| HHSV/HSV/LSV/LLSV | Alarm severities |
| HYST | Alarm deadband |
| ATYP | Array output type: Int, Double, or Char |
| ADSC-JDSC | Description labels for numeric inputs A-J |
| AADN-JJDN | Description labels for string inputs AA-JJ |
| EGU | Engineering units for VAL |
| HOPR/LOPR | High/low operating range |
| MDEL/ADEL | Monitor/archive deadband |

### 1.6 Implicit Lua Globals

Before each processing, the following globals are available in the Lua state:

- `A` through `J` -- current values of numeric inputs
- `AA` through `JJ` -- current values of string inputs
- `_A` through `_J` -- boolean changed flags for numeric inputs
- `_AA` through `_JJ` -- boolean changed flags for string inputs
- `self` -- the record name as a string

The luascriptRecord does NOT support `SCAN = "I/O Intr"`.

---

## 2. Lua Device Support (DTYP "lua")

Standard EPICS records can use `DTYP = "lua"` to have their read/write handled by a Lua function.

### 2.1 Supported Record Types

ai, ao, bi, bo, longin, longout, mbbi, mbbo, stringin, stringout

### 2.2 INP/OUT Field Format

```
field(DTYP, "lua")
field(INP,  "@script.lua function_name(param1, param2)")
field(INP,  "@NAMED_STATE function_name(param1)")
```

The source (after `@`) can be either:

- **A script file** -- located via `LUA_SCRIPT_PATH` and paths registered with `luaAddPath`/`luaAddModule`. A new Lua state is created and the file is loaded.
- **A named state** -- if the name does not resolve to a file on disk, it is looked up as a Lua state registered with `luaRegisterState()`. This allows records to call functions in a state created by `luaLoadFile`, sharing variables and module-level state.

Named states are the recommended pattern when using `db.record` from Lua to create records and define their callbacks in the same file.

### 2.3 Function Signature

```lua
function myfunction(record, param1, param2, ...)
```

- `record` -- a PV object representing the calling record (same type as `epics.pv()`)
- `param1, param2, ...` -- values from the parenthesized parameter list in the INP/OUT field

### 2.4 The PV Object

The PV object provides field access. For local PVs, access uses direct database access (`dbGetField`/`dbPutField`). For remote PVs, Channel Access is used automatically.

```lua
local val = record.VAL          -- read a field
local egu = record.EGU          -- read another field

record.DESC = "new desc"        -- write a field

local name = record.name        -- PV name (read-only property)
print(tostring(record))         -- also returns PV name
```

Methods for fine-grained control:
```lua
local val = record:get("VAL", {timeout=5.0, count=100})
record:put("VAL", 42, {timeout=5.0})
```

Reserved names: `name`, `get`, `put` return PV metadata or methods. All other keys are treated as EPICS field names.

### 2.5 Return Value

**Input records** (ai, bi, longin, mbbi, stringin): The return value sets the record's value.
- Return a number to set VAL/RVAL (depending on record type)
- Return a string for bi (compared to ZNAM/ONAM), mbbi (compared to state strings), or stringin
- Return `nil` to leave the record unchanged

**Output records** (ao, bo, longout, mbbo, stringout): The return value is ignored. The function is invoked for its side effects. For ao, return `nil` to indicate success; any other return type triggers WRITE_ALARM.

### 2.6 Error Handling

If a callback raises a Lua error, the record is placed into alarm (READ_ALARM or WRITE_ALARM with INVALID severity). The error message is printed to the IOC console. This means library functions that raise errors on failure (such as `bytestream.client:read()`) automatically put the calling record into alarm without explicit error handling.

---

## 3. Lua Port Drivers

Lua-based asynPortDrivers can be created entirely from Lua scripts. There are two approaches:

### 3.1 asyn.driver.new (Recommended)

Create a driver using the asyn library's Lua API:

```lua
local asyn = require("asyn")
local Int32, Float64, Octet = asyn.Int32, asyn.Float64, asyn.Octet

local drv = asyn.driver.new(PORT, {
    Float64 "TEMPERATURE" (0.0),
    Float64 "SETPOINT"    (25.0),
    Int32   "ENABLED"     (0),
    Octet   "STATUS"      ("OK"),
}, function(self)
    self.port = asyn.client(DEVICE_PORT, 0, "")
    self.conversion = tonumber(CONV) or 1.0
end)
```

| Argument | Type | Description |
|----------|------|-------------|
| portName | string | The asyn port name for the new driver |
| paramTable | table | Array of parameter specs from `asyn.Int32`, `asyn.Float64`, or `asyn.Octet` |
| initFunc | function | Optional. Receives the driver proxy as its argument |

**Returns:** a driver proxy object.

#### Type Constructors

```lua
asyn.Int32   "PARAM_NAME" [(default_value)]
asyn.Float64 "PARAM_NAME" [(default_value)]
asyn.Octet   "PARAM_NAME" [(default_value)]
```

The optional parenthesized default value sets the parameter's initial value.

#### Parameter Proxy

Access parameters through the driver proxy by name:

```lua
drv.PARAM.value          -- read the current parameter value
drv.PARAM.value = x      -- write a new value + call param callbacks
drv.PARAM.name           -- the parameter name string
```

#### Binding Callbacks

```lua
drv.PARAM.read = function(self)
    -- self is the driver proxy
    -- Return the value to send back to the reader
    return some_value
end

drv.PARAM.write = function(value, self)
    -- value is the incoming value from the writer
    -- self is the driver proxy
    drv.PARAM.value = value
end
```

Callbacks can only be bound on drivers created with `asyn.driver.new`, not on drivers found with `asyn.driver.find`.

#### Driver Proxy Properties and Methods

| Access | Description |
|--------|-------------|
| `drv.portName` | Read-only: port name string |
| `drv.maxAddr` | Read-only: max address |
| `drv.PARAM_NAME` | Returns a parameter proxy |
| `drv:callParamCallbacks()` | Trigger asyn param callbacks |
| `drv:writeParam(name, value)` | Write a parameter by name |
| `drv:readParam(name)` | Read a parameter by name |
| `drv.anyfield = val` | Store persistent internal state |

Internal state fields do not conflict with parameter names. Parameters are accessed via `drv.PARAM.value`; internal state via `self.fieldname`.

#### Finding Existing Drivers

```lua
local drv = asyn.driver("MYPORT")
local drv = asyn.driver.find("MYPORT")

print(drv.TEMPERATURE.value)
drv.SETPOINT.value = 25.0
```

### 3.2 luaPortDriver iocsh Command (Legacy)

```
luaPortDriver("PORTNAME", "driver.lua", "P=prefix:,R=suffix:,START=10")
```

| Argument | Description |
|----------|-------------|
| Port name | The asyn port name for the new driver |
| Script file | Lua file found via `LUA_SCRIPT_PATH` |
| Macros | Comma-separated key=value pairs, available as globals in the script |

Parameters are defined using the `param` global DSL:

```lua
param.int32 "PARAM_NAME"
param.float64 "PARAM_NAME"
param.octet "PARAM_NAME"
param.string "PARAM_NAME"     -- alias for octet

param.float64.read "PARAM_NAME" [[
    return math.sqrt(self["BASE"]^2 + self["SIDE"]^2)
]]

param.int32.write "PARAM_NAME" [[
    out_val = out_val + value
    self:writeParam("CURR_VAL", out_val)
    self:callParamCallbacks()
]]
```

Inside legacy callback code blocks, `self` is a driver proxy, `value` (write only) is the incoming value, `PORT` is the port name, and all macro variables are globals.

### 3.3 Inline Record Creation with db.record

Both APIs commonly use `db.record()` to create EPICS records in the same script:

```lua
local db = require("db")

db.record("ai", P .. R .. "Value") {
    DTYP = "asynFloat64",
    SCAN = "I/O Intr",
    INP = "@asyn(" .. PORT .. ",0,0)TEMPERATURE",
    PINI = "1",
}
```

---

## 4. Lua Shell

### 4.1 Shell Commands

The Lua shell provides five commands with different execution models:

| Command | Runs in | Execution | Line echoing | iocsh fallback |
|---------|---------|-----------|-------------|----------------|
| `luash "file"` | Calling shell state | Synchronous, line-by-line | Yes | Yes |
| `< file` | Calling shell state | Synchronous, line-by-line | Yes | Yes |
| `luaLoadFile "file"` | New state | Synchronous, whole file | No | **No** |
| `luaSpawn "file"` | New state, background thread | Whole file | No | **No** |
| `luaCmd "code"` | New state | Synchronous, single statement | No | Yes |

**iocsh fallback** means undefined global variable lookups automatically resolve to EPICS environment variables and iocsh-registered functions (e.g., `dbLoadRecords`, `epicsEnvSet`). Only `luash`, `luaCmd`, and the `<` include directive have this. Scripts run via `luaLoadFile` and `luaSpawn` do **not** -- use the `db`, `iocsh`, or `epics` Lua libraries instead (e.g., `db.loadRecords()` instead of `dbLoadRecords()`).

Commands that run in the **calling shell** share variables, loaded modules, and function definitions with the shell session. Commands that run in a **new state** start fresh -- pass configuration via macros.

Because `luash` executes each line as a separate statement, `local` variables do not persist between lines. Use global variables, or use `luaLoadFile` which compiles the entire file as one chunk.

All commands accept macros as either a string or a Lua table:
```lua
luaLoadFile("driver.lua", "P=dev1:,PORT=SENSOR1")
luaLoadFile("driver.lua", {P="dev1:", PORT="SENSOR1"})
```

### 4.2 Implicit iocsh Environment (luash and luaCmd only)

Within `luash` and `luaCmd`, global variable lookups that don't match a Lua variable automatically search:
1. EPICS environment variables
2. iocsh-registered functions

This fallback is **not** available in `luaLoadFile` or `luaSpawn`. In those contexts, use the Lua libraries directly (e.g., `db.loadRecords()`, `iocsh.dbLoadRecords()`, `epics.get()`).

In `luash`, iocsh functions can be called as if they were Lua functions:

```lua
epicsEnvSet("LUA_SCRIPT_PATH", "./scripts")

dbLoadDatabase("../../dbd/myApp.dbd")
myApp_registerRecordDeviceDriver(pdbbase)
dbLoadRecords("./my.db", "P=test:,R=x:")
iocInit()
dbl()
```

Environment variables are accessible by name:

```lua
local ver = EPICS_VERSION_MAJOR    -- reads the environment variable
```

These are read-only lookups. Assigning to a name creates a Lua variable and does not modify the environment.

### 4.3 Hash Comments

The directive `#ENABLE_HASH_COMMENTS` at the start of a script makes the shell accept iocsh-style `#` comments. This only applies to lines where `#` is the first non-whitespace character.

```lua
#ENABLE_HASH_COMMENTS

# This comment will be echoed in file mode
#- This comment is silent (not echoed)
print(#"This still works")  -- prints 15 (string length)
```

Blank lines in file mode are also elided from output.

### 4.4 Include Directive

The `<` character includes another Lua script at the insertion point:

```lua
< load_databases.lua
```

The included file is found via `LUA_SCRIPT_PATH` and registered paths.

### 4.5 Named States

By default, a Lua state created by `luaLoadFile` or `luaSpawn` is closed when the script finishes. Call `luaRegisterState` to make the state persistent and referenceable:

```lua
luaRegisterState("mydevice")
```

Named states are referenced using the `@name` syntax in luascript CODE fields and DTYP INP/OUT fields. When the name after `@` does not resolve to a file, it is looked up as a named state.

The typical pattern is a single file loaded via `luaLoadFile` that registers its state, creates records with `db.record`, and defines the callback functions those records reference:

```lua
luaRegisterState(PORT)

function read_value()
    return client:write("MEAS?"):read("%f")
end

db.record("ai", P .. "reading") {
    DTYP = "lua",
    INP  = "@" .. PORT .. " read_value()",
    SCAN = "1 second",
}
```

Each call to `luaLoadFile` with the same script but different macros creates a separate named state.

### 4.6 luaAddPath / luaAddModule

```lua
luaAddPath("/path/to/lua/scripts")
luaAddModule("$(LUA)")
```

`luaAddPath` registers a directory for both `require()` (package.path/cpath) and script file resolution.

`luaAddModule` reads `EPICS_HOST_ARCH` and adds `<top>/lib/<arch>/` and `<top>/bin/<arch>/` via `luaAddPath`. Required for `require("bytestream")`, `require("seq")`, and other installed Lua libraries.

### 4.7 info() Function

Available in all Lua states for discoverability:

```lua
info(epics)       -- lists available functions in the epics library
info(pv_object)   -- lists methods and properties of a PV object
info(drv)         -- lists driver proxy methods
```

### 4.8 exit

A line containing only `exit` breaks from the current script level and returns to the caller. It does not terminate the IOC. Works inside conditionals and loops.

### 4.9 luashSetCommonState

Sets a default Lua environment shared across multiple `luash` calls. Without this, each call gets an independent Lua state.

```c++
#include "luaShell.h"

int main(int argc, char *argv[])
{
    luashSetCommonState("default");

    if (argc >= 2) {
        luash(argv[1]);
        epicsThreadSleep(.2);
    }
    luash(NULL);
    epicsExit(0);
    return 0;
}
```

---

## 5. Built-in Libraries

### 5.1 epics Library

Loaded with `epics = require("epics")`.

#### epics.get

```lua
local val = epics.get("PV:NAME")
local val = epics.get("PV:NAME", 5.0)            -- with timeout
local arr = epics.get("PV:waveform", {count=100}) -- array with count limit
local lbl = epics.get("PV:mbbo", {string=true})   -- enum as label string
```

Options table fields: `timeout` (seconds, default 1.0), `count` (max elements, default all), `string` (bool, controls enum-as-label and char-array-as-string).

For local PVs, uses direct database access. For remote PVs, falls through to Channel Access automatically.

Returns value on success. Returns `nil, "error message"` on failure.

Char waveforms are returned as Lua strings by default. Use `{string=false}` for a table of byte values.

#### epics.put

```lua
epics.put("PV:NAME", 42)
epics.put("PV:NAME", 42, 5.0)                    -- with timeout
epics.put("PV:waveform", {1.0, 2.0, 3.0})        -- array write
epics.put("PV:NAME", 42, {timeout=5.0})           -- options table
```

Returns nothing on success. Returns an error string on failure.

#### epics.pv

```lua
local pv = epics.pv("PV:NAME")
local v  = pv.VAL                    -- read field
pv.VAL   = 10                        -- write field
local n  = pv.name                   -- PV name (read-only property)

local v  = pv:get("VAL", {timeout=5.0, count=100})
pv:put("VAL", 42, {timeout=5.0})
```

The `epics.pv` object uses direct database access for local PVs and Channel Access for remote PVs. Reserved names `name`, `get`, `put` return metadata/methods; all other keys are EPICS field names.

**Note:** `epics.sleep` has been removed. Use `osi.sleep()` instead.

### 5.2 asyn Library

Loaded with `asyn = require("asyn")`.

#### Parameter Access

```lua
local val = asyn.getParam("PORT", "PARAM_NAME")
local val = asyn.getParam("PORT", addr, "PARAM_NAME")

asyn.setParam("PORT", "PARAM_NAME", value)
asyn.setParam("PORT", addr, "PARAM_NAME", value)

asyn.callParamCallbacks("PORT")
asyn.callParamCallbacks("PORT", addr)
```

Typed variants: `asyn.getStringParam`, `asyn.getDoubleParam`, `asyn.getIntegerParam`, `asyn.setStringParam`, `asyn.setDoubleParam`, `asyn.setIntegerParam`.

#### Driver Read/Write (calls the asyn interface)

```lua
local val = asyn.readParam("PORT", "PARAM_NAME")
local val = asyn.readParam("PORT", addr, "PARAM_NAME")
asyn.writeParam("PORT", "PARAM_NAME", value)
asyn.writeParam("PORT", addr, "PARAM_NAME", value)
```

#### Octet Communication

```lua
asyn.setOutTerminator("\n")
asyn.setInTerminator("\n")
asyn.setReadTimeout(1000)
asyn.setWriteTimeout(100)
asyn.setWriteReadTimeout(500)

asyn.write("COMMAND", "PORT")
local response = asyn.read("PORT")
local response = asyn.writeread("COMMAND", "PORT")
```

Getter variants: `asyn.getOutTerminator()`, `asyn.getInTerminator()`, `asyn.getReadTimeout()`, `asyn.getWriteTimeout()`, `asyn.getWriteReadTimeout()`.

#### Port Options

```lua
asyn.setOption("PORT", "baud", "9600")
asyn.setOption("PORT", addr, "baud", "9600")
```

#### asynOctetClient Object

```lua
local client = asyn.client("PORT")
local client = asyn.client("PORT", addr, "param")
local client = asyn.client.find("PORT", addr, "param")  -- equivalent
```

| Property | Description |
|----------|-------------|
| `client.portName` | Read-only: port name |
| `client.addr` | Read-only: address |
| `client.InTerminator` | Get/set input terminator |
| `client.OutTerminator` | Get/set output terminator |
| `client.ReadTimeout` | Get/set read timeout in seconds (default 1.0) |
| `client.WriteTimeout` | Get/set write timeout in seconds (default 1.0) |

| Method | Description |
|--------|-------------|
| `client:read()` | Read from port; returns string or nil on timeout |
| `client:write(data)` | Write string to port |
| `client:writeread(data)` | Write then read atomically |
| `client:flush()` | Flush input buffer |
| `client:trace(key, val)` | Set trace mask; or `client:trace({error=true, flow=true})` |
| `client:traceio(key, val)` | Set trace IO mask; or table form |
| `client:setOption(key, val)` | Set driver-specific option |
| `client[addr]` | Create new client at different address on same port |

#### asynPortDriver Object

```lua
local drv = asyn.driver("PORT")
local drv = asyn.driver.find("PORT")    -- equivalent

-- Parameter access via proxy
print(drv.PARAM_NAME.value)
drv.PARAM_NAME.value = 42               -- setParam + callParamCallbacks

-- Methods
drv:readParam("PARAM_NAME")
drv:writeParam("PARAM_NAME", value)
drv:callParamCallbacks()

-- Properties
print(drv.portName)
print(drv.maxAddr)
```

For creating new drivers, see section 3.1 (asyn.driver.new).

#### Trace Control

```lua
asyn.setTrace("PORT", "error", true)
asyn.setTrace("PORT", {error=true, flow=true})
asyn.setTraceIO("PORT", "ascii", true)
```

Valid trace keys: `error`, `device`, `filter`, `driver`, `flow`, `warning`.
Valid traceIO keys: `nodata`, `ascii`, `escape`, `hex`.

### 5.3 db Library

Loaded with `db = require("db")`.

#### Record Creation

```lua
db.record("ai", "PREFIX:RecordName") {
    DTYP = "asynInt32",
    INP = "@asyn(PORT,0,0)PARAM",
    SCAN = "I/O Intr",
}
```

The `db.record` function returns a record object. Calling it with a table of field-value pairs sets those fields. Fields can also be accessed individually:

```lua
local rec = db.record("stringin", "x:y:z")
rec:field("VAL", "test")
rec:info("autosave", "VAL")

rec.VAL = "test"         -- dot syntax write
print(rec.VAL)           -- dot syntax read
print(rec.name)          -- record name (read-only)
print(rec.type)          -- record type (read-only)
```

If the record type is omitted, `db.record("existingName")` finds an existing record without creating one.

#### Loading Database Files

```lua
db.loadRecords("motor.db", {P="ioc:", M="m1", PORT="serial1"})
db.loadRecords("motor.db", "P=ioc:,M=m1,PORT=serial1")
```

#### Loading Templates with Multiple Substitutions

```lua
-- Variable style
db.loadTemplate("motor.db", {
    {P="ioc:", M="m1", PORT="serial1", ADDR="0"},
    {P="ioc:", M="m2", PORT="serial1", ADDR="1"},
})

-- Pattern style with global macros
db.loadTemplate("motor.db", {
    global  = {P="ioc:", PORT="serial1"},
    pattern = {"M", "ADDR"},
    {"m1", "0"},
    {"m2", "1"},
})
```

#### Other Functions

```lua
local pvs = db.list()                    -- table of all record objects

local ent = db.entry()                   -- DBENTRY cursor for static database access
ent:findRecord("myrecord")
print(ent:getFieldName())
-- Or module function syntax:
db.findRecord(ent, "myrecord")
print(db.getFieldName(ent))

db.registerDatabaseHook(function(filepath, macros)
    -- called each time dbLoadRecords is invoked
end)
```

The entry object supports all static database access functions from EPICS base (e.g., `findRecord`, `getRecordName`, `getString`, `putString`, `firstField`, `nextField`, `findInfo`, `getInfo`, etc.) with the `db` prefix dropped and camelCase naming.

### 5.4 iocsh Library

Loaded with `iocsh = require("iocsh")`. In the Lua shell, this is built into the global environment implicitly (no `require` needed).

```lua
local val = iocsh.EPICS_VERSION_MAJOR    -- environment variable lookup
iocsh.epicsEnvShow("EPICS_VERSION_MAJOR") -- call iocsh function
```

Lookups search environment variables first, then iocsh-registered functions.

### 5.5 osi Library

Loaded with `osi = require("osi")`.

```lua
osi.sleep(1.5)                           -- sleep in seconds (fractional OK)

local t = osi.monotonic()                -- monotonic time in seconds (not affected by clock adjustments)
local t = osi.time()                     -- current EPICS epoch time (seconds since Jan 1 1990 UTC)
local s = osi.timestr()                  -- formatted timestamp: "2026-07-02 14:30:00.000"
local s = osi.timestr(t)                 -- format a specific timestamp
local s = osi.timestr(t, "%H:%M:%S")    -- custom format

osi.startRedirectOut("output.log")       -- redirect stdout to file (supports nesting)
osi.endRedirectOut()                     -- restore previous stdout
```

### 5.6 event Library

Loaded with `event = require("event")`.

Provides event flags for inter-thread synchronization:

```lua
local done  = event.flag()              -- anonymous (local to this state)
local ready = event.flag("dataReady")   -- named (shared across all states)
```

Named flags: all calls to `event.flag("name")` with the same name -- even from different Lua states -- return a reference to the same underlying flag. Named flags persist for the IOC lifetime.

| Method | Description |
|--------|-------------|
| `flag:set()` | Set the flag to true; wakes any thread in `flag:wait()` |
| `flag:clear()` | Set the flag to false |
| `flag:test()` | Returns true if set, false otherwise (non-destructive) |
| `flag:testAndClear()` | Returns true if was set, then clears atomically |
| `flag:wait(timeout)` | Block until set or timeout (seconds). `-1` = indefinite, `0` = non-blocking. Returns true/false. |

### 5.7 seq Library

Loaded with `seq = require("seq")`. Requires `luaAddModule` to make it available via `require`.

A Lua-native state machine sequencer as an alternative to SNL. Programs are registered before iocInit and start automatically in background threads after iocInit completes.

```lua
local seq = require("seq")

local prog = seq.program("myProgram")
-- or with options:
local prog = seq.program("myProgram", { poll = 0.05 })

prog:state("idle", {
    entry = function() print("Entering idle") end,
    exit  = function() print("Leaving idle") end,

    options = { always_enter = true },

    seq.when(function() return voltage.VAL > 5.0 end) {
        action = function() print("High!") end,
        next = "alarm",
    },

    seq.when(seq.delay(5.0)) {
        next = "timeout",
    },

    seq.when() {       -- unconditional (always fires)
        next = "idle",
    },
})

seq.register(prog)     -- starts after iocInit (or immediately if after iocInit)
prog:stop()            -- signal the program to stop
```

The first state defined becomes the initial state.

**State options:**

| Option | Default | Description |
|--------|---------|-------------|
| `always_enter` | false | Run entry on self-transitions |
| `always_exit` | false | Run exit on self-transitions |
| `always_reset` | true | Reset delay timers on self-transitions |

**Transition conditions:**

| Condition | Fires when |
|-----------|-----------|
| Function | The function returns a truthy value |
| `seq.delay(seconds)` | Time elapsed since entering the state |
| None (`seq.when()`) | Always (unconditional) |

Transitions are evaluated in order; the first whose condition is true fires.

If a condition, action, or entry/exit function raises an error, the sequencer logs it and continues. Condition errors are treated as false.

### 5.8 bytestream Library

Loaded with `bs = require("bytestream")`. Requires `luaAddModule` to make it available via `require`.

Provides scanf-style parsing and printf-style formatting for byte stream device communication. Format specifiers follow StreamDevice conventions.

#### Format Specifiers

| Specifier | Read (match) | Write (format) | Description |
|-----------|-------------|----------------|-------------|
| `%s` | non-whitespace chars | `tostring(v)` | String |
| `%c` | any characters | first char (or width chars) | Character |
| `%d` | signed decimal | `string.format("%d")` | Signed integer |
| `%u` | unsigned decimal | `string.format("%u")` | Unsigned integer |
| `%o` | octal digits | `string.format("%o")` | Octal integer |
| `%x` | hex digits (with optional 0x) | `string.format("%x")` | Hexadecimal |
| `%f` | fixed-point float | `string.format("%f")` | Fixed-point |
| `%e` / `%E` | scientific notation | `string.format("%e")` | Scientific |
| `%g` / `%G` | general float | `string.format("%g")` | General |
| `%b` | binary digits (01) | integer to binary string | Binary |
| `%r` | raw N bytes (width=count) | passthrough | Raw bytes |
| `%{a\|b\|c}` | match enum string, return 0-based index | index to enum string | Enumeration |
| `%%` | literal % | literal % | Escape |

Flags: `*` (discard), `-` (negative/left-align), `0` (zero-pad), `#` (spaces after sign), `?` (lenient: default on no match), `!` (exact width).

#### Parsing and Formatting

```lua
local n      = bs.match("%d", "42")
local x, y   = bs.match("%d %d", "10 20")
local v, u   = bs.match("VOLTS %f %s", "VOLTS 3.14 V")

local s = bs.format("%d", 42)                  -- "42"
local s = bs.format("%08b", 42)                -- "00101010"
local s = bs.format("%{off|on|standby}", 2)    -- "standby"
```

#### Bytestream Client

Wraps `asyn.client` with format-aware read/write:

```lua
local dev = bs.client("SERIAL1")
dev.OutTerminator = "\n"
dev.InTerminator  = "\n"

dev:write("*RST")
dev:write("SET:VOLT %.3f", 3.300)
local temp = dev:write("MEAS:TEMP?"):read("%f")

local raw = dev:read()
local v, a = dev:read("%f %f")

dev:flush()
```

Properties: `InTerminator`, `OutTerminator`, `ReadTimeout`, `WriteTimeout`, `portName`, `addr`.

`client:write()` returns self for chaining with `:read()`. Errors raised by bytestream are caught by DTYP device support and mapped to record alarm states.

#### Custom Format Specifiers

```lua
bs.add_format {
    identifier = "B",
    read = function(flags)
        local lpeg = require("lpeg")
        return lpeg.P("true") * lpeg.Cc(true)
             + lpeg.P("false") * lpeg.Cc(false)
    end,
    write = function(flags)
        return function(value)
            return value and "true" or "false"
        end
    end,
}
```

---

## 6. Complete Examples

### 6.1 luascriptRecord -- Inline CODE

```
record(luascript, "$(P)$(R)sum")
{
    field(INPA, "$(P)$(R)inputA")
    field(INPB, "$(P)$(R)inputB")
    field(CODE, "return A + B")
    field(SCAN, "1 second")
    field(OUT,  "$(P)$(R)result PP")
    field(OOPT, "Every Time")
}
```

### 6.2 luascriptRecord -- Conditional Processing

```
record(luascript, "$(P)$(R)conditional")
{
    field(INPA, "$(P)$(R)trigger")
    field(INPB, "$(P)$(R)scale")
    field(POPT, "Conditional")
    field(PCAL, "_A")
    field(CODE, "return A * B")
    field(OUT,  "$(P)$(R)result PP")
    field(OOPT, "Every Time")
}
```

CODE only runs when input A changes.

### 6.3 luascriptRecord -- External File with State

**Database:**
```
record(luascript, "$(P)$(R)state_machine")
{
    field(INAA, "$(P)$(R)aaval.VAL")
    field(INBB, "$(P)$(R)bbval.VAL")
    field(PINI, 1)
    field(CODE, "@examples.lua state_demo()")
}
```

**scripts/examples.lua:**
```lua
curr = -1

function state_demo()
    curr = curr + 1
    curr = curr % 10

    if     curr == 0 then return AA
    elseif curr == 1 then return BB
    elseif curr == 2 then return CC
    end
end
```

Global variables persist between processings (controlled by RELO field).

### 6.4 DTYP "lua" -- File-Based Callbacks

**Database:**
```
record(ai, "$(P)counter")
{
    field(DTYP, "lua")
    field(INP, "@dtyp.lua next_int(10)")
}

record(bi, "$(P)toggle")
{
    field(DTYP, "lua")
    field(INP, "@dtyp.lua next_bool")
    field(ONAM, "On")
    field(ZNAM, "Off")
}
```

**scripts/dtyp.lua:**
```lua
function next_int(record, step)
    return record.VAL + step
end

function next_bool(record)
    if record.VAL == 0 then return "On"
    else                    return "Off"
    end
end
```

### 6.5 DTYP "lua" -- Named State with Bytestream Client

**scripts/sensor.lua:**
```lua
local db = require("db")
local bs = require("bytestream")

luaRegisterState(PORT)

local client = bs.client(PORT)
client.OutTerminator = "\n"
client.InTerminator  = "\n"

db.record("ai", P .. "Temperature") {
    DTYP = "lua",
    INP  = "@" .. PORT .. " read_temp()",
    SCAN = "1 second",
    EGU  = "degC",
    PREC = "2",
}

function read_temp()
    return client:write("MEAS:TEMP?"):read("%f")
end
```

**st.lua:**
```lua
luaAddModule("$(LUA)")
drvAsynIPPortConfigure("SENSOR1", "192.168.1.100:5025")
luaLoadFile("sensor.lua", {P="dev1:", PORT="SENSOR1"})

drvAsynIPPortConfigure("SENSOR2", "192.168.1.101:5025")
luaLoadFile("sensor.lua", {P="dev2:", PORT="SENSOR2"})

iocInit()
```

Each `luaLoadFile` creates a separate named state. The two sensor instances do not interfere.

### 6.6 Lua Shell Startup Script

**st.lua:**
```lua
#ENABLE_HASH_COMMENTS

# Set up paths
epicsEnvSet("LUA_SCRIPT_PATH", "./scripts")
luaAddModule("../..")

dbLoadDatabase("../../dbd/myApp.dbd")
myApp_registerRecordDeviceDriver(pdbbase)

#- Load device drivers (silent comment)
luaLoadFile("device.lua", {P="dev1:", PORT="DEV1", DEVICE_PORT="serial1"})
luaLoadFile("device.lua", {P="dev2:", PORT="DEV2", DEVICE_PORT="serial2"})

< load_databases.lua

iocInit()

luaSpawn("tick.lua", {INTERVAL=1.0})

dbl()
```

### 6.7 luaPortDriver -- asyn.driver.new (Recommended)

**scripts/driver.lua:**
```lua
local asyn = require("asyn")
local db = require("db")
local Int32, Float64, Octet = asyn.Int32, asyn.Float64, asyn.Octet

luaRegisterState(PORT)

local drv = asyn.driver.new(PORT, {
    Float64 "TEMPERATURE" (0.0),
    Float64 "SETPOINT"    (25.0),
    Int32   "ERRORS"      (0),
    Octet   "STATUS"      ("OK"),
}, function(self)
    self.port = asyn.client(DEVICE_PORT, 0, "")
    self.port.InTerminator = "\r\n"
    self.port.OutTerminator = "\r\n"
    self.conversion = tonumber(CONV) or 1.0
end)

drv.TEMPERATURE.read = function(self)
    local response = self.port:writeread("READ:TEMP?")
    if response then
        drv.STATUS.value = "OK"
        return tonumber(response) * self.conversion
    end
    drv.ERRORS.value = drv.ERRORS.value + 1
    drv.STATUS.value = "Read error"
    return drv.TEMPERATURE.value
end

drv.SETPOINT.write = function(value, self)
    drv.SETPOINT.value = value
end

db.record("ai", P .. "Temperature") {
    DTYP = "asynFloat64",
    INP  = "@asyn(" .. PORT .. ",0,0)TEMPERATURE",
    SCAN = "I/O Intr",
    PINI = "1",
    EGU  = "degC",
    PREC = "2",
}

db.record("ao", P .. "Setpoint") {
    DTYP = "asynFloat64",
    OUT  = "@asyn(" .. PORT .. ",0,0)SETPOINT",
    EGU  = "degC",
}
```

**st.lua:**
```lua
luaAddModule("../..")
drvAsynIPPortConfigure("serial1", "192.168.1.100:5025")
luaLoadFile("driver.lua", {P="dev1:", PORT="DEV1", DEVICE_PORT="serial1", CONV="0.01"})
iocInit()
```

### 6.8 luaPortDriver -- Legacy param DSL

**scripts/driver.lua:**
```lua
db = require("db")

out_val = START

param.int32.read "CURR_VAL" [[
    return out_val
]]

db.record("ai", P .. R .. "Value") {
    DTYP = "asynInt32",
    SCAN = "I/O Intr",
    INP = "@asyn(" .. PORT .. ",0,0)CURR_VAL",
    PINI = 1
}

param.int32.write "INCREMENTOR" [[
    out_val = out_val + value
    self:writeParam("CURR_VAL", out_val)
    self:callParamCallbacks()
]]

db.record("ao", P .. R .. "Increment") {
    DTYP = "asynInt32",
    OUT  = "@asyn(" .. PORT .. ",0,0)INCREMENTOR"
}
```

**st.lua:**
```lua
luaPortDriver("TEST", "driver.lua", "P=x:, R=y:, START=10")
iocInit()
```

### 6.9 Sequencer -- State Machine

**scripts/traffic.lua:**
```lua
local seq   = require("seq")
local db    = require("db")
local epics = require("epics")
local event = require("event")

luaRegisterState(PORT)

db.record("bo", P .. "enable") { ZNAM = "Off", ONAM = "On", PINI = "YES" }
db.record("stringin", P .. "state") { PINI = "YES" }

local enable = epics.pv(P .. "enable")
local state  = epics.pv(P .. "state")

local prog = seq.program("traffic", { poll = 0.1 })

prog:state("red", {
    entry = function() state.VAL = "RED" end,
    seq.when(function() return enable.VAL == 1 end) {
        next = "green",
    },
    seq.when(seq.delay(0.1)) { next = "red" },
})

prog:state("green", {
    entry = function() state.VAL = "GREEN" end,
    seq.when(seq.delay(5.0)) { next = "yellow" },
})

prog:state("yellow", {
    entry = function() state.VAL = "YELLOW" end,
    seq.when(seq.delay(2.0)) { next = "red" },
})

seq.register(prog)
```

**st.lua:**
```lua
luaAddModule("../..")
luaLoadFile("traffic.lua", {P="IOC:", PORT="TRAFFIC"})
iocInit()
```

### 6.10 Event Flags -- Inter-Thread Signaling

```lua
-- worker.lua (run via luaSpawn)
local event = require("event")
local osi   = require("osi")

local ready = event.flag("sensorReady")

-- ... sensor initialization ...
osi.sleep(2.0)

ready:set()
```

```lua
-- main.lua (in st.lua or luaLoadFile)
local event = require("event")

luaSpawn("worker.lua")

local ready = event.flag("sensorReady")
if ready:wait(10.0) then
    print("Sensor is ready")
else
    print("Sensor initialization timed out")
end
```

---

## 7. Key Rules and Pitfalls

1. **CODE field is limited to 120 characters.** Use `@file.lua function()` for anything non-trivial.

2. **`LUA_SCRIPT_PATH` must be set** before loading records or scripts that reference Lua files. Set it with `epicsEnvSet("LUA_SCRIPT_PATH", "./scripts")`. Use `luaAddPath` and `luaAddModule` to register additional directories.

3. **`luaAddModule` is required for bytestream, seq, and lpeg.** These are installed to `lib/<arch>/`. Call `luaAddModule("$(LUA)")` or `luaAddModule("../..")` in your startup script.

4. **luascriptRecord cannot use `I/O Intr` scanning.** It has no direct hardware interface. Use periodic scanning or process via forward links.

5. **The RELO field controls whether global variables persist.** With `Every New File` (default), changing the function within the same file preserves all Lua globals. With `Every New Change` or `Every Processing`, the state is reset.

6. **Return value semantics differ between input and output records** for DTYP "lua". Input records use the return value to set the record's value. Output records ignore it (except ao, which triggers WRITE_ALARM on non-nil returns).

7. **`epics.sleep` has been removed.** Use `osi.sleep()` instead. The `osi` library is always available.

8. **PV field access uses direct database access for local PVs.** Both `epics.pv` objects and DTYP `record` objects automatically detect local PVs and use `dbGetField`/`dbPutField` instead of Channel Access, eliminating network overhead. Remote PVs fall through to CA.

9. **Use `record.name` for the PV name.** The old `record:getName()` method has been removed. Use the `name` property instead.

10. **`asyn.driver.new` is the recommended port driver API.** The legacy `luaPortDriver` iocsh command still works but the new API provides type constructors, parameter proxies, callback binding, and internal state.

11. **Named states are the recommended pattern for DTYP "lua".** Use `luaRegisterState(PORT)` in a script loaded via `luaLoadFile`, then reference the state name in DTYP INP/OUT fields. This allows the same script to create records and define their callbacks.

12. **The implicit iocsh fallback only works in `luash` and `luaCmd`.** Scripts run via `luaLoadFile` and `luaSpawn` do NOT have automatic access to iocsh functions like `dbLoadRecords` or `drvAsynIPPortConfigure` as globals. Use the Lua library equivalents instead (e.g., `db.loadRecords()`, `iocsh.dbLoadRecords()`). Configure ports and drivers in your `st.lua` (which runs via `luash`) before calling `luaLoadFile`.

13. **`luash` processes line-by-line; `luaLoadFile` compiles as a single chunk.** In `luash`, `local` variables do not persist between lines. Use `luaLoadFile` when local scoping matters.

14. **All action commands return nothing on success, error string on failure.** This applies to `luash`, `luaSpawn`, `luaLoadFile`, `luaCmd`, `epics.put`, and bytestream operations.

15. **Callbacks can only be bound on `asyn.driver.new` drivers.** Drivers obtained via `asyn.driver.find` support parameter read/write but not callback binding.

16. **Sequencer programs must be registered before iocInit** to start automatically. If registered after iocInit, they start immediately. The script should be loaded via `luaLoadFile` before `iocInit()`.
