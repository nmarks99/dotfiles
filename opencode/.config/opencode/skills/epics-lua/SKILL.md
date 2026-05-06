---
name: epics-lua
description: Write Lua scripts and records for EPICS IOCs -- luascriptRecord expressions, Lua shell startup scripts, Lua device support (DTYP "lua"), luaPortDriver definitions, and built-in library usage (epics, asyn, db)
---

# EPICS Lua Skill

You are an expert at writing Lua-based logic for EPICS IOCs using the lua EPICS module. This module embeds Lua 5.4 into an IOC and exposes four capabilities:

1. **luascriptRecord** -- a scriptable record type (like calcout/scalcout but using Lua)
2. **Lua Device Support (DTYP "lua")** -- standard records (ai, bi, ao, etc.) backed by Lua functions
3. **luaPortDriver** -- generate an asynPortDriver entirely from a Lua script
4. **Lua Shell** -- use Lua as the IOC startup script language (st.lua instead of st.cmd)

All four share a set of built-in Lua libraries: `epics`, `asyn`, `db`, `iocsh`, and `osi`.

---

## 1. luascriptRecord

The `luascript` record has 10 double input fields (A-J, fetched from INPA-INPJ) and 10 string input fields (AA-JJ, fetched from INAA-INJJ). These are pushed as Lua globals before each execution.

The record has three output values:
- **VAL** (double) -- set when the Lua code returns a number or boolean
- **SVAL** (string, 40 chars) -- set when the Lua code returns a string
- **AVAL** (array) -- set when the Lua code returns a table of numbers

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

The `@` prefix tells the record to search `LUA_SCRIPT_PATH` for the file. A space separates the filename from the function name. Parameters in parentheses are passed to the function on each processing.

Use external files for anything beyond trivial one-liners. The 120-character CODE limit makes inline code impractical for real logic, and external files allow persistent state, reusable functions, and `require` for libraries.

### 1.2 RELO Field (Reload Behavior)

Controls when the Lua state is recompiled on CODE changes:

| Value | Behavior |
|-------|----------|
| `Every New File` | Recompile only if the referenced file changes. Changing to a different function in the same file preserves state. |
| `Every New Change` | Recompile on any CODE field change. |
| `Every Processing` | Recompile before every processing. |

The FRLD field forces a one-shot recompile when written with a non-zero value.

### 1.3 Output Parameters

| Field | Description |
|-------|-------------|
| OUT | Output link for the result |
| OOPT | When to write: `Every Time`, `On Change`, `When Zero`, `When Non-zero`, `Transition To Zero`, `Transition To Non-zero`, `Never` |
| SYNC | `Sync` (process Lua in the record's thread) or `Async` (process in a separate thread) |

### 1.4 Other Fields

| Field | Description |
|-------|-------------|
| ERR | String containing the last Lua error encountered during processing |
| PREC | Display precision for VAL |
| HIHI/HIGH/LOW/LOLO | Alarm limits for VAL |

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
field(INP,  "@script.lua function_name(param1) PORTNAME")
```

- `script.lua` -- Lua file found via `LUA_SCRIPT_PATH`
- `function_name` -- global function defined in that file
- `(param1, param2)` -- optional comma-separated arguments (numbers, quoted strings, booleans)
- `PORTNAME` -- optional; set as the global variable `PORT` in the Lua state

### 2.3 Function Signature

```lua
function myfunction(record, param1, param2, ...)
```

- `record` -- a PV object representing the calling record
- `param1, param2, ...` -- values from the parenthesized parameter list in the INP/OUT field

### 2.4 The `record` Object

The record object provides field access through Channel Access:

```lua
local val = record["VAL"]      -- ca_get on RECORDNAME.VAL
local val = record.VAL         -- equivalent

record["DESC"] = "new desc"    -- ca_put on RECORDNAME.DESC
record.DESC = "new desc"       -- equivalent

local name = record:getName()  -- returns the PV name string (colon syntax required)
```

Both reading and writing go through CA (not direct database access). This means CA must be running and there is network-level overhead on each access.

### 2.5 Return Value

**Input records** (ai, bi, longin, mbbi, stringin): The return value sets the record's value.
- Return a number to set VAL/RVAL (depending on record type)
- Return a string for bi (compared to ZNAM/ONAM), mbbi (compared to state strings), or stringin
- Return `nil` to leave the record unchanged

**Output records** (ao, bo, longout, mbbo, stringout): The return value is ignored. The function is invoked for its side effects (e.g., writing to hardware, updating other PVs).

---

## 3. luaPortDriver

The `luaPortDriver` function creates an asynPortDriver from a Lua script:

```
luaPortDriver("PORTNAME", "driver.lua", "P=prefix:,R=suffix:,START=10")
```

| Argument | Description |
|----------|-------------|
| Port name | The asyn port name for the new driver |
| Script file | Lua file found via `LUA_SCRIPT_PATH` |
| Macros | Comma-separated key=value pairs, available as globals in the script |

### 3.1 Parameter Definition Syntax

Parameters are defined in the driver script using the `param` global:

**Basic parameter (no callbacks):**
```lua
param.int32 "PARAM_NAME"
param.float64 "PARAM_NAME"
param.octet "PARAM_NAME"
param.string "PARAM_NAME"     -- alias for octet
```

Parameter type names are case-insensitive.

**Parameter with read callback:**
```lua
param.float64.read "PARAM_NAME" [[
    return math.sqrt(self["BASE"]^2 + self["SIDE"]^2)
]]
```

**Parameter with write callback:**
```lua
param.int32.write "PARAM_NAME" [[
    out_val = out_val + value
    self:writeParam("CURR_VAL", out_val)
    self:callParamCallbacks()
]]
```

### 3.2 Implicit Variables

Inside callback code blocks:

| Variable | Description |
|----------|-------------|
| `self` | An asynPortDriver object (see asyn library). Use `self["PARAM"]` to read params, `self:writeParam("PARAM", val)` to write, `self:callParamCallbacks()` to trigger monitors. |
| `value` | (Write callbacks only) The value from the asyn write callback. |
| `PORT` | The asyn port name string. |
| Macro variables | All macro key-value pairs from the third argument (e.g., `P`, `R`, `START`). |

### 3.3 Inline Record Creation with db.record

Driver scripts commonly use `db.record()` to create EPICS records within the same script:

```lua
db.record("ai", P .. R .. "Value") {
    DTYP = "asynInt32",
    SCAN = "I/O Intr",
    INP = "@asyn(" .. PORT .. ",0,0)CURR_VAL",
    PINI = 1
}
```

This eliminates the need for separate .db files.

---

## 4. Lua Shell

### 4.1 st.lua as Replacement for st.cmd

The Lua shell can replace the IOC shell entirely. A startup script written in Lua (e.g., `st.lua`) supports conditionals, loops, variables, and functions -- capabilities not available in standard iocsh scripts.

### 4.2 Implicit iocsh Environment

Within the Lua shell, global variable lookups that don't match a Lua variable automatically search:
1. EPICS environment variables
2. iocsh-registered functions

This means iocsh functions can be called as if they were Lua functions:

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

The directive `#ENABLE_HASH_COMMENTS` at the start of a script makes the shell accept iocsh-style `#` comments. This only applies to lines where `#` is the first non-whitespace character; `#` used in Lua expressions (table length operator) is unaffected.

```lua
#ENABLE_HASH_COMMENTS

# This is now a comment
print(#"This still works")  -- prints 15 (string length)
```

### 4.4 Include Directive

The `<` character includes another Lua script at the insertion point:

```lua
< load_databases.lua
```

The included file is found via `LUA_SCRIPT_PATH`.

### 4.5 luash Command (from iocsh)

After the DBD is loaded, the `luash` command runs a Lua script from within iocsh:

```
luash("script.lua", "X=5,TEXT='Hello'")
```

The second argument is a macro string. Non-quoted values are interpreted as numbers; strings must be quoted.

With no script argument, `luash` opens an interactive Lua shell (prompt set by `LUASH_PS1`).

### 4.6 luaSpawn

Runs a Lua script in a background EPICS thread:

```lua
luaSpawn("tick.lua")
```

### 4.7 exit

A line containing only `exit` breaks from the current script level and returns to the caller. It does not terminate the IOC.

### 4.8 luashSetCommonState

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

This allows the interactive shell to access objects created during the startup script.

---

## 5. Built-in Libraries

### 5.1 epics Library

Loaded with `epics = require("epics")`.

```lua
local val = epics.get("PV:NAME")            -- ca_get, returns value or nil
local val = epics.get("PV:NAME", 5.0)       -- with timeout in seconds

epics.put("PV:NAME", 42)                    -- ca_put

epics.sleep(1.5)                            -- sleep in seconds (fractional OK)

local pv = epics.pv("PV:NAME")              -- PV object
local v = pv.VAL                             -- ca_get on PV:NAME.VAL
pv.VAL = 10                                 -- ca_put on PV:NAME.VAL
```

The `epics.pv` object uses the same mechanism as the DTYP `record` object -- field access goes through Channel Access via `__index`/`__newindex` metamethods.

### 5.2 asyn Library

Loaded with `asyn = require("asyn")`.

**Parameter access:**
```lua
local val = asyn.getParam("PORT", "PARAM_NAME")
local val = asyn.getParam("PORT", addr, "PARAM_NAME")

asyn.setParam("PORT", "PARAM_NAME", value)
asyn.setParam("PORT", addr, "PARAM_NAME", value)

asyn.callParamCallbacks("PORT")
asyn.callParamCallbacks("PORT", addr)
```

Typed variants: `asyn.getStringParam`, `asyn.getDoubleParam`, `asyn.getIntegerParam`, `asyn.setStringParam`, `asyn.setDoubleParam`, `asyn.setIntegerParam`.

**Driver read/write (calls the asyn interface):**
```lua
local val = asyn.readParam("PORT", "PARAM_NAME")
local val = asyn.readParam("PORT", addr, "PARAM_NAME")
asyn.writeParam("PORT", "PARAM_NAME", value)
asyn.writeParam("PORT", addr, "PARAM_NAME", value)
```

**Octet communication:**
```lua
asyn.setOutTerminator("\n")
asyn.setInTerminator("\n")
asyn.setReadTimeout(1000)
asyn.setWriteTimeout(100)

asyn.write("COMMAND", "PORT")
local response = asyn.read("PORT")
local response = asyn.writeread("COMMAND", "PORT")
```

**Port options:**
```lua
asyn.setOption("PORT", "baud", "9600")
asyn.setOption("PORT", addr, "baud", "9600")
```

**asynOctetClient object (C++11 builds):**
```lua
local client = asynOctetClient.find("PORT", 0, "")
client.InTerminator = "\n"
client.OutTerminator = "\n"
client:write("COMMAND")
local response = client:read()
```

In non-C++11 builds, this class is not available. Use `asyn.client("PORT", addr, "param")` instead, which returns an equivalent object with the same `read`, `write`, and `writeread` methods.

**asynPortDriver object (C++11 builds):**
```lua
local drv = asynPortDriver.find("PORT")
local val = drv["PARAM_NAME"]           -- getParam
drv["PARAM_NAME"] = 42                  -- setParam
drv:readParam("PARAM_NAME")             -- calls the read interface
drv:writeParam("PARAM_NAME", value)     -- calls the write interface
drv:callParamCallbacks()

local addr1 = drv[1]                    -- access address 1
local val = addr1["PARAM_NAME"]
```

In non-C++11 builds, this class is not available. Use `asyn.driver("PORT")` instead, which returns an equivalent object.

**Trace control:**
```lua
asyn.setTrace("PORT", "error", true)
asyn.setTrace("PORT", {error=true, flow=true})
asyn.setTraceIO("PORT", "ascii", true)
```

Valid trace keys: `error`, `device`, `filter`, `driver`, `flow`, `warning`.
Valid traceIO keys: `nodata`, `ascii`, `escape`, `hex`.

### 5.3 db Library

Loaded with `db = require("db")`.

**Record creation:**
```lua
db.record("ai", "PREFIX:RecordName") {
    DTYP = "asynInt32",
    INP = "@asyn(PORT,0,0)PARAM",
    SCAN = "I/O Intr"
}
```

The `db.record` function returns an object. Calling it with a table of field-value pairs sets those fields. You can also set fields individually:

```lua
local rec = db.record("stringin", "x:y:z")
rec:field("VAL", "test")
rec:info("autosave", "VAL")
```

Accessor methods: `rec:name()` returns the record name, `rec:type()` returns the RTYP.

If the record type is omitted, `db.record("existingName")` finds an existing record without creating one.

**Other functions:**
```lua
local pvs = db.list()                    -- list of all PVs as db.record instances
local entry = db.entry()                 -- DBENTRY pointer for static database access

db.registerDatabaseHook(function(filepath, macros)
    -- called each time dbLoadRecords is invoked
end)
```

The db library also wraps most EPICS static database access functions (e.g., `db.findRecord`, `db.getRecordName`, `db.getString`, `db.putString`, etc.), with the `db` prefix dropped and camelCase naming.

### 5.4 iocsh Library

Loaded with `iocsh = require("iocsh")`.

```lua
local val = iocsh.EPICS_VERSION_MAJOR    -- environment variable lookup
iocsh.epicsEnvShow("EPICS_VERSION_MAJOR") -- call iocsh function
```

Lookups search environment variables first, then iocsh-registered functions. In the Lua shell, this is built into the global environment implicitly (no `require` needed).

### 5.5 osi Library

Loaded with `osi = require("osi")`.

```lua
osi.sleep(1.0)                           -- equivalent to epics.sleep()
osi.startRedirectOut("output.log")       -- redirect stdout to file
osi.endRedirectOut()                     -- restore previous stdout
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

### 6.2 luascriptRecord -- External File

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

The variable `curr` persists across processings because the Lua state is retained (controlled by the RELO field).

### 6.3 luascriptRecord -- State Machine

**scripts/examples.lua:**
```lua
curr = -1

function state_demo()
    curr = curr + 1
    curr = curr % 10

    if     curr == 0 then return AA
    elseif curr == 1 then return BB
    elseif curr == 2 then return CC
    elseif curr == 3 then return DD
    elseif curr == 4 then return EE
    elseif curr == 5 then return FF
    elseif curr == 6 then return GG
    elseif curr == 7 then return HH
    elseif curr == 8 then return II
    elseif curr == 9 then return JJ
    end
end
```

Global variables persist between processings, enabling state machine behavior without external storage. This can replace simple SNL programs.

### 6.4 DTYP "lua" -- ai and bi Records

**Database:**
```
record(ai, "$(P)$(R)ai")
{
    field(DTYP, "lua")
    field(INP, "@dtyp.lua next_int(10)")
}

record(bi, "$(P)$(R)bi")
{
    field(DTYP, "lua")
    field(INP, "@dtyp.lua next_bool")
    field(ONAM, "True")
    field(ZNAM, "False")
}
```

**scripts/dtyp.lua:**
```lua
function next_int(record, amount)
    local curr_val = record["VAL"]
    return curr_val + amount
end

function next_bool(record)
    local curr_val = record["VAL"]
    if curr_val == 0 then
        return "True"
    else
        return "False"
    end
end
```

For bi records, returning the string "True" or "False" matches against ONAM/ZNAM.

### 6.5 Lua Shell Startup Script

**st.lua:**
```lua
#ENABLE_HASH_COMMENTS

VERSION      = 0 + EPICS_VERSION_MAJOR
REVISION     = 0 + EPICS_VERSION_MIDDLE
MODIFICATION = 0 + EPICS_VERSION_MINOR

VERSION_INT   = VERSION << 16 | REVISION << 8 | MODIFICATION
VERSION_CHECK = 3 << 16 | 15 << 8 | 6

if (VERSION_INT < VERSION_CHECK) then
    print("You are using a version below base-3.15.6")
end

epicsEnvSet("LUA_SCRIPT_PATH", "./scripts")

dbLoadDatabase("../../dbd/testLuaShell.dbd")
testLuaShell_registerRecordDeviceDriver(pdbbase)

< load_userscripts.lua

iocInit()

luaSpawn("tick.lua")

dbl()
```

**scripts/load_userscripts.lua:**
```lua
for i = 1, 3 do
    dbLoadRecords("../../luaApp/Db/luascripts10.db", "P=lua:,R=set" .. i .. ":")
end
```

**scripts/tick.lua:**
```lua
osi = require("osi")

local flip = false

for i = 1, 10 do
    flip = not flip
    if flip then
        print("Tick")
    else
        print("Tock")
    end
    osi.sleep(1.0)
end
```

### 6.6 luaPortDriver

**st.lua:**
```lua
epicsEnvSet("LUA_SCRIPT_PATH", ".:./scripts")

dbLoadDatabase("../../dbd/testLuaShell.dbd")
testLuaShell_registerRecordDeviceDriver(pdbbase)

luaPortDriver("TEST", "driver.lua", "P=x:, R=y:, START=10")

iocInit()
```

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

param.int32.write "SET_VALUE" [[
    out_val = value
    self:writeParam("CURR_VAL", out_val)
    self:callParamCallbacks()
]]

db.record("ao", P .. R .. "Set") {
    DTYP = "asynInt32",
    OUT  = "@asyn(" .. PORT .. ",0,0)SET_VALUE"
}
```

`START` is a macro from the `luaPortDriver` call. `PORT` is the port name ("TEST"). `P` and `R` are macros. After a write to INCREMENTOR or SET_VALUE, the callback updates CURR_VAL and calls `callParamCallbacks()` to trigger monitors on the "Value" record.

### 6.7 Asyn Communication from luascript

**Database:**
```
record(luascript, "$(P)$(R)script")
{
    field(CODE, "@asyn.lua get_html('$(PORT)')")
}
```

**scripts/asyn.lua:**
```lua
asyn = require("asyn")

function get_html(port)
    p = asynOctetClient.find(port, 0, "")
    p.InTerminator = "\n"
    p.OutTerminator = "\n\n"

    p:write("GET / HTTP/1.0")

    local input = p:read()
    while (input ~= nil) do
        print(input)
        input = p:read()
    end
end
```

Requires an asyn port configured for the target (e.g., `drvAsynIPPortConfigure("IP", "www.google.com:80", 0, 0, 0)` in the startup script).

---

## 7. Key Rules and Pitfalls

1. **CODE field is limited to 120 characters.** Use `@file.lua function()` for anything non-trivial.

2. **DTYP "lua" field access goes through Channel Access**, not direct database access. Every `record["FIELD"]` read or write is a `ca_get`/`ca_put`. This has performance implications and requires CA to be running.

3. **`LUA_SCRIPT_PATH` must be set** before loading records or scripts that reference Lua files. Set it with `epicsEnvSet("LUA_SCRIPT_PATH", "./scripts")` in the startup script.

4. **luascriptRecord cannot use `I/O Intr` scanning.** It has no direct hardware interface. Use periodic scanning or process via forward links.

5. **The RELO field controls whether global variables persist.** With `Every New File` (default), changing the function within the same file preserves all Lua globals. With `Every New Change` or `Every Processing`, the state is reset.

6. **Return value semantics differ between input and output records** for DTYP "lua". Input records (ai, bi, longin, mbbi, stringin) use the return value to set the record's value. Output records (ao, bo, longout, mbbo, stringout) ignore it.

7. **`record:getName()` requires colon syntax.** Using `record.getName()` will print an error. The colon calls it as a method with `record` as `self`.

8. **luaPortDriver implicit variables are available without declaration.** `self`, `value`, `PORT`, and all macro variables (P, R, etc.) exist in the callback scope automatically. Do not redeclare them.

9. **`require` with EPICS static libraries searches standard Lua paths first.** Libraries registered via `luaRegisterLibrary` are only found after the built-in Lua search fails. If a file in `LUA_CPATH` matches the library name, it takes precedence over the statically registered version.
