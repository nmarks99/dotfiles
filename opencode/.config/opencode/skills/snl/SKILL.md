---
name: snl
description: Write EPICS State Notation Language (SNL) programs (.st/.stt) -- state machines, PV interaction (assign/monitor/sync/syncq), built-in functions, event flags, safe mode, embedded C code, and build integration
---

# State Notation Language (SNL) Skill

You are an expert at writing EPICS State Notation Language (SNL) programs. SNL is a domain-specific language for building concurrent finite state machines that interact with EPICS Process Variables (PVs) via Channel Access. SNL programs are compiled by the `snc` compiler into C code, then linked with the sequencer runtime library.

---

## 1. Program Structure

```
program programName ("param1=value1,param2=value2")

/* Global definitions: variables, assign, monitor, sync, syncq, options */
option +r;

int myVar;
assign myVar to "{prefix}:myPV";
monitor myVar;

/* Global entry block (runs once before state sets start) */
entry {
    /* initialization code */
}

/* One or more state sets */
ss myStateSet {
    /* State set local definitions */

    state firstState {
        entry { /* runs when entering this state */ }

        when (condition1) {
            /* action code */
        } state secondState

        when (condition2) {
            /* action code */
        } state firstState

        exit { /* runs when leaving this state */ }
    }

    state secondState {
        when (condition) {
            /* action code */
        } state firstState

        when (delay(10.0)) {
            /* timeout -- no events for 10 seconds */
        } exit    /* terminate program */
    }
}

/* Global exit block (runs after all state sets exit) */
exit {
    /* cleanup code */
}
```

### 1.1 Program Name and Parameters

```
program myProgram                              /* No parameters */
program myProgram ("prefix=IOC:,debug=0")      /* With default parameters */
```

The program name becomes a global C symbol. Parameters are key-value pairs in a single string, overridable at runtime via the `seq` command.

Parameters are expanded in PV names using `{paramName}` syntax:

```
assign voltage to "{prefix}:voltage";
/* With prefix=IOC: this becomes "IOC:voltage" */
```

### 1.2 File Extensions

| Extension | Preprocessing |
|-----------|---------------|
| `.st` | Preprocessed by C preprocessor (`cpp`) before `snc` compilation |
| `.stt` | Compiled directly by `snc` (no preprocessing) |

Use `.st` when you need `#include`, `#define`, or `#ifdef`. Use `.stt` for simple programs without preprocessor directives.

---

## 2. Variable Declarations and Types

### 2.1 Primitive Types

```
char c;
short s;
int i;
long l;
unsigned char uc;
unsigned short us;
unsigned int ui;
unsigned long ul;
int8_t i8;
uint8_t u8;
int16_t i16;
uint16_t u16;
int32_t i32;
uint32_t u32;
float f;
double d;
string str;         /* char[MAX_STRING_SIZE], typically char[40] */
```

### 2.2 Event Flags

```
evflag myFlag;      /* Abstract binary flag type */
```

Event flags cannot be arrays or pointers. They support four operations: `efSet`, `efClear`, `efTest`, `efTestAndClear`.

### 2.3 Foreign Types

```
enum myEnum x;           /* C enum defined elsewhere */
struct myStruct s;        /* C struct defined elsewhere */
union myUnion u;          /* C union defined elsewhere */
typename myTypedef t;     /* C typedef -- typename keyword is REQUIRED */
```

### 2.4 Arrays, Pointers, Const

```
int arr[10];              /* Array of 10 ints */
double matrix[4][4];      /* 2D array */
int *ptr;                 /* Pointer (cannot be assigned to a PV) */
char const *msg;          /* Pointer to const char */
int const N = 100;        /* Constant */
```

Array sizes must be integer literals (not expressions).

### 2.5 Initializers

Variables with global lifetime (top-level, state-set-local, state-local) must use constant initializers (as in C static initialization). They are initialized once when the program starts.

Variables with block-local lifetime (inside action blocks) follow normal C rules and are re-initialized each time the block is entered.

---

## 3. Process Variable Interaction

### 3.1 assign -- Connect Variables to PVs

```
/* Single variable to single PV */
assign voltage to "{prefix}:voltage";

/* Array element to single PV */
assign temps[0] to "{prefix}:temp1";
assign temps[1] to "{prefix}:temp2";

/* Array to multiple PVs */
assign lights to {"traffic:red", "traffic:yellow", "traffic:green"};

/* Anonymous PV (for dynamic assignment or inter-state-set communication) */
assign myVar;
/* equivalent to: assign myVar to ""; */
```

Only variables with global lifetime (top-level, state-set-local, or state-local) can be assigned to PVs. Pointer types cannot be assigned.

### 3.2 monitor -- Subscribe to PV Changes

```
monitor voltage;           /* Auto-update when PV changes */
monitor temps[0];          /* Monitor single array element */
monitor temps;             /* Monitor all elements */
```

The variable must be assigned first. Monitored variables are automatically updated when the underlying PV changes value.

### 3.3 sync -- Couple Event Flags to PV Changes

```
evflag voltageFlag;
sync voltage to voltageFlag;
```

When a monitor event occurs on `voltage`, `voltageFlag` is set. The variable must be assigned and monitored. An event flag can be synced to multiple variables.

### 3.4 syncq -- Queued Monitoring

```
/* With event flag */
evflag dataFlag;
syncq data to dataFlag 10;    /* Queue size = 10 */

/* Without event flag */
syncq data 10;
```

When a monitor event occurs, the new value is appended to the queue. Use `pvGetQ(data)` to dequeue values. If the queue is full, the newest entry is overwritten. Queue size defaults to 100 if omitted (but explicit size is recommended).

---

## 4. State Sets and States

### 4.1 State Set

```
ss myStateSet {
    /* State-set-local declarations (global lifetime) */
    int count = 0;
    assign count;

    state idle {
        /* ... transitions ... */
    }

    state running {
        /* ... transitions ... */
    }
}
```

A program must have at least one state set. Each state set runs in its own EPICS thread. State set names must be unique within the program. State names must be unique within their state set.

### 4.2 State Transitions

```
state idle {
    when (voltage > threshold) {
        /* Action code -- runs when condition is true */
        printf("Voltage exceeded threshold!\n");
    } state alarm

    when (delay(1.0)) {
        /* Periodic check -- runs if no other condition fires for 1 second */
    } state idle

    when () {
        /* Unconditional -- always true (use as last transition) */
    } state done
}
```

Transitions are evaluated in order. The first condition that evaluates to true causes its action block to execute, then the state changes to the target state.

### 4.3 Transition to Exit

```
when (errorCondition) {
    printf("Fatal error, shutting down\n");
} exit    /* Terminates the program (all state sets) */
```

### 4.4 State Entry and Exit Blocks

```
state measuring {
    entry {
        printf("Entering measuring state\n");
        startTime = epicsTime_getCurrent();
    }

    when (measurementDone) {
        /* process result */
    } state idle

    exit {
        printf("Leaving measuring state\n");
    }
}
```

Entry blocks run when the state is entered (before condition evaluation). Exit blocks run when the state is left (after the action block that determined the next state).

### 4.5 State Options

```
state myState {
    option -t;    /* Don't reset delay timers on self-transition */
    option -e;    /* Execute entry block even on self-transition */
    option -x;    /* Execute exit block even on self-transition */

    /* ... */
}
```

| Option | Default | Effect |
|--------|---------|--------|
| `+t` | Yes | Reset delay timers on each state entry (including self-transition) |
| `-t` | -- | Don't reset timers on self-transition (measure from first entry) |
| `+e` | Yes | Execute entry only when entering from a different state |
| `-e` | -- | Execute entry every time (including self-transition) |
| `+x` | Yes | Execute exit only when leaving to a different state |
| `-x` | -- | Execute exit every time (including self-transition) |

### 4.6 Global Entry and Exit Blocks

```
program myProg

entry {
    /* Runs once before state sets start.
     * PV connections are established. If +c, all channels are connected.
     * Runs in the context of the first state set thread. */
    printf("Program starting\n");
}

ss main { /* ... */ }

exit {
    /* Runs once after all state sets exit.
     * PV connections are still active.
     * Runs in the context of the first state set thread. */
    printf("Program exiting\n");
}
```

---

## 5. Condition Events

Transition conditions are evaluated when:

1. The state is entered (after entry block execution)
2. A monitored PV receives an update
3. An asynchronous `pvGet` or `pvPut` completes
4. A `delay()` timer expires
5. An event flag is set or cleared
6. A PV connects or disconnects

```
/* Monitor event -- variable changes */
when (voltage > 10.0) { ... } state alarm

/* Delay timer */
when (delay(5.0)) { ... } state timeout

/* Event flag */
when (efTestAndClear(dataReady)) { ... } state process

/* Async completion */
when (pvGetComplete(value)) { ... } state gotData

/* Connection check */
when (pvConnectCount() < pvChannelCount()) { ... } state disconnected

/* Combined */
when (voltage > limit && efTest(enableFlag)) { ... } state action

/* Unconditional (always true) */
when () { ... } state next
```

---

## 6. Built-in Functions

### 6.1 PV Operations

| Function | Description |
|----------|-------------|
| `pvGet(ch)` | Get PV value. Default completion depends on `-a`/`+a` option |
| `pvGet(ch, SYNC)` | Synchronous get (blocks until complete) |
| `pvGet(ch, SYNC, 5.0)` | Synchronous get with 5-second timeout |
| `pvGet(ch, ASYNC)` | Asynchronous get (returns immediately) |
| `pvGetComplete(ch)` | Check if async pvGet completed (returns `TRUE`/`FALSE`) |
| `pvGetCancel(ch)` | Cancel pending async pvGet |
| `pvGetQ(ch)` | Dequeue next value from syncQ queue (returns `TRUE` if non-empty) |
| `pvFlushQ(ch)` | Flush (empty) the syncQ queue |
| `pvPut(ch)` | Put PV value (fire-and-forget) |
| `pvPut(ch, SYNC)` | Synchronous put (blocks until complete) |
| `pvPut(ch, SYNC, 5.0)` | Synchronous put with 5-second timeout |
| `pvPut(ch, ASYNC)` | Asynchronous put (returns immediately) |
| `pvPutComplete(ch)` | Check if async pvPut completed |
| `pvPutCancel(ch)` | Cancel pending async pvPut |
| `pvFlush()` | Flush all pending CA requests |

### 6.2 Array PV Operations

| Function | Description |
|----------|-------------|
| `pvArrayGetComplete(arr, length, any, complete)` | Check async get completion for array elements |
| `pvArrayPutComplete(arr, length)` | Check if all async puts completed |
| `pvArrayPutComplete(arr, length, TRUE, done)` | Check if any completed; individual results in `done[]` |
| `pvArrayGetCancel(arr, length)` | Cancel pending gets for array elements |
| `pvArrayPutCancel(arr, length)` | Cancel pending puts for array elements |
| `pvArrayMonitor(arr, length)` | Monitor first `length` elements |
| `pvArrayStopMonitor(arr, length)` | Stop monitoring first `length` elements |
| `pvArraySync(arr, length, ef)` | Sync event flag to array elements |
| `pvArrayConnected(arr, length)` | Check if all array elements are connected |

### 6.3 PV Information

| Function | Return Type | Description |
|----------|-------------|-------------|
| `pvName(ch)` | `char*` | PV name string |
| `pvCount(ch)` | `unsigned` | Native element count |
| `pvStatus(ch)` | `pvStat` | Alarm status |
| `pvSeverity(ch)` | `pvSevr` | Alarm severity |
| `pvMessage(ch)` | `char*` | Status message string |
| `pvTimeStamp(ch)` | `epicsTimeStamp` | PV timestamp |
| `pvAssigned(ch)` | `seqBool` | Is the variable assigned to a PV? |
| `pvConnected(ch)` | `seqBool` | Is the PV connected? |
| `pvIndex(ch)` | `CH_ID` | Channel index (for use in escaped C code) |

### 6.4 Global PV Information

| Function | Description |
|----------|-------------|
| `pvChannelCount()` | Total number of assigned channels |
| `pvConnectCount()` | Number of currently connected channels |
| `pvAssignCount()` | Number of assigned channels |

### 6.5 Event Flag Operations

| Function | Description |
|----------|-------------|
| `efSet(ef)` | Set event flag (wakes up waiting state sets) |
| `efClear(ef)` | Clear event flag |
| `efTest(ef)` | Test if flag is set (returns `TRUE`/`FALSE`) |
| `efTestAndClear(ef)` | Test and clear atomically (returns previous state) |

### 6.6 Timing

| Function | Description |
|----------|-------------|
| `delay(seconds)` | Returns `TRUE` if specified time has elapsed since entering state. **Only valid in transition conditions.** |

### 6.7 Dynamic PV Operations

| Function | Description |
|----------|-------------|
| `pvAssign(ch, "newPVname")` | Dynamically reassign variable to a different PV |
| `pvAssignSubst(ch, "macro=value")` | Reassign with macro substitution |
| `pvMonitor(ch)` | Start monitoring a channel |
| `pvStopMonitor(ch)` | Stop monitoring a channel |
| `pvSync(ch, ef)` | Sync event flag to channel (use `NOEVFLAG` to cancel) |

### 6.8 Utilities

| Function | Description |
|----------|-------------|
| `macValueGet("paramName")` | Get program parameter value (returns `char*`) |
| `optGet("optionLetter")` | Get compiler option value (returns `seqBool`) |

---

## 7. Built-in Constants

| Constant | Value | Use |
|----------|-------|-----|
| `TRUE` | 1 | Boolean true |
| `FALSE` | 0 | Boolean false |
| `SYNC` | -- | Synchronous completion mode for pvGet/pvPut |
| `ASYNC` | -- | Asynchronous completion mode for pvGet/pvPut |
| `NOEVFLAG` | 0 | Remove sync binding (use with `pvSync`) |
| `pvStatOK` | 0 | PV status: OK |
| `pvStatERROR` | -1 | PV status: error |
| `pvStatDISCONN` | -2 | PV status: disconnected |
| `pvSevrNONE` | 0 | Severity: none |
| `pvSevrMINOR` | 1 | Severity: minor |
| `pvSevrMAJOR` | 2 | Severity: major |
| `pvSevrINVALID` | 3 | Severity: invalid |

Additional `pvStat` constants: `pvStatREAD`, `pvStatWRITE`, `pvStatHIHI`, `pvStatHIGH`, `pvStatLOLO`, `pvStatLOW`, `pvStatSTATE`, `pvStatCOS`, `pvStatCOMM`, `pvStatTIMEOUT`, `pvStatHW_LIMIT`, `pvStatCALC`, `pvStatSCAN`, `pvStatLINK`, `pvStatSOFT`, `pvStatBAD_SUB`, `pvStatUDF`, `pvStatDISABLE`, `pvStatSIMM`, `pvStatREAD_ACCESS`, `pvStatWRITE_ACCESS`.

---

## 8. Compiler Options

Set globally in the program or on the `snc` command line:

```
option +r;     /* Set option in program (overrides command line) */
option -ca;    /* Multiple options can be combined */
```

| Option | Default | Description |
|--------|---------|-------------|
| `+a` | Off (`-a`) | Asynchronous `pvGet` (default: synchronous) |
| `+c` | On | Wait for all PV connections before starting |
| `-c` | -- | Allow program to run before all PVs connect |
| `+d` | Off | Enable runtime debug messages |
| `+e` | On | New event flag mode (flags not auto-cleared) |
| `+i` | On | Generate IOC shell registrar |
| `+l` | On | Generate line markers in C output |
| `+m` | Off | Include `main()` for standalone program |
| `+r` | Off | Reentrant code (allows multiple instances) |
| `+s` | Off | Safe mode (per-state-set variable copies, implies `+r`) |
| `+w` | On | Enable warnings |
| `+W` | Off | Enable extra warnings for undefined identifiers |

---

## 9. Safe Mode (`+s`)

Safe mode gives each state set its own copy of all global variables. Changes made by one state set are NOT visible to others until explicitly communicated.

```
program safeProg
option +s;

int shared = 0;
assign shared;
monitor shared;

ss producer {
    state produce {
        when (delay(1.0)) {
            shared++;
            pvPut(shared);    /* Makes change visible to other state sets */
        } state produce
    }
}

ss consumer {
    state consume {
        when (pvGetQ(shared) || efTest(sharedFlag)) {
            /* shared is now updated with the producer's value */
            printf("Got: %d\n", shared);
        } state consume
    }
}
```

In safe mode:
- Each state set operates on its own copy of variables
- `pvPut(var)` publishes the local copy to the "shared" state and to the PV
- `pvGet(var)` reads the current PV value into the local copy
- Monitored variables are updated in a state set only when it waits in a transition condition
- This eliminates race conditions between state sets

---

## 10. Embedded C Code

### 10.1 Single-Line Escape

```
%% #include <math.h>
%% extern void myExternalFunc(int arg);
```

### 10.2 Multi-Line Escape

```
%{
#include <epicsThread.h>

static int computeChecksum(char *data, int len)
{
    int sum = 0;
    int i;
    for (i = 0; i < len; i++) sum += data[i];
    return sum;
}
}%
```

### 10.3 Preprocessor Directives in Escaped Code

When using `.st` files (preprocessed), prefix `#include` with `%%` to defer it past preprocessing:

```
%%#include <myLib.h>        /* Included during C compilation, not during cpp */
```

Without `%%`, the `#include` would be processed by `cpp` before `snc` sees the code.

### 10.4 Calling seq_ Functions from C Code

Built-in SNL functions have C equivalents with `seq_` prefix. They require `ssId` as the first argument:

```
%{
static void myHelper(SS_ID ssId, int *pVar, VAR_ID varId)
{
    seq_pvGet(ssId, varId, SYNC);
    *pVar += 1;
    seq_pvPut(ssId, varId, SYNC);
}
}%

int counter;
assign counter to "myCounter";

ss main {
    state run {
        when (delay(1.0)) {
            myHelper(ssId, &counter, pvIndex(counter));
        } state run
    }
}
```

In reentrant mode (`+r`), access SNL variables through the `pVar` pointer:

```
/* With +r, pVar->counter instead of counter directly */
```

---

## 11. SNL Function Definitions

SNL supports function definitions (similar to C) that can call built-in functions:

```
program funcExample
option +r;

int x;
assign x to "myPV";
monitor x;

/* SNL function -- gets implicit sequencer context */
int doubleAndPut()
{
    x = x * 2;
    pvPut(x, SYNC);
    return x;
}

ss main {
    state run {
        when (delay(1.0)) {
            int result = doubleAndPut();
            printf("Result: %d\n", result);
        } state run
    }
}
```

SNL functions automatically scope over the whole program. They can call built-in `pvXxx` functions on global assigned variables. They cannot receive channel variables as parameters (limitation -- pass by value only).

---

## 12. Statements and Expressions

SNL supports most C statements except `switch`/`case`:

```
/* if/else */
if (voltage > limit) {
    alarm = 1;
} else {
    alarm = 0;
}

/* while */
while (count < 10) {
    count++;
}

/* for */
for (i = 0; i < N; i++) {
    data[i] = 0;
}

/* break, continue */
for (i = 0; i < 100; i++) {
    if (data[i] < 0) break;
    if (data[i] == 0) continue;
    sum += data[i];
}

/* State change statement (inside transition action blocks only) */
state newTarget;    /* Override the static target state */
```

Expression syntax is identical to C: all arithmetic, logical, bitwise, assignment, ternary, comma, sizeof, and type cast operators are supported.

---

## 13. Complete Examples

### 13.1 Simple Monitor and React

```
program voltageMonitor
option +r;

float voltage;
assign voltage to "{user}:voltage";
monitor voltage;

ss main {
    state low {
        when (voltage > 5.0) {
            printf("Voltage high: %g\n", voltage);
        } state high

        when (delay(0.1)) {
        } state low
    }

    state high {
        when (voltage <= 5.0) {
            printf("Voltage low: %g\n", voltage);
        } state low

        when (delay(0.1)) {
        } state high
    }
}
```

### 13.2 Traffic Light Controller

```
program trafficLight

int lights[3];
assign lights to {
    "traffic:red",
    "traffic:yellow",
    "traffic:green"
};

double redTime = 3.0;
double greenTime = 4.0;
double yellowTime = 1.0;

ss light {
    state red {
        entry {
            lights[0] = 1; pvPut(lights[0]);
            lights[1] = 0; pvPut(lights[1]);
            lights[2] = 0; pvPut(lights[2]);
        }
        when (delay(redTime)) {
        } state green
    }

    state green {
        entry {
            lights[0] = 0; pvPut(lights[0]);
            lights[1] = 0; pvPut(lights[1]);
            lights[2] = 1; pvPut(lights[2]);
        }
        when (delay(greenTime)) {
        } state yellow
    }

    state yellow {
        entry {
            lights[0] = 0; pvPut(lights[0]);
            lights[1] = 1; pvPut(lights[1]);
            lights[2] = 0; pvPut(lights[2]);
        }
        when (delay(yellowTime)) {
        } state red
    }
}
```

### 13.3 Multi-State-Set with Event Flags

```
program coordination
option +r;

double voltage;
assign voltage to "{prefix}:voltage";
monitor voltage;

double loLimit;
assign loLimit to "{prefix}:loLimit";
monitor loLimit;
evflag loFlag;
sync loLimit to loFlag;

double hiLimit;
assign hiLimit to "{prefix}:hiLimit";
monitor hiLimit;
evflag hiFlag;
sync hiLimit to hiFlag;

int light;
assign light to "{prefix}:light";

/* State set 1: light control based on voltage */
ss lightControl {
    state off {
        when (voltage > hiLimit) {
            light = 1;
            pvPut(light);
        } state on
    }

    state on {
        when (voltage < loLimit) {
            light = 0;
            pvPut(light);
        } state off
    }
}

/* State set 2: enforce limit constraints */
ss limitCheck {
    state check {
        when (efTestAndClear(loFlag) && loLimit > hiLimit) {
            hiLimit = loLimit;
            pvPut(hiLimit);
        } state check

        when (efTestAndClear(hiFlag) && hiLimit < loLimit) {
            loLimit = hiLimit;
            pvPut(loLimit);
        } state check
    }
}
```

### 13.4 Async PvPut with Completion Checking

```
program parallelInit
option +r;

int32_t init[6];
assign init to {
    "dcs:axis1init", "dcs:axis2init", "dcs:axis3init",
    "dcs:axis4init", "dcs:axis5init", "dcs:axis6init"
};

ss main {
    state start {
        when () {
            int i;
            for (i = 0; i < 6; i++) {
                init[i] = 1;
                pvPut(init[i], ASYNC);
            }
        } state waitComplete
    }

    state waitComplete {
        when (pvArrayPutComplete(init, 6)) {
            printf("All axes initialized\n");
        } state done

        when (delay(10.0)) {
            printf("Timeout waiting for init\n");
        } state done
    }

    state done {
        when (delay(5.0)) {
        } state start
    }
}
```

### 13.5 Connection Management Pattern

```
program withConnCheck
option +r;
option -c;    /* Don't wait for connections at startup */

short startBtn;
assign startBtn to "{P}start";
monitor startBtn;

string statusMsg;
assign statusMsg to "{P}status";

ss main {
    state init {
        when (pvConnectCount() == pvChannelCount()) {
            sprintf(statusMsg, "Ready");
            pvPut(statusMsg);
        } state idle
    }

    state idle {
        when (pvConnectCount() < pvChannelCount()) {
            sprintf(statusMsg, "Lost connection");
            pvPut(statusMsg);
        } state init

        when (startBtn) {
            sprintf(statusMsg, "Running");
            pvPut(statusMsg);
        } state running
    }

    state running {
        when (delay(1.0)) {
            /* periodic work */
        } state running

        when (!startBtn) {
            sprintf(statusMsg, "Stopped");
            pvPut(statusMsg);
        } state idle
    }
}
```

---

## 14. Build Integration

### 14.1 configure/RELEASE

```makefile
SNCSEQ = /path/to/sequencer
EPICS_BASE = /path/to/base
```

### 14.2 src/Makefile

```makefile
# For an IOC application:
PROD_IOC = myApp

myApp_DBD += base.dbd

myApp_SRCS += myApp_registerRecordDeviceDriver.cpp
myApp_SRCS_DEFAULT += myAppMain.cpp
myApp_SRCS_vxWorks += -nil-

# Add the SNL program as a source
myApp_SRCS += myProgram.st

# Link with sequencer libraries
myApp_LIBS += seq pv
myApp_LIBS += $(EPICS_BASE_IOC_LIBS)
```

For a support library:
```makefile
LIBRARY_IOC += myLib
myLib_SRCS += myStateMachine.st
myLib_LIBS += seq pv
```

### 14.3 DBD Registration

The `snc` compiler (with default `+i` option) automatically generates IOC shell registrar code. No manual DBD entry is needed -- the generated C code includes `epicsExportRegistrar`.

For IOCs that include a library containing SNL programs, add the library's DBD to the IOC DBD.

### 14.4 Starting Programs in st.cmd

```bash
## Start with no parameters
seq myProgram

## Start with parameters
seq myProgram "prefix=IOC:,debug=0"

## Start with parameters and custom stack size
seq myProgram "prefix=IOC:" 20000
```

The `seq` command starts the program asynchronously -- it returns immediately and the state sets begin executing in their own threads.

### 14.5 Shell Commands for Running Programs

| Command | Description |
|---------|-------------|
| `seq prog "params"` | Start a program |
| `seqShow` | List all running programs and state sets |
| `seqShow threadID` | Show detailed state for a program instance |
| `seqChanShow threadID` | Show PV channel connections |
| `seqChanShow threadID "+"` | Show only connected channels |
| `seqChanShow threadID "-"` | Show only disconnected channels |
| `seqQueueShow threadID` | Show syncQ queue status |
| `seqcar` | Summary of all program channel connections |
| `seqcar 2` | Detailed per-channel connection report |
| `seqStop threadID` | Clean shutdown of a program instance |

---

## 15. Key Rules and Pitfalls

1. **`delay()` is only valid in transition conditions** (`when (delay(...))`). It returns whether the specified time has elapsed since entering the state. It is NOT a sleep function.

2. **Conditions should be side-effect-free.** They may be evaluated multiple times. The exception is `efTestAndClear()` and `pvGetQ()`, which have side effects but are designed for single use in conditions.

3. **`pvGetQ()` in conditions**: Use it alone or as the first operand of `&&`. Due to lazy evaluation, `pvGetQ(x) && someCheck(x)` is safe -- `someCheck` only runs if the queue was non-empty. But `someCheck(x) && pvGetQ(x)` may dequeue values that are then ignored.

4. **Only one pending async pvGet/pvPut per variable per state set.** Issuing a second async operation on the same variable before the first completes will fail (for pvPut) or be delayed (for pvGet with SYNC after ASYNC).

5. **Variables declared in action blocks** have block-local lifetime and CANNOT be assigned to PVs, monitored, or synced. Only top-level, state-set-local, and state-local variables have global lifetime.

6. **In safe mode (`+s`), `pvPut` is required** to make changes visible to other state sets. Simply modifying a global variable does not propagate the change.

7. **There is no `switch`/`case` statement** in SNL. Use `if`/`else if`/`else` chains instead.

8. **`string` is NOT `char*`** -- it is `char[MAX_STRING_SIZE]` (typically `char[40]`). A `string` variable assigned to a PV uses `DBR_STRING` with count 1, while `char arr[N]` uses `DBR_CHAR` with count N.

9. **Array sizes must be integer literals**, not constant expressions. `int arr[N]` where `N` is a `#define` works (after preprocessing), but `int arr[myConst]` where `myConst` is a variable does not.

10. **The `typename` keyword is required** before any C typedef name. `EPICS_TIME ts;` is invalid -- use `typename EPICS_TIME ts;` or `typename epicsTimeStamp ts;`.

11. **`+c` (default) blocks program startup** until ALL assigned PVs are connected. Use `-c` if the program should start even with disconnected PVs, then check `pvConnectCount()` in your state machine.

12. **`+r` (reentrant) mode** is required to run multiple instances of the same program. In reentrant mode, all global variables become members of a `UserVar` struct. SNL code handles this automatically, but escaped C code must use `pVar->varName` instead of `varName` directly.
