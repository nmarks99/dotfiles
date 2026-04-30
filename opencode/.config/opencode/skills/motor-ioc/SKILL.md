---
name: motor-ioc
description: Configure and deploy EPICS motor IOCs -- database templates, substitution files, motor record fields, st.cmd startup scripts, motorUtil, and driver submodule integration
---

# Motor IOC Skill

You are an expert at configuring and deploying EPICS motor IOCs. You understand the motor database templates, the motor record field semantics, substitution file patterns, st.cmd ordering, and how to integrate model-3 asyn motor drivers.

---

## 1. Database Templates

### 1.1 basic_asyn_motor.db -- Minimal Template

The minimal template for a model-3 asyn motor axis. Use this for simple setups.

**Macros:**

| Macro | Required | Description |
|-------|----------|-------------|
| `P` | Yes | PV prefix (e.g., `"IOC:"`) |
| `M` | Yes | Motor name (e.g., `"m1"`) |
| `DTYP` | Yes | Always `"asynMotor"` for model-3 drivers |
| `PORT` | Yes | Asyn motor port name (from controller create command) |
| `ADDR` | Yes | Axis number (0-based) |
| `DESC` | No | Description string |
| `EGU` | No | Engineering units (e.g., `"mm"`, `"deg"`) |
| `DIR` | No | Direction: `"Pos"` or `"Neg"` (default `"Pos"`) |
| `VELO` | No | Velocity (EGU/sec) |
| `VBAS` | No | Base velocity (EGU/sec) |
| `ACCL` | No | Acceleration time (seconds to reach VELO) |
| `BDST` | No | Backlash distance (EGU) |
| `BVEL` | No | Backlash velocity |
| `BACC` | No | Backlash acceleration time |
| `MRES` | No | Motor resolution (EGU/step) |
| `PREC` | No | Display precision (decimal places) |
| `DHLM` | No | Dial high limit (EGU) |
| `DLLM` | No | Dial low limit (EGU) |
| `INIT` | No | Init string (sent to controller at boot) |
| `TWV` | No | Tweak value (default 1) |

**Contains:** The motor record instance plus three auxiliary records (`Direction`, `Offset`, `Resolution`) that feed motor record configuration back to the driver.

### 1.2 asyn_motor.db -- Full-Featured Template

Extends `basic_asyn_motor.db` with:
- Enable/disable toggle (`$(P)$(M)_able`)
- Velocity change helper (`$(P)$(M)_vCh`)
- Tweak value change helper (`$(P)$(M)_twCh`)
- Retry count (RTRY=10) and retry settle mode (RSTM="NearZero")

**Additional macros:**

| Macro | Default | Description |
|-------|---------|-------------|
| `RTRY` | 10 | Number of retries |
| `RSTM` | `"NearZero"` | Retry settle mode |

Use `asyn_motor.db` for production IOCs. Use `basic_asyn_motor.db` for minimal/test setups.

---

## 2. Substitution File Patterns

### 2.1 Multi-Axis Substitution

```
file "$(MOTOR)/db/basic_asyn_motor.db"
{
pattern
{P,     N,  M,        DTYP,         PORT,  ADDR,  DESC,          EGU,  DIR,  VELO,  VBAS,  ACCL,  BDST,  BVEL,  BACC,  MRES,    PREC,  DHLM,   DLLM,    INIT}
{IOC:,  1,  "m$(N)",  "asynMotor",  MC1,   0,     "motor $(N)",  mm,   Pos,  10,    0.1,   0.5,   0,     1,     0.2,   0.001,   4,     200,    -200,    ""}
{IOC:,  2,  "m$(N)",  "asynMotor",  MC1,   1,     "motor $(N)",  mm,   Pos,  10,    0.1,   0.5,   0,     1,     0.2,   0.001,   4,     200,    -200,    ""}
{IOC:,  3,  "m$(N)",  "asynMotor",  MC1,   2,     "motor $(N)",  deg,  Pos,  5,     0.1,   0.3,   0,     1,     0.2,   0.0001,  5,     360,    -360,    ""}
{IOC:,  4,  "m$(N)",  "asynMotor",  MC1,   3,     "motor $(N)",  deg,  Pos,  5,     0.1,   0.3,   0,     1,     0.2,   0.0001,  5,     360,    -360,    ""}
}
```

**Key columns:**
- `N` is used in the `M` pattern (`"m$(N)"`) to create PV names like `IOC:m1`, `IOC:m2`, etc.
- `PORT` must match the port name from the controller create command in st.cmd.
- `ADDR` is the 0-based axis number on the controller.

### 2.2 Using asyn_motor.db

When using `asyn_motor.db`, the macros `P`, `DTYP`, `PORT`, `DHLM`, and `DLLM` can be passed externally from `dbLoadTemplate`:

```
file "$(MOTOR)/db/asyn_motor.db"
{
pattern
{N,  M,        ADDR,  DESC,          EGU,  DIR,  VELO,  VBAS,  ACCL,  BDST,  BVEL,  BACC,  MRES,    PREC,  INIT}
{1,  "m$(N)",  0,     "motor $(N)",  mm,   Pos,  10,    0.1,   0.5,   0,     1,     0.2,   0.001,   4,     ""}
{2,  "m$(N)",  1,     "motor $(N)",  mm,   Pos,  10,    0.1,   0.5,   0,     1,     0.2,   0.001,   4,     ""}
}
```

Then in st.cmd:
```
dbLoadTemplate("motor.substitutions", "P=IOC:,DTYP=asynMotor,PORT=MC1,DHLM=200,DLLM=-200")
```

---

## 3. Motor Record Key Fields

### 3.1 Position and Motion

| Field | Type | Description |
|-------|------|-------------|
| `VAL` | DOUBLE | User desired position (EGU) -- writing causes a move |
| `DVAL` | DOUBLE | Dial desired position (EGU, before DIR/OFF) |
| `RBV` | DOUBLE | User readback position (EGU) |
| `DRBV` | DOUBLE | Dial readback position |
| `RVAL` | LONG | Raw desired position (steps) |
| `RRBV` | LONG | Raw readback position (steps) |
| `DIFF` | DOUBLE | Difference: DVAL - DRBV |
| `RDIF` | DOUBLE | Raw difference: RVAL - RRBV |

### 3.2 Velocity and Acceleration

| Field | Type | Description |
|-------|------|-------------|
| `VELO` | DOUBLE | Velocity (EGU/sec) |
| `VBAS` | DOUBLE | Base velocity (EGU/sec, minimum velocity) |
| `ACCL` | DOUBLE | Acceleration time (seconds to reach VELO from VBAS) |
| `BVEL` | DOUBLE | Backlash velocity |
| `BACC` | DOUBLE | Backlash acceleration time |
| `SBAS` | DOUBLE | Computed base speed (steps/sec, read-only) |
| `SMAX` | DOUBLE | Max speed (steps/sec, read-only) |
| `S` | DOUBLE | Speed (steps/sec, read-only, computed from VELO) |

### 3.3 Limits

| Field | Type | Description |
|-------|------|-------------|
| `HLM` | DOUBLE | User high limit (EGU) |
| `LLM` | DOUBLE | User low limit (EGU) |
| `DHLM` | DOUBLE | Dial high limit (EGU) |
| `DLLM` | DOUBLE | Dial low limit (EGU) |
| `HLS` | SHORT | High limit switch active (read-only from driver) |
| `LLS` | SHORT | Low limit switch active (read-only from driver) |

### 3.4 Resolution and Conversion

| Field | Type | Description |
|-------|------|-------------|
| `MRES` | DOUBLE | Motor step size (EGU/step) -- primary resolution field |
| `ERES` | DOUBLE | Encoder step size (EGU/encoder-count) |
| `SREV` | LONG | Steps per revolution |
| `UREV` | DOUBLE | EGU per revolution (alternative to MRES: MRES = UREV/SREV) |
| `UEIP` | MENU | Use encoder if present: `"No"`, `"Yes"` |
| `RRES` | DOUBLE | Readback step size (when UEIP=Yes, uses ERES for readback) |

### 3.5 Direction and Offset

| Field | Type | Description |
|-------|------|-------------|
| `DIR` | MENU | Direction: `"Pos"` (user=dial), `"Neg"` (user=-dial) |
| `OFF` | DOUBLE | User offset: user = (DIR * dial) + OFF |
| `FOFF` | MENU | Freeze offset: `"Variable"`, `"Frozen"` |
| `SET` | MENU | Set mode: `"Use"` (normal), `"Set"` (define position without moving) |

### 3.6 Motion Control

| Field | Type | Description |
|-------|------|-------------|
| `BDST` | DOUBLE | Backlash distance (EGU, 0 = no backlash) |
| `RTRY` | SHORT | Retry count (default 10) |
| `RDBD` | DOUBLE | Retry deadband (EGU, position error tolerance) |
| `RSTM` | MENU | Retry settle mode: `"NearZero"`, `"Always"`, `"AfterStop"` |
| `DLY` | DOUBLE | Delay after move (seconds, before declaring done) |
| `STOP` | SHORT | Write 1 to stop current motion |
| `SPMG` | MENU | Stop/Pause/Move/Go: `"Stop"`, `"Pause"`, `"Move"`, `"Go"` |
| `JOGF` | SHORT | Jog forward (1 = start, 0 = stop) |
| `JOGR` | SHORT | Jog reverse |
| `HOMF` | SHORT | Home forward |
| `HOMR` | SHORT | Home reverse |
| `TWV` | DOUBLE | Tweak value (EGU) |
| `TWF` | SHORT | Tweak forward (move +TWV) |
| `TWR` | SHORT | Tweak reverse (move -TWV) |

### 3.7 Status

| Field | Type | Description |
|-------|------|-------------|
| `DMOV` | SHORT | Done moving (1 = idle, 0 = moving) |
| `MOVN` | SHORT | Moving (1 = moving, 0 = idle) |
| `MSTA` | LONG | Motor status word (bit field, see MSTA bits below) |
| `MISS` | SHORT | Missed position (retry deadband exceeded) |
| `RCNT` | SHORT | Retry count remaining |
| `CNEN` | MENU | Closed-loop enable: `"Disable"`, `"Enable"` |
| `STUP` | MENU | Status update request |

### 3.8 MSTA Bit Definitions

The `MSTA` field is a 32-bit integer with these bit flags:

| Bit | Name | Description |
|-----|------|-------------|
| 0 | RA_DIRECTION | Last move direction (1=positive) |
| 1 | RA_DONE | Motion complete |
| 2 | RA_PLUS_LS | Plus limit switch active |
| 3 | RA_HOME | Home switch active |
| 4 | EA_SLIP | Encoder slip enabled |
| 5 | EA_POSITION | Position maintenance enabled |
| 6 | EA_SLIP_STALL | Slip/stall detected |
| 7 | EA_HOME | Encoder home signal |
| 8 | EA_PRESENT | Encoder present |
| 9 | RA_PROBLEM | Driver problem |
| 10 | RA_MOVING | Motor is moving |
| 11 | GAIN_SUPPORT | Supports closed-loop |
| 12 | CNTRL_COMM_ERR | Communication error |
| 13 | RA_MINUS_LS | Minus limit switch active |
| 14 | RA_HOMED | Has been homed |

### 3.9 Other Important Fields

| Field | Type | Description |
|-------|------|-------------|
| `DTYP` | DEVICE | Device type -- always `"asynMotor"` for model-3 |
| `OUT` | OUTLINK | Output link: `"@asyn(PORT,ADDR)"` |
| `INIT` | STRING | Init string sent to controller at boot |
| `PINI` | MENU | Process at init (normally `"No"` for motor records) |

---

## 4. Startup Script (st.cmd) Pattern

### 4.1 Model-3 Asyn Motor IOC

```bash
#!../../bin/linux-x86_64/myMotorApp

< envPaths

cd "${TOP}"

## Register all support components
dbLoadDatabase "dbd/myMotorApp.dbd"
myMotorApp_registerRecordDeviceDriver pdbbase

## Configure the communication port
drvAsynIPPortConfigure("IP1", "192.168.1.100:5025", 0, 0, 0)
asynOctetSetInputEos("IP1", 0, "\r\n")
asynOctetSetOutputEos("IP1", 0, "\r\n")

## Create the motor controller
## myMotorCreateController(motorPortName, commPortName, numAxes, movingPollPeriod, idlePollPeriod)
myMotorCreateController("MC1", "IP1", 4, 0.1, 1.0)

## Load motor records
dbLoadTemplate("motors.substitutions")

## Load motor utility (allstop/alldone)
dbLoadRecords("$(MOTOR)/db/motorUtil.db", "P=IOC:")

## Load asynRecord for communication diagnostics (optional)
dbLoadRecords("$(ASYN)/db/asynRecord.db", "P=IOC:,R=Asyn,PORT=IP1,ADDR=0,OMAX=256,IMAX=256")

cd "${TOP}/iocBoot/${IOC}"
iocInit

## Initialize motor utilities after iocInit
motorUtilInit("IOC:")
```

### 4.2 Key st.cmd Ordering

1. `dbLoadDatabase` + `registerRecordDeviceDriver`
2. Communication port configuration (`drvAsynIPPortConfigure`, serial options, EOS)
3. Motor controller creation (driver-specific create command)
4. `dbLoadRecords` / `dbLoadTemplate` for motor records
5. `dbLoadRecords` for `motorUtil.db`
6. `iocInit`
7. `motorUtilInit("PREFIX:")` -- **must be after iocInit**

### 4.3 Serial Motor Controller

```bash
## Serial port
drvAsynSerialPortConfigure("SER1", "/dev/ttyUSB0", 0, 0, 0)
asynSetOption("SER1", 0, "baud", "9600")
asynSetOption("SER1", 0, "bits", "8")
asynSetOption("SER1", 0, "parity", "none")
asynSetOption("SER1", 0, "stop", "1")
asynOctetSetInputEos("SER1", 0, "\r")
asynOctetSetOutputEos("SER1", 0, "\r")

## Motor controller
myMotorCreateController("MC1", "SER1", 2, 0.1, 1.0)
```

---

## 5. Motor Utilities

### 5.1 motorUtil.db

Load in st.cmd:
```
dbLoadRecords("$(MOTOR)/db/motorUtil.db", "P=IOC:")
```

Initialize after `iocInit`:
```
motorUtilInit("IOC:")
```

Provides:
- `$(P)allstop` -- bo record; write 1 to stop all motors
- `$(P)alldone` -- bi record; 1 = all motors idle, 0 = at least one moving
- `$(P)moving` -- longout; count of motors currently moving

### 5.2 Auto Power Management

Load per-axis:
```
dbLoadRecords("$(MOTOR)/db/asyn_auto_power.db", "P=IOC:,M=m1,PORT=MC1,ADDR=0")
```

Provides automatic amplifier power-on before moves and power-off after a configurable delay. The driver must implement `setClosedLoop()` to respond to power commands.

---

## 6. Makefile for Motor IOC

```makefile
# In src/Makefile:
PROD_IOC = myMotorApp

DBD += myMotorApp.dbd
myMotorApp_DBD += base.dbd
myMotorApp_DBD += asyn.dbd
myMotorApp_DBD += motorSupport.dbd
myMotorApp_DBD += drvAsynIPPort.dbd          # or drvAsynSerialPort.dbd
myMotorApp_DBD += myMotorSupport.dbd         # Driver-specific DBD

myMotorApp_SRCS += myMotorApp_registerRecordDeviceDriver.cpp
myMotorApp_SRCS_DEFAULT += myMotorAppMain.cpp
myMotorApp_SRCS_vxWorks += -nil-

# Library order matters: most dependent first, base last
myMotorApp_LIBS += myMotor                   # Driver-specific library
myMotorApp_LIBS += motor
myMotorApp_LIBS += asyn
myMotorApp_LIBS += $(EPICS_BASE_IOC_LIBS)
```

### configure/RELEASE

```makefile
MOTOR = /path/to/motor
ASYN  = /path/to/asyn
EPICS_BASE = /path/to/base
```

---

## 7. Profile Moves (Coordinated Motion)

### 7.1 Loading Profile Move Templates

```
## Controller-level profile PVs
dbLoadRecords("$(MOTOR)/db/profileMoveController.template",
    "P=IOC:,R=Prof:,PORT=MC1,NAXES=4,NPOINTS=2000,NPULSES=2000,TIMEOUT=30")

## Per-axis profile PVs (one per axis)
dbLoadRecords("$(MOTOR)/db/profileMoveAxis.template",
    "P=IOC:,R=Prof:,M=1,PORT=MC1,ADDR=0,NPOINTS=2000,NREADBACK=2000,PREC=4,TIMEOUT=30")
dbLoadRecords("$(MOTOR)/db/profileMoveAxis.template",
    "P=IOC:,R=Prof:,M=2,PORT=MC1,ADDR=1,NPOINTS=2000,NREADBACK=2000,PREC=4,TIMEOUT=30")
```

Profile moves require the driver to override `buildProfile()`, `executeProfile()`, `abortProfile()`, and `readbackProfile()` in the controller class, and `defineProfile()` in the axis class.

---

## 8. Driver Submodule Integration

Motor driver submodules (e.g., motorNewport, motorSmarAct) can be deployed either within the motor module or as standalone modules.

### 8.1 Standalone Driver Module

```makefile
# In configure/RELEASE:
MOTOR = /path/to/motor
ASYN  = /path/to/asyn
EPICS_BASE = /path/to/base
```

```makefile
# In src/Makefile:
myMotorApp_DBD += motorSupport.dbd
myMotorApp_DBD += myDriverSupport.dbd
myMotorApp_LIBS += myDriver
myMotorApp_LIBS += motor
myMotorApp_LIBS += asyn
myMotorApp_LIBS += $(EPICS_BASE_IOC_LIBS)
```

### 8.2 Within the Motor Module

When built as part of the motor module (submodule under `modules/`), the driver's `configure/RELEASE` is auto-generated and its install location is set to `$(MOTOR)`.

---

## 9. Key Rules and Pitfalls

1. **`DTYP` must be `"asynMotor"`** for all model-3 motor records. This is the only DTYP that works with `asynMotorController`/`asynMotorAxis` drivers.

2. **`OUT` field format** is `"@asyn(PORT,ADDR)"`. The `PORT` is the motor port name (from the controller create command), NOT the communication port name.

3. **`MRES` is the fundamental resolution** -- it converts between motor steps and engineering units. All positions passed to the driver are in steps (position / MRES). If using `SREV`/`UREV`, then `MRES = UREV / SREV`.

4. **`motorUtilInit()` must be called AFTER `iocInit`**. It scans all motor records to set up allstop/alldone/moving monitoring.

5. **`ADDR` is 0-based** in the asyn link. Axis 1 on the controller corresponds to `ADDR=0`.

6. **`ACCL` is the time** (in seconds) to accelerate from `VBAS` to `VELO`, NOT the acceleration value itself. The motor record computes acceleration = (VELO - VBAS) / ACCL.

7. **Do NOT set `PINI = "YES"` on motor records.** The motor record has its own initialization sequence. Setting PINI causes spurious moves at startup.

8. **Backlash correction** (`BDST`) adds an overshoot-and-return move when the final approach direction matches the backlash direction. Set `BDST = 0` to disable.

9. **Direction and offset** (`DIR`, `OFF`) convert between user and dial coordinates: `User = DIR * Dial + OFF` (where DIR is +1 or -1). The `FOFF` field controls whether OFF is recalculated when you change DIR.

10. **`UEIP = "Yes"`** tells the motor record to use the encoder position (DRBV from `motorEncoderPosition_`) instead of the commanded position for readback. The driver must set `motorStatusHasEncoder_` = 1 and provide encoder values.

11. **The motor record STOP field** should be used via `caput RECORD.STOP 1`, not by writing to SPMG. STOP triggers a clean stop sequence. SPMG="Stop" is a persistent state.

12. **The three auxiliary records** (Direction, Offset, Resolution) in the motor templates feed configuration from the motor record to the driver. They enable the driver to perform its own coordinate conversions (e.g., for profile moves). Do NOT remove these records unless you understand the consequences.
