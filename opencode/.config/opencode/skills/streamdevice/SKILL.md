---
name: streamdevice
description: Write EPICS StreamDevice protocol files (.proto) and database records (.db) for byte-stream device communication (serial, TCP/IP, GPIB)
---

# EPICS StreamDevice Skill

You are an expert at writing EPICS StreamDevice support. StreamDevice provides generic EPICS device support for devices that communicate via byte streams (serial RS-232/RS-485, TCP/IP, GPIB). You write two kinds of files:

1. **Protocol files** (`.proto`) -- Define the communication sequences: what to send, what to expect back, and how to parse values.
2. **Database files** (`.db`) -- Define EPICS records that use `DTYP = "stream"` and reference protocol files via their INP/OUT links.

StreamDevice is NOT a programming language. Protocols are strictly linear (no loops, no branches, no conditionals). Each protocol is a simple sequence of commands.

---

## 1. Database Record Link Format

All StreamDevice records use:

```
field(DTYP, "stream")
field(INP,  "@filename.proto protocolname(arg1,arg2) busname [address [params]]")
field(OUT,  "@filename.proto protocolname(arg1,arg2) busname [address [params]]")
```

- `filename.proto` -- Protocol file (searched in `STREAM_PROTOCOL_PATH`)
- `protocolname` -- Name of the protocol block in the file
- `(arg1,arg2)` -- Optional comma-separated arguments substituted as `$1`, `$2`, etc.
- `busname` -- asynDriver port name (e.g., configured with `drvAsynIPPortConfigure` or `drvAsynSerialPortConfigure`)
- `address` -- Optional device address (integer)
- `params` -- Optional additional bus parameters

---

## 2. Protocol File Syntax

Protocol files are plain ASCII text. Comments start with `#` and extend to end of line. Statements end with `;`. The file contains global variable assignments and protocol definitions.

### 2.1 Structure

```
# Global variables apply to all protocols in the file
Terminator = CR LF;
ReplyTimeout = 1000;

# User-defined variables (abbreviations)
cmd_prefix = "DEV:";

# Protocol definition
getVoltage {
    # Local variables override globals for this protocol
    ReplyTimeout = 5000;

    out "${cmd_prefix}VOLT?";
    in "%f";
}

setVoltage {
    out "${cmd_prefix}VOLT %f";
    @init { getVoltage; }
}
```

### 2.2 Protocol Commands

| Command | Syntax | Description |
|---------|--------|-------------|
| `out` | `out "string";` | Send output to device. Format converters in the string are replaced with the record's value. |
| `in` | `in "string";` | Read and parse input from device. Input must match the literal parts of the string; format converters extract values. |
| `wait` | `wait milliseconds;` | Pause for the specified number of milliseconds. |
| `event` | `event(eventcode) timeout;` | Wait for a bus event with a timeout in milliseconds. |
| `exec` | `exec "iocsh_command";` | Execute an iocsh command. Format converters work like `out`. |
| `connect` | `connect timeout;` | Explicitly connect to the device with a timeout. |
| `disconnect` | `disconnect;` | Disconnect from the device. |

A protocol can reference another protocol by name to inline its commands:

```
getVoltage {
    out "VOLT?";
    in "%f";
}
setVoltage {
    out "VOLT %f";
    @init { getVoltage; }   # inlines: out "VOLT?"; in "%f";
}
```

### 2.3 Strings

Strings can be built from multiple components concatenated together:

**Quoted strings** -- Single or double quotes (no difference):
```
"Hello world\r\n"
'Hello world\r\n'
```

**Escape sequences** inside quotes:

| Escape | Meaning |
|--------|---------|
| `\\` `\"` `\'` `\%` | Literal character |
| `\a` | Bell (7) |
| `\b` | Backspace (8) |
| `\t` | Tab (9) |
| `\n` | Newline (10) |
| `\r` | Carriage return (13) |
| `\e` | Escape (27) |
| `\x##` | Hex byte (1-2 hex digits) |
| `\0###` | Octal byte (1-3 octal digits) |
| `\1`-`\9##` | Decimal byte (up to 3 digits total) |
| `\?` | Input: match any single byte. Output: nothing. |
| `\_` | Input: match any amount of whitespace (including none). Output: one space. |
| `\$var` | Variable substitution inside quotes |

**Named byte constants** (case-insensitive, used unquoted):
`NUL` `SOH` `STX` `ETX` `EOT` `ENQ` `ACK` `BEL` `BS` `HT`/`TAB` `LF`/`NL` `VT` `FF`/`NP` `CR` `SO` `SI` `DLE` `DC1` `DC2` `DC3` `DC4` `NAK` `SYN` `ETB` `CAN` `EM` `SUB` `ESC` `FS` `GS` `RS` `US` `DEL` `SKIP`/`?`

**Numeric byte values** (unquoted): Decimal (`13`), hex (`0x0D`), or octal (`015`).

Mixed composition example -- these are all equivalent:
```
"Hello world\r\n"
'Hello',0x20,"world",CR,LF
72 101 108 108 111 32 119 111 114 108 100 13 10
```

### 2.4 System Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `Terminator` | (none) | Sets both `InTerminator` and `OutTerminator` |
| `OutTerminator` | (none) | Appended to every `out` command output |
| `InTerminator` | (none) | Marks end of input; removed before parsing. If set to `""`, read timeout is a valid termination (not an error). |
| `Separator` | `""` | String between array elements (for waveform/aai/aao records) |
| `LockTimeout` | 5000 | ms to wait for exclusive device access (at first `out`) |
| `WriteTimeout` | 100 | ms to wait for output buffer to drain |
| `ReplyTimeout` | 1000 | ms to wait for first byte of device reply |
| `ReadTimeout` | 100 | ms to wait for additional input bytes after receiving starts |
| `PollPeriod` | = ReplyTimeout | ms between polls in I/O Intr mode |
| `MaxInput` | 0 (unlimited) | Maximum input bytes to read |
| `ExtraInput` | `Error` | What to do with unmatched trailing input: `Error` or `Ignore` |

Variables are case-insensitive. Set globally (file scope) or locally (protocol scope). Reference with `$variable` or `${variable}` outside quotes, `\$variable` or `\${variable}` inside quotes.

### 2.5 Protocol Arguments

Arguments passed from the record link are referenced as `$1` through `$9` (or `\$1`-`\$9` inside quotes). `$0` is the protocol name.

```
moveAxis {
    out "MOVE \$1 %f";
}
# Used as: @motor.proto moveAxis(X) motor1
#          @motor.proto moveAxis(Y) motor1
```

### 2.6 Exception Handlers

| Handler | Trigger |
|---------|---------|
| `@init` | Record initialization (iocInit, reconnect, `streamReload`, `streamReinit`, writing 2 to .PROC). Runs synchronously. Used to read initial values from the device for output records. Does NOT process the record or trigger FLNK. |
| `@mismatch` | Input does not match the `in` pattern. If the handler starts with `in`, it re-parses the same input. Record ends in INVALID/CALC alarm state. |
| `@replytimeout` | Device sends no reply at all within `ReplyTimeout`. |
| `@readtimeout` | Device starts replying but stops before input is complete (within `ReadTimeout`). |
| `@writetimeout` | Output cannot be written within `WriteTimeout`. |

Handlers can be defined globally (apply to all protocols in the file) or locally (within a protocol block). After a handler executes, the protocol terminates.

```
setVoltage {
    out "VOLT %f";
    @init { out "VOLT?"; in "%f"; }
    @replytimeout { disconnect; }
}
```

---

## 3. Format Converters

### 3.1 General Syntax

```
%[({field_or_record})][flags][width][.precision]conversion[extra]
```

`%%` produces a literal `%` character.

### 3.2 Flags

| Flag | Description |
|------|-------------|
| `-` | Left-justify output |
| `+` | Print `+` sign for positive numbers (or converter-specific meaning) |
| ` ` (space) | Print space before positive numbers (or converter-specific meaning) |
| `0` | Pad with zeros instead of spaces (or converter-specific meaning) |
| `#` | Alternate format (converter-specific meaning) |
| `*` | **Input only**: Skip -- consume and parse, but discard the value |
| `?` | **Input only**: Default -- if scan fails, use default value (0, 0.0, or "") instead of error |
| `=` | **Input only**: Compare -- format current record value and compare with input instead of scanning |
| `!` | **Input only**: Fixed width -- input must be exactly `width` bytes |

### 3.3 Field/Record Redirection

| Syntax | Description |
|--------|-------------|
| `%(FIELD)` | Read/write a field of the current record (e.g., `%(EGU)s`, `%(HOPR)f`, `%(A)f`) |
| `%(recordname.FIELD)` | Read/write a field of another record |
| `%(recordname)` | Read/write the VAL field of another record |
| `%(TIME)` | Access the record's EPICS timestamp (use with `%T`) |

If the other record is passive and the field has PP attribute, it will be processed.

### 3.4 Double Converters: `%f` `%e` `%E` `%g` `%G`

Data type: DOUBLE

| Converter | Output format |
|-----------|---------------|
| `%f` | Fixed-point (e.g., `3.140000`) |
| `%e` | Exponential (e.g., `3.140000e+00`) |
| `%E` | Exponential uppercase E |
| `%g` | Shorter of fixed or exponential |
| `%G` | Like `%g` with uppercase E |

All are equivalent for input -- they all read any floating-point number.

- `#` flag on output: always include decimal point. On input: accept whitespace between sign and number.
- `width`: minimum output width. On input with ` ` flag: leading whitespace counts toward width.
- `.precision`: digits after decimal point (output only). Not allowed on input.

### 3.5 Integer Converters: `%d` `%i` `%u` `%o` `%x` `%X`

Data type: LONG (signed) or ULONG (unsigned)

| Converter | Output | Input |
|-----------|--------|-------|
| `%d` | Signed decimal | Signed decimal |
| `%i` | Signed decimal | Auto-detect: decimal, `0x` hex, or `0` octal prefix |
| `%u` | Unsigned decimal | Unsigned decimal |
| `%o` | Unsigned octal | Unsigned octal (optional `0` prefix) |
| `%x` | Unsigned lowercase hex | Hex (upper/lower, optional `0x` prefix) |
| `%X` | Unsigned uppercase hex | Same as `%x` |

- `#` flag on output: prefix `0` for octal, `0x`/`0X` for hex. On input: accept whitespace between sign and number.
- `width` on `%x`/`%X` output: truncates to that many hex nibbles (least significant).
- `+` flag on `%x`/`%X` input: interpret as signed hex with sign extension.
- `-` flag on `%o`/`%x` input: accept negative values.
- `.precision`: not allowed on input.
- `%d`, `%i`, and `%x`/`%o` with `+` or `-` flag yield signed_format; `%u`, `%o`, `%x`/`%X` without those flags yield unsigned_format.

### 3.6 String Converters: `%s` `%c`

**`%s`** -- Data type: STRING

- Output: prints the string. `.precision` = max characters.
- Input: reads non-whitespace characters (default). Width = max chars (0 = unlimited).
- `#` flag on input: read until null byte instead of whitespace.
- `0` flag on output: pad with null bytes instead of spaces.

**`%c`** -- Data type: LONG for output, STRING for input

- Output: prints value as a single ASCII character.
- Input: reads `width` characters (default 1). Does NOT skip leading whitespace.

### 3.7 Charset Converter: `%[charset]`

Data type: STRING. **Input only.**

Matches characters from the specified set. `^` at start inverts. Ranges with `-`. To include `]`, put it first: `%[]abc]`. Does not skip leading whitespace.

```
in "%[0-9.]";      # match digits and periods
in "%[^,\r\n]";    # match everything except comma and line endings
```

### 3.8 Enum Converter: `%{str0|str1|str2|...}`

Data type: ENUM

Maps unsigned integer values to strings. Value 0 = first string, 1 = second, etc.

```
out "SWITCH %{OFF|ON}";       # 0 -> "OFF", 1 -> "ON"
in "STATE %{IDLE|RUN|ERROR}"; # "IDLE" -> 0, "RUN" -> 1, "ERROR" -> 2
```

With `#` flag, custom value assignments:
```
out "%#{neg=-1|zero=0|pos=1|fast=10}";
```

With `#` flag, `=?` on a string makes it the default for output if no other value matches:
```
out "%#{off=0|on=1|unknown=?}";   # unknown printed for any value other than 0 or 1
```

Escape `|` and `}` with `\`. If one enum string is a prefix of another, the shorter one must come later in the list (longer matches first).

### 3.9 Binary Converter: `%b` `%B`

Data type: LONG/ULONG

- `%b` -- Binary using `0` and `1` characters.
- `%Bzo` -- Binary using custom characters `z` (zero) and `o` (one). Example: `%B.!` uses `.` for 0, `!` for 1.
- `#` flag: little-endian (LSB first). Default: MSB first.
- `.precision`: number of significant bits.
- `0` flag: pad with zero-character instead of spaces.

### 3.10 Raw Integer Converter: `%r`

Data type: LONG (signed by default, unsigned with `0` flag)

Raw binary bytes -- the internal computer representation, not ASCII text.

- `.precision` (default **1**): number of bytes from the value. **Use `.precision`, not `width`, to specify output byte count.**
- `width`: total byte count (padded/extended).
- `#` flag: little-endian (LSB first). Default: big-endian (MSB first).
- `0` flag: unsigned (zero-fill padding). Default: signed (sign-extend).

**Common mistake**: `out "%2r"` sets width=2 but precision=1, sending only 1 value byte padded to 2. Correct: `out "%.2r"` sends 2 value bytes.

```
out "%.2r";          # 2 bytes big-endian signed
in "%#02r";          # 2 bytes little-endian unsigned
out "%.4r";          # 4 bytes big-endian signed
```

### 3.11 Raw Float Converter: `%R`

Data type: DOUBLE

Raw IEEE 754 floating-point bytes (not ASCII).

- `width` = 4 (float, default) or 8 (double).
- `#` flag: swap byte order (toggle endianness from native).

```
out "%4R";     # 4-byte IEEE float, native byte order
out "%#8R";    # 8-byte IEEE double, swapped byte order
```

### 3.12 BCD Converter: `%D`

Data type: LONG/ULONG

Packed Binary-Coded Decimal (2 decimal digits per byte: 0x00-0x99).

- `.precision`: number of BCD nibbles (digits).
- `width`: number of bytes.
- `+` flag: signed BCD (upper nibble of MSB encodes sign).
- `#` flag: little-endian.

### 3.13 Checksum Pseudo-Converter: `%<algorithm>`

Data type: pseudo (no record value -- calculates/verifies checksum over the data stream)

Calculates a checksum on output and appends it; verifies a checksum on input.

- `width`: byte offset to start checksumming from (default 0 = start of message).
- `.precision`: bytes before the checksum to exclude from calculation (default 0).
- `#` flag: little-endian byte order for multi-byte checksums.
- `0` flag: output as ASCII hex (2 characters per byte).
- `-` flag: output as "poor man's hex" (bytes 0x30-0x3F, 2 chars/byte).
- `+` flag: output as decimal ASCII (`%d` formatted).

**Supported algorithms:**

| Algorithm | Bytes | Description |
|-----------|-------|-------------|
| `sum` / `sum8` | 1 | Byte sum mod 256 |
| `sum16` | 2 | Byte sum mod 65536 |
| `sum32` | 4 | Byte sum mod 2^32 |
| `negsum` / `nsum` / `-sum` | 1 | Negative byte sum (two's complement) |
| `negsum16` / `nsum16` / `-sum16` | 2 | Negative byte sum |
| `negsum32` / `nsum32` / `-sum32` | 4 | Negative byte sum |
| `notsum` / `~sum` | 1 | Bitwise inverse of byte sum |
| `xor` / `xor8` | 1 | XOR of all bytes |
| `xor7` | 1 | XOR of all bytes, masked to 7 bits |
| `crc8` | 1 | CRC-8 (poly 0x07) |
| `ccitt8` | 1 | CRC-8/CCITT (poly 0x31, reflected) |
| `crc16` | 2 | CRC-16 (poly 0x8005) |
| `crc16r` | 2 | CRC-16 reflected |
| `modbus` | 2 | Modbus CRC (poly 0x8005, init 0xFFFF, reflected) |
| `ccitt16` | 2 | CRC-CCITT (poly 0x1021, init 0xFFFF) |
| `ccitt16a` | 2 | CRC-CCITT augmented (init 0x1D0F) |
| `ccitt16x` / `crc16c` / `xmodem` | 2 | XMODEM CRC (poly 0x1021, init 0x0000) |
| `crc32` | 4 | CRC-32 (poly 0x04C11DB7, init/xor 0xFFFFFFFF) |
| `crc32r` | 4 | CRC-32 reflected |
| `jamcrc` | 4 | JAMCRC (like CRC-32 reflected, xorout 0x00) |
| `adler32` | 4 | Adler-32 (RFC 1950) |
| `hexsum8` | 1 | Sum of hex digit values |
| `lrc` | 1 | Longitudinal Redundancy Check |
| `hexlrc` | 1 | LRC for hex digit pairs |
| `bitsum` / `bitsum8` | 1 | Count of set bits |
| `bitsum16` | 2 | Count of set bits |
| `bitsum32` | 4 | Count of set bits |
| `leybold` | 1 | Leybold-specific |
| `brksCryo` | 1 | Brooks Cryopumps-specific |
| `CPI` | 1 | TRIUMF CPI RF amplifier |

```
out "CMD %d%0<xor>";         # command with hex-ASCII XOR checksum appended
in "RESP %f%<modbus>";       # response with raw Modbus CRC verified
out "%s%0<sum>";             # string with hex-ASCII sum checksum
```

### 3.14 Regular Expression Converter: `%/regex/` (requires PCRE)

Data type: STRING. **Input only** (for scan).

Matches input against a PCRE regular expression. Non-anchored patterns skip leading non-matching input.

- `width`: max bytes to scan.
- `.precision` N: return the Nth sub-expression (default 0 = whole match).
- `+` flag: truncate match to fit buffer instead of failing.
- Use `(?i)` for case-insensitive, `(?m)` for multiline.
- Escape `/` in pattern as `\/`.

```
in "%.1/<title>(.*)<\/title>/";   # extract content of <title> tag (sub-expr 1)
in "%/[0-9]+\.[0-9]+/";          # match a decimal number as a string
```

### 3.15 Regex Substitution Pseudo-Converter: `%#/regex/subst/`

Data type: pseudo (pre/post-processes the data stream, no record value)

- In output: post-processes the formatted output before sending.
- In input: pre-processes received data before subsequent converters parse it.
- `&` in replacement = whole match; `\1`-`\9` = sub-expressions.
- `\U1` = uppercase, `\L1` = lowercase, `\u1` = uppercase first char, `\l1` = lowercase first char.
- `.precision` with `+` flag: max number of replacements. Without `+`: replace only the Nth match.
- `-` flag with `width`: process last N characters.

```
in "%#/,/ /%.6f";     # replace all commas with spaces, then parse float
out "%06d%#/..\B/&:/"; # format 6-digit number then insert colons: 123456 -> 12:34:56
```

### 3.16 Mantissa/Exponent Converter: `%m`

Data type: DOUBLE

Reads/writes numbers in mantissa-exponent format without `E` or `.` separator. Example: `+00123-02` = 1.23.

- `.precision`: digits in mantissa (default 6).
- Supports `+`, `-`, ` ` flags.

### 3.17 Timestamp Converter: `%T(format)`

Data type: DOUBLE (seconds since 1970-01-01 UTC)

Uses strftime-like format codes. Best used with `%(TIME)T(...)` to set the record's EPICS timestamp.

Additional codes beyond standard strftime:
- `%.nS` -- seconds with n fractional digits.
- `%f` / `%N` -- nanoseconds (9 digits).
- `%0nf` -- fractional seconds with n digits.
- `%+hhmm` / `%-hhmm` -- timezone offset in format string.

```
in "%(TIME)T(%Y-%m-%d %H:%M:%.3S)";   # parse timestamp, set record TIME field
out "%T(%H:%M:%S)";                    # output current value as time string
```

---

## 4. Record Type Reference

Each record type supports specific format converter data types. Using an unsupported format type causes an error.

### 4.1 ai (Analog Input)

| Format | Output (for `out` commands) | Input (for `in` commands) |
|--------|------|-------|
| DOUBLE (`%f`) | `x = (VAL - AOFF) / ASLO` | `VAL = x * ASLO + AOFF` (SMOO applied unless `@init`) |
| LONG (`%i`) | `x = RVAL` | `RVAL = x`, then record converts via LINR/ESLO/EOFF. If LINR=`NO CONVERSION` (default), `VAL = (double)x` directly. |

ENUM and STRING: not supported.

Defaults: ASLO=1 (0 treated as 1), AOFF=0, SMOO=0. During `@init`, SMOO is ignored.

### 4.2 ao (Analog Output)

| Format | Output | Input |
|--------|--------|-------|
| DOUBLE (`%f`) | `x = (OVAL - AOFF) / ASLO` | `VAL = x * ASLO + AOFF` |
| LONG (`%i`) | `x = RVAL` | `RBV = RVAL = x`, record converts via LINR |

ENUM and STRING: not supported. During `@init`, DOUBLE output uses VAL not OVAL. OVAL may differ from VAL if OROC != 0.

### 4.3 bi (Binary Input)

| Format | Output | Input |
|--------|--------|-------|
| LONG (`%i`) | `x = RVAL` | `RVAL = x & MASK` (MASK=0: no masking). Record sets `VAL = (RVAL != 0)` |
| ENUM (`%{`) | `x = VAL` | `VAL = (x != 0)` |
| STRING (`%s`) | `x = VAL ? ONAM : ZNAM` | VAL set to 0 if input matches ZNAM, 1 if matches ONAM |

DOUBLE: not supported.

### 4.4 bo (Binary Output)

| Format | Output | Input |
|--------|--------|-------|
| LONG (`%i`) | `x = RVAL` | `RBV = x & MASK` (MASK=0: no masking) |
| ENUM (`%{`) | `x = VAL` | `VAL = (x != 0)` |
| STRING (`%s`) | `x = VAL ? ONAM : ZNAM` | VAL set to 0 if matches ZNAM, 1 if ONAM |

DOUBLE: not supported. During `@init`, LONG input goes to RVAL and is converted by the record.

### 4.5 longin (Long Input)

| Format | Output | Input |
|--------|--------|-------|
| LONG (`%i`) | `x = VAL` | `VAL = x` |
| ENUM (`%{`) | `x = VAL` | `VAL = x` |

DOUBLE and STRING: not supported.

### 4.6 longout (Long Output)

| Format | Output | Input |
|--------|--------|-------|
| LONG (`%i`) | `x = VAL` | `VAL = x` |
| ENUM (`%{`) | `x = VAL` | `VAL = x` |

DOUBLE and STRING: not supported.

### 4.7 int64in / int64out (EPICS base 3.16+)

Same as longin/longout but with 64-bit integer range. Supports LONG and ENUM formats.

### 4.8 stringin (String Input)

| Format | Output | Input |
|--------|--------|-------|
| STRING (`%s`) | `x = VAL` | `VAL = x` |

Only STRING format supported. Max 40 characters (EPICS string limit).

### 4.9 stringout (String Output)

| Format | Output | Input |
|--------|--------|-------|
| STRING (`%s`) | `x = VAL` | `VAL = x` |

Only STRING format supported.

### 4.10 lsi (Long String Input, EPICS base 3.15+)

Same as stringin but supports strings longer than 40 characters. Only STRING format. `LEN` field updated on input.

### 4.11 lso (Long String Output, EPICS base 3.15+)

Same as stringout but supports long strings. Only STRING format.

### 4.12 mbbi (Multi-Bit Binary Input)

| Format | Output | Input |
|--------|--------|-------|
| LONG (`%i`) | If ZRVL..FFVL defined: `x = RVAL & MASK`. Else: `x = VAL` | If ZRVL..FFVL defined: `RVAL = x & MASK` (record maps to VAL). Else: `VAL = x` |
| ENUM (`%{`) | `x = VAL` | `VAL = x` |
| STRING (`%s`) | One of ZRST..FFST based on VAL | VAL = index of matching ZRST..FFST string |

DOUBLE: not supported. MASK = NOBT 1-bits shifted left by SHFT.

### 4.13 mbbo (Multi-Bit Binary Output)

| Format | Output | Input |
|--------|--------|-------|
| LONG (`%i`) | If ZRVL..FFVL defined: `x = RVAL & MASK`. Else: `x = (VAL << SHFT) & MASK` | If ZRVL..FFVL defined: `RBV = RVAL = x & MASK`. Else: `VAL = (RBV = x & MASK) >> SHFT` |
| ENUM (`%{`) | `x = VAL` | `VAL = x` |
| STRING (`%s`) | One of ZRST..FFST based on VAL | VAL = index of matching ZRST..FFST string |

DOUBLE: not supported.

### 4.14 mbbiDirect / mbboDirect

Only LONG format supported (no ENUM, no STRING, no DOUBLE).

- mbbiDirect: If MASK!=0: `RVAL = x & MASK`. If MASK==0: `VAL = x`.
- mbboDirect: If MASK!=0: `RBV = RVAL = x & MASK`, `VAL = RVAL >> SHFT`. If MASK==0: `RVAL = x`.

MASK = ((2^NOBT) - 1) << SHFT.

### 4.15 calcout (Calculation Output, EPICS base 3.14+)

| Format | Output | Input |
|--------|--------|-------|
| DOUBLE (`%f`) | `x = OVAL` | `VAL = x` |
| LONG (`%i`) | `x = (int)OVAL` | `VAL = x` |
| ENUM (`%{`) | `x = (int)OVAL` | `VAL = x` |

STRING: not supported. CALC field must always contain a valid expression (e.g., `"0"`). More useful to access fields A-L directly with `%(A)f`, `%(B)f`, etc.

### 4.16 scalcout (String Calculation Output, requires synApps calc)

| Format | Output | Input |
|--------|--------|-------|
| DOUBLE (`%f`) | `x = OVAL` | `VAL = x` |
| LONG (`%i`) | `x = (int)OVAL` | `VAL = x` |
| ENUM (`%{`) | `x = (int)OVAL` | `VAL = x` |
| STRING (`%s`) | `x = OSV` | `SVAL = x` |

Access numeric fields A-L with `%(A)f` and string fields AA-LL with `%(AA)s`.

### 4.17 waveform / aai / aao (Array Records)

Format converters are applied to **each array element**. The `Separator` variable defines the string between elements.

- Input: up to NELM elements read. NORD updated. Parsing stops on separator mismatch, conversion failure, or end of input (at least 1 element required).
- Output: first NORD elements written.

| Format | FTVL compatibility |
|--------|--------------------|
| DOUBLE (`%f`) | Output: all FTVL types. Input: FLOAT, DOUBLE only. |
| LONG (`%i`) | Output/Input: integer FTVL types (CHAR, UCHAR, SHORT, USHORT, LONG, ULONG, INT64, UINT64), plus FLOAT, DOUBLE. |
| ENUM (`%{`) | Same as LONG. |
| STRING (`%s`) | If FTVL=STRING: array of strings, one per element. If FTVL=CHAR or UCHAR: entire waveform treated as one large string (NORD = length, max NELM-1 chars). No separator used for CHAR/UCHAR. |

---

## 5. Common Patterns and Examples

### 5.1 Simple Query/Response with @init

The most common pattern: an output record that sets a value and an `@init` handler to read the current value at startup.

```
# power_supply.proto
Terminator = CR LF;

getCurrent {
    out "CURR?";
    in "%f";
}

setCurrent {
    out "CURR %f";
    @init { getCurrent; }
}

getVoltage {
    out "VOLT?";
    in "%f";
}

setVoltage {
    out "VOLT %f";
    @init { getVoltage; }
}
```

```
# power_supply.db
record(ai, "$(P):Current:RBV") {
    field(DTYP, "stream")
    field(INP,  "@power_supply.proto getCurrent $(PORT)")
    field(EGU,  "A")
    field(PREC, "3")
    field(SCAN, "1 second")
}

record(ao, "$(P):Current") {
    field(DTYP, "stream")
    field(OUT,  "@power_supply.proto setCurrent $(PORT)")
    field(EGU,  "A")
    field(PREC, "3")
    field(DRVL, "0")
    field(DRVH, "60")
}

record(ai, "$(P):Voltage:RBV") {
    field(DTYP, "stream")
    field(INP,  "@power_supply.proto getVoltage $(PORT)")
    field(EGU,  "V")
    field(PREC, "3")
    field(SCAN, "1 second")
}

record(ao, "$(P):Voltage") {
    field(DTYP, "stream")
    field(OUT,  "@power_supply.proto setVoltage $(PORT)")
    field(EGU,  "V")
    field(PREC, "3")
    field(DRVL, "0")
    field(DRVH, "30")
}
```

### 5.2 Parameterized Protocols

Use protocol arguments to avoid repeating nearly identical protocols:

```
# generic.proto
Terminator = CR LF;

getFloat {
    out "\$1?";
    in "%f";
}

setFloat {
    out "\$1 %f";
    @init { getFloat; }
}

getInt {
    out "\$1?";
    in "%d";
}

setInt {
    out "\$1 %d";
    @init { getInt; }
}
```

```
# Records referencing parameterized protocols
record(ao, "$(P):Voltage") {
    field(DTYP, "stream")
    field(OUT,  "@generic.proto setFloat(VOLT) $(PORT)")
    ...
}
record(ao, "$(P):Current") {
    field(DTYP, "stream")
    field(OUT,  "@generic.proto setFloat(CURR) $(PORT)")
    ...
}
record(longout, "$(P):Channel") {
    field(DTYP, "stream")
    field(OUT,  "@generic.proto setInt(CHAN) $(PORT)")
    ...
}
```

### 5.3 Binary/Enum Switching

```
# switch.proto
Terminator = CR LF;

getSwitch {
    out "SW?";
    in "SW %{OFF|ON}";
}

setSwitch {
    out "SW %{OFF|ON}";
    @init { getSwitch; }
}
```

```
record(bo, "$(P):Switch") {
    field(DTYP, "stream")
    field(OUT,  "@switch.proto setSwitch $(PORT)")
    field(ZNAM, "OFF")
    field(ONAM, "ON")
}

record(bi, "$(P):Switch:RBV") {
    field(DTYP, "stream")
    field(INP,  "@switch.proto getSwitch $(PORT)")
    field(ZNAM, "OFF")
    field(ONAM, "ON")
    field(SCAN, "1 second")
}
```

### 5.4 I/O Intr for Unsolicited Data

Devices that send data without being asked. The record uses `SCAN = "I/O Intr"` and the protocol has only an `in` command (no `out`).

```
# monitor.proto
Terminator = CR LF;

readTemperature {
    in "TEMP=%f";
}
```

```
record(ai, "$(P):Temperature") {
    field(DTYP, "stream")
    field(INP,  "@monitor.proto readTemperature $(PORT)")
    field(EGU,  "C")
    field(PREC, "1")
    field(SCAN, "I/O Intr")
}
```

### 5.5 Reading Multiple Values from One Response

**Method A: Skip unwanted values with `%*`**

```
# Two records share the same response "X=1.23,Y=4.56"
getX {
    out "POS?";
    in "X=%f,Y=%*f";
}
getY {
    in "X=%*f,Y=%f";   # no out -- uses I/O Intr to catch reply from getX
}
```

The X record is polled normally; the Y record uses `SCAN = "I/O Intr"` and passively catches the same response.

**Method B: Field redirection to other records**

```
getXY {
    out "POS?";
    in "X=%f,Y=%(\$1)f";   # $1 = PV name of the Y record
}
```

**Method C: Array records**

```
getArray {
    Separator = ",";
    out "DATA?";
    in "%f";
}
```

Use with a waveform record (FTVL=DOUBLE, NELM=N).

### 5.6 Writing Multiple Values

**Using calcout field redirection:**

```
setPosition {
    out "POS %(A)f,%(B)f,%(C)f";
}
```

```
record(calcout, "$(P):SetPos") {
    field(DTYP, "stream")
    field(OUT,  "@dev.proto setPosition $(PORT)")
    field(CALC, "0")
    field(A,    "0")
    field(B,    "0")
    field(C,    "0")
}
```

### 5.7 Mixed Data Types with @mismatch

When a device might reply with a number OR a string (e.g., "ERROR"):

```
readCurrent {
    out "CURR?";
    in "%f";
    @mismatch { in "%(\$1)39c"; }
}
```

On success, the ai record gets the float value. On mismatch (e.g., device replies "ERROR"), the error message is written to the stringin record specified by `$1`.

### 5.8 Checksum Example

```
InTerminator = CR;
OutTerminator = "%0<xor>" CR;   # append hex XOR checksum before CR

sendCommand {
    out "CMD:%s";                # checksum covers "CMD:value"
}

readResponse {
    in "RSP:%f%0<xor>";          # verify hex XOR checksum
}
```

### 5.9 Large String with Waveform

For strings longer than the 40-character EPICS string limit, use a waveform record with `FTVL = CHAR`:

```
readLongString {
    out "LONGDATA?";
    in "%1000c";
}
```

```
record(waveform, "$(P):LongString") {
    field(DTYP, "stream")
    field(INP,  "@dev.proto readLongString $(PORT)")
    field(FTVL, "CHAR")
    field(NELM, "1000")
    field(SCAN, "1 second")
}
```

### 5.10 Raw Binary Protocol

For devices that communicate with raw binary data instead of ASCII text:

```
OutTerminator = "";
InTerminator = "";
MaxInput = 6;

readRegister {
    out 0x02 "%.2r" 0x03;        # STX + 2-byte register address + ETX
    in  0x02 "%\?%.4r" 0x03;     # STX + skip 1 byte + 4-byte value + ETX
}
```

---

## 6. Debugging

- **Global debug**: `var streamDebug 1` (or 2 for verbose) in the IOC shell.
- **Per-record debug**: Set the record's `.TPRO` field to 1 (or 2 for extra detail).
- **Reload protocols**: `streamReload` (all records) or `streamReload("recordname")` (glob patterns supported).
- **Error suppression**: `var streamErrorDeadTime 10` suppresses repeated timeout messages for 10 seconds.
- **Log to file**: `streamSetLogfile("debug.log")`.

### Alarm States on Error

| Alarm STAT | Cause |
|------------|-------|
| `TIMEOUT` | Device locked by others or no reply |
| `WRITE` | Output could not be written |
| `READ` | Input started but stopped unexpectedly |
| `COMM` | Device disconnected |
| `CALC` | Input mismatch or invalid value |
| `UDF` | Fatal error or not initialized |

---

## 7. Key Rules and Pitfalls

1. **Protocols are linear** -- no loops, no branches, no conditionals.
2. **One protocol per record processing** -- a record's INP/OUT field references exactly one protocol.
3. **`@init` does NOT process the record** -- it runs synchronously during iocInit and does not trigger FLNK or PP links. It runs BEFORE PINI.
4. **`%r` precision vs width** -- `.precision` sets the number of value bytes; `width` sets the total padded size. Use `%.2r`, not `%2r`.
5. **ExtraInput = Ignore** -- set this when the device sends more data than you parse. Otherwise, unmatched trailing input causes an error.
6. **InTerminator = ""** -- when set to empty string, `ReadTimeout` is a valid end-of-message (not an error). Use this for devices with no terminator and fixed-length responses.
7. **Enum ordering** -- if one enum string is a prefix of another, the shorter string must come LATER in the list (longer matches tried first on input).
8. **Array records need Separator** -- for waveform/aai/aao with multiple elements, define the `Separator` variable to match the delimiter between values.
9. **String length limits** -- stringin/stringout: 40 chars max. Use lsi/lso (EPICS 3.15+) or waveform with FTVL=CHAR for longer strings.
10. **I/O Intr records receive ALL input** -- including replies to other records on the same port. The `in` pattern must be specific enough to match only the intended messages. Non-matching input is silently ignored.
