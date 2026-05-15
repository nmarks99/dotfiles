---
name: pydm
description: Build PyDM control system display applications -- Display subclasses, .ui file generation, widget properties, channel addressing, rules, macros, custom widgets, data plugins, and stylesheets
---

# PyDM Application Development Skill

You are an expert at building control system display applications with **PyDM** (Python Display Manager). PyDM is a Python-Qt framework for building user interfaces that connect to EPICS and other control system data sources. You build displays in three ways:

1. **`.ui` files** -- XML-based Qt Designer files with PyDM widgets. You generate the XML directly.
2. **Python `Display` subclasses** -- Python classes that combine `.ui` files with application logic, or build UIs entirely in code.
3. **Extensions** -- Custom widgets, data plugins, and external tools registered via entrypoints.

PyDM uses `qtpy` to abstract over PyQt5 and PySide6. The `QT_API` environment variable (`pyqt5` or `pyside6`) selects the binding at runtime.

---

## 1. Project Setup

### 1.1 Prerequisites

- Python >= 3.10, <= 3.12
- `QT_API` environment variable **must** be set to `pyqt5` or `pyside6`
- Runtime dependencies: `qtpy>=2.2.0`, `pyqtgraph>=0.12.0`, `numpy>=1.11.0`, `pyepics>=3.2.7`

### 1.2 Single-File Display

The simplest project is a single `.ui` or `.py` file:

```
my_screen.ui          # launched with: pydm my_screen.ui
```

Or a Python display:

```
my_display.py         # launched with: pydm my_display.py
```

### 1.3 Multi-Display Project

A typical multi-display project:

```
my_project/
├── home.ui                  # main entry screen
├── detail_screen.ui         # linked via PyDMRelatedDisplayButton
├── plot_view.py             # Python Display subclass
├── templates/
│   └── device_row.ui        # template for PyDMTemplateRepeater
├── data/
│   └── devices.json         # macro data for template repeater
└── styles/
    └── custom.qss           # custom stylesheet
```

Launch with:

```bash
pydm my_project/home.ui
pydm --stylesheet my_project/styles/custom.qss my_project/home.ui
```

### 1.4 Installable Package

For distributing custom widgets, data plugins, or tools, create a Python package with entrypoints:

```
my_pydm_package/
├── pyproject.toml
└── src/
    └── my_package/
        ├── __init__.py
        ├── widgets/
        │   └── my_widget.py
        ├── plugins/
        │   └── my_plugin.py
        └── tools/
            └── my_tool.py
```

Register entrypoints in `pyproject.toml`:

```toml
[project.entry-points."pydm.widget"]
MyWidget = "my_package.widgets.my_widget:MyWidget"

[project.entry-points."pydm.data_plugin"]
myproto = "my_package.plugins.my_plugin:MyPlugin"

[project.entry-points."pydm.tool"]
MyTool = "my_package.tools.my_tool:MyExternalTool"
```

---

## 2. Channel Addressing

Every PyDM widget connects to data sources via **channel addresses** with a protocol prefix.

### 2.1 Protocol Prefixes

| Protocol | Address Format | Description |
|----------|---------------|-------------|
| `ca://` | `ca://PVNAME` | EPICS Channel Access (default backend: pyepics) |
| `pva://` | `pva://PVNAME` | EPICS PV Access (backend: p4p) |
| `loc://` | `loc://name?type=T&init=V` | Local in-process variable |
| `calc://` | `calc://name?expr=E&var=CH` | Calculated/derived channel |
| `archiver://` | `archiver://PVNAME` | EPICS Archiver Appliance data |
| `fake://` | `fake://anything` | Test plugin emitting random strings |

If `PYDM_DEFAULT_PROTOCOL` is set (e.g., `ca`), the prefix can be omitted: `MTEST:Float` becomes `ca://MTEST:Float`.

### 2.2 Local Plugin Format (`loc://`)

```
loc://name?type=TYPE&init=VALUE[&optional_params...]
```

**Required parameters:**

| Parameter | Values |
|-----------|--------|
| `type` | `int`, `float`, `str`, `bool`, `array` |
| `init` | Initial value (e.g., `0`, `3.14`, `hello`, `[1,2,3]`) |

**Optional parameters:**

| Parameter | Description |
|-----------|-------------|
| `precision` | Display precision for floats |
| `unit` | Engineering units string |
| `upper_limit` / `lower_limit` | Control limits (int/float) |
| `enum_string` | Tuple of enum strings, e.g., `('Off','On')` |
| `dtype` | Numpy dtype for arrays (e.g., `float64`) |

**Examples:**

```
loc://my_float?type=float&init=3.14
loc://my_int?type=int&init=42&upper_limit=100&lower_limit=0
loc://my_str?type=str&init=hello
loc://my_bool?type=bool&init=true
loc://my_array?type=array&init=[1,2,3]&dtype=float64
loc://my_var?type=float&init=0.0&precision=4&unit=mm
loc://my_enum?type=int&init=0&enum_string=('Off','On','Error')
```

Local channels have write access. Values written are broadcast to all listeners.

### 2.3 Calc Plugin Format (`calc://`)

```
calc://name?expr=EXPRESSION&varA=CHANNEL_A&varB=CHANNEL_B[&update=varA,varB]
```

- `expr` -- Python expression using variable names defined in the query parameters
- Named variables map to channel addresses (any protocol)
- `update` -- comma-separated list of variable names that trigger recalculation (if omitted, any variable update triggers it)

**Expression environment:**

| Name | Description |
|------|-------------|
| Variable names | Current values of referenced channels |
| `prev_res` | Previous result of this calc channel |
| `np` / `numpy` | NumPy module |
| `math.*` | All `math` module functions (sin, cos, sqrt, etc.) |
| `epics_string(val)` | Convert char waveform ndarray to string |
| `epics_unsigned(val, bits=32)` | Interpret signed int as unsigned |

**Examples:**

```
calc://sum?expr=a+b&a=ca://PV:A&b=ca://PV:B
calc://scaled?expr=x*2.5+offset&x=ca://PV:RAW&offset=ca://PV:OFFSET&update=x
calc://rms?expr=np.sqrt(np.mean(wf**2))&wf=ca://PV:Waveform
calc://toggle?expr=not prev_res&dummy=loc://trigger?type=int&init=0
```

Calc channels are read-only.

---

## 3. Display Development

### 3.1 Generating `.ui` Files

`.ui` files are XML. The AI generates them directly. Every `.ui` file follows this structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Form</class>
 <widget class="QWidget" name="Form">
  <property name="geometry">
   <rect><x>0</x><y>0</y><width>400</width><height>300</height></rect>
  </property>
  <property name="windowTitle">
   <string>My Display</string>
  </property>

  <!-- Layout and widgets go here -->

 </widget>

 <!-- Declare ALL PyDM widgets used -->
 <customwidgets>
  <customwidget>
   <class>PyDMLabel</class>
   <extends>QLabel</extends>
   <header>pydm.widgets.label</header>
  </customwidget>
 </customwidgets>
</ui>
```

**Critical rules for `.ui` XML:**

1. **All PyDM-specific properties use `stdset="0"`**. Standard Qt properties (geometry, text, etc.) omit this attribute.
2. **Every PyDM widget class used must be declared in `<customwidgets>`** with the correct `<extends>` base class and `<header>` module path.
3. **Channel addresses include the protocol prefix**: `ca://MTEST:Float`, not just `MTEST:Float`.
4. **Macros use `${NAME}` syntax** in any string property value.

**Widget-to-header mapping** (for `<customwidgets>` declarations):

| Widget Class | Extends | Header |
|---|---|---|
| `PyDMLabel` | `QLabel` | `pydm.widgets.label` |
| `PyDMLineEdit` | `QLineEdit` | `pydm.widgets.line_edit` |
| `PyDMPushButton` | `QPushButton` | `pydm.widgets.pushbutton` |
| `PyDMSlider` | `QFrame` | `pydm.widgets.slider` |
| `PyDMSpinbox` | `QDoubleSpinBox` | `pydm.widgets.spinbox` |
| `PyDMCheckbox` | `QCheckBox` | `pydm.widgets.checkbox` |
| `PyDMEnumComboBox` | `QComboBox` | `pydm.widgets.enum_combo_box` |
| `PyDMEnumButton` | `QWidget` | `pydm.widgets.enum_button` |
| `PyDMByteIndicator` | `QWidget` | `pydm.widgets.byte` |
| `PyDMMultiStateIndicator` | `QWidget` | `pydm.widgets.byte` |
| `PyDMScaleIndicator` | `QFrame` | `pydm.widgets.scale` |
| `PyDMImageView` | `QWidget` | `pydm.widgets.image` |
| `PyDMSymbol` | `QWidget` | `pydm.widgets.symbol` |
| `PyDMDateTimeLabel` | `QLabel` | `pydm.widgets.datetime` |
| `PyDMDateTimeEdit` | `QDateTimeEdit` | `pydm.widgets.datetime` |
| `PyDMTimePlot` | `QGraphicsView` | `pydm.widgets.timeplot` |
| `PyDMArchiverTimePlot` | `QGraphicsView` | `pydm.widgets.archiver_time_plot` |
| `PyDMWaveformPlot` | `QGraphicsView` | `pydm.widgets.waveformplot` |
| `PyDMScatterPlot` | `QGraphicsView` | `pydm.widgets.scatterplot` |
| `PyDMEventPlot` | `QGraphicsView` | `pydm.widgets.eventplot` |
| `PyDMEmbeddedDisplay` | `QFrame` | `pydm.widgets.embedded_display` |
| `PyDMTemplateRepeater` | `QFrame` | `pydm.widgets.template_repeater` |
| `PyDMRelatedDisplayButton` | `QPushButton` | `pydm.widgets.related_display_button` |
| `PyDMShellCommand` | `QPushButton` | `pydm.widgets.shell_command` |
| `PyDMTabWidget` | `QTabWidget` | `pydm.widgets.tab_bar` |
| `PyDMFrame` | `QFrame` | `pydm.widgets.frame` |
| `PyDMNTTable` | `QWidget` | `pydm.widgets.nt_table` |
| `PyDMWaveformTable` | `QTableWidget` | `pydm.widgets.waveformtable` |
| `PyDMDrawingLine` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingRectangle` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingCircle` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingEllipse` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingTriangle` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingArc` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingPie` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingChord` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingImage` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingPolyline` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingPolygon` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMDrawingIrregularPolygon` | `QWidget` | `pydm.widgets.drawing` |
| `PyDMLogDisplay` | `QWidget` | `pydm.widgets.logdisplay` |
| `PyDMAnalogIndicator` | `QFrame` | `pydm.widgets.analog_indicator` |
| `PyDMTerminator` | `QLabel` | `pydm.widgets.terminator` |

**Example: label with channel and alarm sensitivity:**

```xml
<widget class="PyDMLabel" name="temperatureLabel">
 <property name="geometry">
  <rect><x>10</x><y>10</y><width>200</width><height>30</height></rect>
 </property>
 <property name="channel" stdset="0">
  <string>ca://MTEST:Float</string>
 </property>
 <property name="alarmSensitiveContent" stdset="0">
  <bool>true</bool>
 </property>
 <property name="showUnits" stdset="0">
  <bool>true</bool>
 </property>
</widget>
```

**Example: line edit (writable) with precision:**

```xml
<widget class="PyDMLineEdit" name="setpointEdit">
 <property name="channel" stdset="0">
  <string>ca://MTEST:Float</string>
 </property>
 <property name="precisionFromPV" stdset="0">
  <bool>true</bool>
 </property>
</widget>
```

**Example: time plot with curves:**

Curves are stored as a `<stringlist>` of JSON objects:

```xml
<widget class="PyDMTimePlot" name="timePlot">
 <property name="title" stdset="0">
  <string>Temperature History</string>
 </property>
 <property name="timeSpan" stdset="0">
  <double>60.0</double>
 </property>
 <property name="bufferSize" stdset="0">
  <number>18000</number>
 </property>
 <property name="curves">
  <stringlist>
   <string>{"channel": "ca://MTEST:Float", "name": "Temperature", "color": "white", "lineStyle": 1, "lineWidth": 2, "symbol": null, "symbolSize": 10}</string>
   <string>{"channel": "ca://MTEST:MinValue", "name": "Min", "color": "dodgerblue", "lineStyle": 3, "lineWidth": 1, "symbol": null, "symbolSize": 10}</string>
  </stringlist>
 </property>
</widget>
```

**Curve JSON keys:**

| Key | Type | Description |
|-----|------|-------------|
| `channel` | string | Full channel address with protocol |
| `name` | string | Legend label |
| `color` | string | CSS color name or hex (e.g., `"white"`, `"#FF0000"`) |
| `lineStyle` | int | Qt PenStyle: 1=Solid, 2=Dash, 3=Dot, 4=DashDot, 5=DashDotDot |
| `lineWidth` | int | Line width in pixels |
| `symbol` | null or string | pyqtgraph symbol character (e.g., `"o"`, `"s"`, `"t"`) |
| `symbolSize` | int | Symbol size in pixels |

For `PyDMWaveformPlot`, use `y_channel` and `x_channel` instead of `channel`:

```xml
<string>{"y_channel": "ca://MTEST:Waveform", "x_channel": "ca://MTEST:TimeBase", "name": "Waveform", "color": "white"}</string>
```

**Example: embedded display with macros:**

```xml
<widget class="PyDMEmbeddedDisplay" name="embeddedView">
 <property name="filename" stdset="0">
  <string>detail.ui</string>
 </property>
 <property name="macros" stdset="0">
  <string>{"PREFIX": "MTEST"}</string>
 </property>
</widget>
```

**Example: related display button:**

```xml
<widget class="PyDMRelatedDisplayButton" name="detailButton">
 <property name="text">
  <string>Open Detail</string>
 </property>
 <property name="displayFilename" stdset="0">
  <string>detail.ui</string>
 </property>
 <property name="macros" stdset="0">
  <string>{"PREFIX": "MTEST"}</string>
 </property>
</widget>
```

**Example: template repeater with JSON data source:**

```xml
<widget class="PyDMTemplateRepeater" name="deviceList">
 <property name="templateFilename" stdset="0">
  <string>templates/device_row.ui</string>
 </property>
 <property name="dataSource" stdset="0">
  <string>data/devices.json</string>
 </property>
 <property name="layoutType" stdset="0">
  <enum>PyDMTemplateRepeater::Vertical</enum>
 </property>
</widget>
```

Where `devices.json` is:

```json
[
  {"devname": "DEVICE:001"},
  {"devname": "DEVICE:002"},
  {"devname": "DEVICE:003"}
]
```

And `device_row.ui` uses `${devname}` macros in channel addresses.

### 3.2 Python Display Subclass

Subclass `pydm.Display` to combine `.ui` files with Python logic:

```python
from pydm import Display

class MyDisplay(Display):
    def __init__(self, parent=None, args=None, macros=None):
        super().__init__(parent=parent, args=args, macros=macros)
        # self.ui is self after load_ui completes
        # Access widgets by their objectName: self.ui.myLabel, self.ui.myPlot, etc.

    def ui_filename(self):
        return "my_display.ui"

    def ui_filepath(self):
        # Default joins the directory of THIS Python file with ui_filename().
        # Override only if the .ui file is in a non-standard location.
        return None  # use default behavior

    def menu_items(self):
        # Custom entries added to the menu bar.
        # Values: callable, nested dict (submenu), or (callable, shortcut_string) tuple.
        return {
            "Reset": self.reset_values,
            "Advanced": {"Calibrate": self.calibrate},
            "Save Config": (self.save_config, "Ctrl+S"),
        }

    def file_menu_items(self):
        # Keys limited to: "save", "save_as", "load"
        return {
            "save": self.save_data,
            "load": (self.load_data, "Ctrl+L"),
        }
```

**Accessing macros in Python:**

```python
def __init__(self, parent=None, args=None, macros=None):
    super().__init__(parent=parent, args=args, macros=macros)
    prefix = self.macros().get("PREFIX", "DEFAULT")
    self.ui.titleLabel.setText(f"Device: {prefix}")
```

### 3.3 Code-Only Displays

Build the UI entirely in Python without a `.ui` file:

```python
from pydm import Display
from pydm.widgets import PyDMLabel, PyDMLineEdit, PyDMTimePlot
from qtpy.QtWidgets import QVBoxLayout, QHBoxLayout

class MyDisplay(Display):
    def __init__(self, parent=None, args=None, macros=None):
        super().__init__(parent=parent, args=args, macros=macros)
        layout = QVBoxLayout()

        row = QHBoxLayout()
        label = PyDMLabel(init_channel="ca://MTEST:Float")
        label.showUnits = True
        edit = PyDMLineEdit(init_channel="ca://MTEST:Float")
        row.addWidget(label)
        row.addWidget(edit)
        layout.addLayout(row)

        plot = PyDMTimePlot()
        plot.addYChannel(y_channel="ca://MTEST:Float", name="Value", color="white")
        layout.addWidget(plot)

        self.setLayout(layout)

    def ui_filename(self):
        return None

    def ui_filepath(self):
        return None
```

---

## 4. Macros

Macros enable reusable displays by substituting `${NAME}` placeholders with values at load time.

### 4.1 Syntax

Use `${MACRO_NAME}` in any string property value in `.ui` files:

```xml
<property name="channel" stdset="0">
 <string>ca://${PREFIX}:Temperature</string>
</property>
```

### 4.2 Passing Macros

**CLI:**

```bash
pydm -m '{"PREFIX": "MTEST", "SECTOR": "A"}' my_display.ui
pydm -m 'PREFIX=MTEST,SECTOR=A' my_display.ui
```

**Embedded display** (JSON string property):

```xml
<property name="macros" stdset="0">
 <string>{"PREFIX": "MTEST"}</string>
</property>
```

**Related display button** (same format):

```xml
<property name="macros" stdset="0">
 <string>{"PREFIX": "${PREFIX}", "CHANNEL": "Temperature"}</string>
</property>
```

**Template repeater** (JSON array data source, each element is a macro dict):

```json
[{"PREFIX": "DEV:001"}, {"PREFIX": "DEV:002"}]
```

### 4.3 Cascading

Macros cascade through nested embedded displays. An outer display defines `{"A": "1"}`, an inner embedded display adds `{"B": "2"}` -- the innermost display receives both `A` and `B`. Inner macros override outer macros with the same name.

### 4.4 Python Access

```python
prefix = self.macros().get("PREFIX", "DEFAULT")
```

---

## 5. Widget Reference

### 5.1 Class Hierarchy

```
QWidget / QLabel / etc. (Qt base)
  └── PyDMPrimitiveWidget (mixin)
        ├── rules, opacity, context menu, middle-click tooltip
        │
        ├── PyDMWidget (read-only base)
        │     ├── channel property, alarm handling, value/severity/connection callbacks
        │     ├── tooltip with $(pv_value), $(name), etc.
        │     │
        │     └── PyDMWritableWidget (writable base)
        │           ├── send_value_signal
        │           ├── write access handling
        │           └── DISP field monitoring (monitorDisp)
        │
        └── TextFormatter (mixin)
              ├── precision, precisionFromPV
              ├── showUnits
              └── format string management
```

- **Read-only widgets** (PyDMLabel, PyDMByteIndicator, etc.) inherit `PyDMWidget`.
- **Writable widgets** (PyDMLineEdit, PyDMSpinbox, PyDMSlider, etc.) inherit `PyDMWritableWidget`.
- **Container widgets** (PyDMEmbeddedDisplay, PyDMTemplateRepeater) inherit `PyDMPrimitiveWidget` directly (no channel).
- **Drawing widgets** inherit `PyDMPrimitiveWidget` (optional channel for alarm coloring).

### 5.2 Common Properties

**All PyDM widgets** (`PyDMPrimitiveWidget`):

| Property | Type | Description |
|----------|------|-------------|
| `rules` | `str` | JSON string defining dynamic property rules |
| `opacity` | `float` | Widget opacity (0.0-1.0) |

**Channel-connected widgets** (`PyDMWidget`):

| Property | Type | Description |
|----------|------|-------------|
| `channel` | `str` | Channel address (e.g., `ca://PV:NAME`) |
| `alarmSensitiveContent` | `bool` | Change content color based on alarm severity |
| `alarmSensitiveBorder` | `bool` | Show colored border based on alarm severity |

**Text-displaying widgets** (`TextFormatter` mixin):

| Property | Type | Description |
|----------|------|-------------|
| `precision` | `int` | Number of decimal places |
| `precisionFromPV` | `bool` | Use precision from the PV (default: true) |
| `showUnits` | `bool` | Append engineering units to displayed value |

**Writable widgets** (`PyDMWritableWidget`):

| Property | Type | Description |
|----------|------|-------------|
| `monitorDisp` | `bool` | Monitor the `.DISP` field to disable puts |

**Dynamic tooltip substitutions** (set in the `toolTip` property):

| Token | Value |
|-------|-------|
| `$(name)` | Channel address |
| `$(pv_value)` | Current value |
| `$(pv_value.SEVR)` | Alarm severity string |
| `$(pv_value.EGU)` | Engineering units |
| `$(pv_value.PREC)` | Precision |
| `$(pv_value.TIME)` | Timestamp |

### 5.3 Widget Table

**Display widgets** (read-only):

| Widget | Key Properties | Notes |
|--------|---------------|-------|
| `PyDMLabel` | `channel`, `displayFormat` (Default/String/Decimal/Exponential/Hex/Binary), `enableRichText` | Text display. Rule property: `Text`. |
| `PyDMByteIndicator` | `channel`, `numBits`, `orientation`, `onColor`, `offColor`, `showLabels` | Bit-level indicator |
| `PyDMMultiStateIndicator` | `channel` | Multi-state display |
| `PyDMScaleIndicator` | `channel`, `limitsFromPV`, `userLowerLimit`, `userUpperLimit`, `showValue`, `showLimits`, `showTicks`, `barIndicator`, `orientation` | Analog gauge/scale |
| `PyDMAnalogIndicator` | `channel` | Analog bar indicator |
| `PyDMDateTimeLabel` | `channel` | Displays timestamp value |
| `PyDMImageView` | `imageChannel`, `widthChannel`, `colorMap`, `colorMapMin`, `colorMapMax`, `readingOrder` (Fortranlike/Clike), `normalizeData`, `autoDownsample`, `redrawRate` | 2D image display (camera viewer) |
| `PyDMSymbol` | `channel` | State-dependent image/icon |
| `PyDMNTTable` | `channel` | NTTable display |
| `PyDMLogDisplay` | `channel` | Log message display |

**Input widgets** (writable):

| Widget | Key Properties | Notes |
|--------|---------------|-------|
| `PyDMLineEdit` | `channel`, `displayFormat` | Text input. Sends value on Enter. |
| `PyDMSpinbox` | `channel`, `precision`, `showStepExponent` | Numeric spinner |
| `PyDMSlider` | `channel`, `orientation`, `userMinimum`, `userMaximum`, `showValueLabel`, `showLimitLabels` | Value slider |
| `PyDMCheckbox` | `channel` | Checkbox (writes 0/1) |
| `PyDMEnumComboBox` | `channel` | Dropdown from PV enum strings |
| `PyDMEnumButton` | `channel`, `orientation`, `widgetType` (PushButton/RadioButton), `items` | Button group from PV enum strings |
| `PyDMPushButton` | `channel`, `pressValue`, `releaseValue` | Writes a fixed value on click |
| `PyDMDateTimeEdit` | `channel` | DateTime editor |
| `PyDMWaveformTable` | `channel` | Editable waveform table |

**Navigation/action widgets:**

| Widget | Key Properties | Notes |
|--------|---------------|-------|
| `PyDMRelatedDisplayButton` | `displayFilename`, `macros` (JSON string), `openInNewWindow` | Opens another display |
| `PyDMShellCommand` | `commands`, `titles`, `allowMultipleExecutions` | Runs shell commands |

**Container widgets:**

| Widget | Key Properties | Notes |
|--------|---------------|-------|
| `PyDMEmbeddedDisplay` | `filename`, `macros` (JSON string), `disconnectWhenHidden` | Embed another display inline. Rule property: `Filename`. |
| `PyDMTemplateRepeater` | `templateFilename`, `dataSource` (JSON file path or JSON string), `layoutType` (Vertical/Horizontal/Flow), `layoutSpacing` | Repeat a template with different macros |
| `PyDMTabWidget` | standard QTabWidget properties | Tab container with alarm indicators |
| `PyDMFrame` | standard QFrame properties | Alarm-sensitive frame container |

**Plot widgets** (based on pyqtgraph):

| Widget | Key Properties | Notes |
|--------|---------------|-------|
| `PyDMTimePlot` | `title`, `timeSpan`, `bufferSize`, `updateInterval`, `curves` (stringlist of JSON) | Time-series plot. Curve key: `channel`. |
| `PyDMArchiverTimePlot` | Same as TimePlot + archiver integration | Requires `PYDM_ARCHIVER_URL` env var |
| `PyDMWaveformPlot` | `title`, `curves` (stringlist of JSON) | Waveform plot. Curve keys: `y_channel`, `x_channel`. |
| `PyDMScatterPlot` | `title`, `curves` (stringlist of JSON) | Scatter plot |
| `PyDMEventPlot` | `title`, `curves` (stringlist of JSON) | Event-based plot |

**Drawing widgets** (all in `pydm.widgets.drawing`):

`PyDMDrawingLine`, `PyDMDrawingRectangle`, `PyDMDrawingTriangle`, `PyDMDrawingEllipse`, `PyDMDrawingCircle`, `PyDMDrawingArc`, `PyDMDrawingPie`, `PyDMDrawingChord`, `PyDMDrawingImage`, `PyDMDrawingPolyline`, `PyDMDrawingPolygon`, `PyDMDrawingIrregularPolygon`

Common drawing properties: `penColor`, `penWidth`, `penStyle`, `brush` (fill color). Optional channel for alarm-sensitive coloring.

### 5.4 Callback Methods for Subclassing

When building custom widgets or overriding behavior in `Display` subclasses that create widgets programmatically, these are the key callback methods on `PyDMWidget`:

| Method | Signature | Called When |
|--------|-----------|-------------|
| `value_changed` | `(self, new_val)` | Channel value updates. Sets `self.value`, `self.channeltype`, `self.subtype`. |
| `connection_changed` | `(self, connected: bool)` | Connection state changes. Enables/disables widget. |
| `alarm_severity_changed` | `(self, new_alarm_severity: int)` | Alarm severity changes (0-4). Refreshes stylesheet. |
| `enum_strings_changed` | `(self, new_enum_strings: tuple)` | Enum strings received from PV. |
| `timestamp_changed` | `(self, new_timestamp: float)` | Timestamp update. |
| `ctrl_limit_changed` | `(self, which, new_limit)` | Upper/lower control limit update. |

---

## 6. Rules System

Rules dynamically change widget properties based on PV values. The `rules` property on any PyDM widget is a JSON string containing a list of rule definitions.

### 6.1 JSON Format

```json
[
  {
    "name": "Hide when off",
    "property": "Visible",
    "expression": "ch[0] == 1",
    "channels": [
      {"channel": "ca://PV:Status", "trigger": true, "use_enum": false}
    ],
    "initial_value": "True"
  }
]
```

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name for the rule |
| `property` | string | Target property (must be a key in the widget's `RULE_PROPERTIES`) |
| `expression` | string | Python expression. Result is cast to the property's type. |
| `channels` | array | List of channel objects |
| `initial_value` | string | Optional. Value before any channel data arrives. |

**Channel object:**

| Field | Type | Description |
|-------|------|-------------|
| `channel` | string | Channel address with protocol |
| `trigger` | bool | Whether value changes on this channel trigger re-evaluation |
| `use_enum` | bool | Use enum string value instead of numeric value |

### 6.2 Expression Environment

| Name | Description |
|------|-------------|
| `ch[0]`, `ch[1]`, ... | Values of channels in order |
| `np` | NumPy module |
| `QColor` | `qtpy.QtGui.QColor` |
| `QBrush` | `qtpy.QtGui.QBrush` |
| All `math` functions | `sin`, `cos`, `sqrt`, `pi`, `e`, etc. |

### 6.3 Available Rule Properties

**Base properties** (all PyDM widgets):

| Property Name | Method | Type |
|---|---|---|
| `Enable` | `setEnabled` | `bool` |
| `Visible` | `setVisible` | `bool` |
| `Opacity` | `set_opacity` | `float` |

**Extended by `PyDMWidget`:**

| Property Name | Method | Type |
|---|---|---|
| `Position - X` | `setX` | `int` |
| `Position - Y` | `setY` | `int` |

**Widget-specific additions:**

| Widget | Property | Method | Type |
|--------|----------|--------|------|
| `PyDMLabel` | `Text` | `value_changed` | `str` |
| `PyDMEmbeddedDisplay` | `Filename` | `filename` | `str` |

### 6.4 Examples

**In `.ui` XML:**

```xml
<property name="rules" stdset="0">
 <string>[{"name": "Alarm color", "property": "Opacity", "expression": "0.3 if ch[0] > 100 else 1.0", "channels": [{"channel": "ca://PV:Temp", "trigger": true, "use_enum": false}]}]</string>
</property>
```

**Multi-channel rule:**

```json
[{
  "name": "Enable if both ready",
  "property": "Enable",
  "expression": "ch[0] == 1 and ch[1] == 1",
  "channels": [
    {"channel": "ca://PV:Ready1", "trigger": true, "use_enum": false},
    {"channel": "ca://PV:Ready2", "trigger": true, "use_enum": false}
  ]
}]
```

### 6.5 Adding Custom Rule Properties

When writing a custom widget, define `new_properties` as a class attribute:

```python
class MyWidget(PyDMWidget, QWidget):
    new_properties = {
        "Background Color": ["setStyleSheet", str],
        "Label Text": ["setText", str],
    }
```

The `__init_subclass__` mechanism merges `new_properties` into `RULE_PROPERTIES` automatically.

---

## 7. Alarm Styling and Stylesheets

### 7.1 Alarm Severity Levels

| Level | Name | Default Color | Description |
|-------|------|--------------|-------------|
| 0 | `ALARM_NONE` | `#00EB00` (green) | No alarm |
| 1 | `ALARM_MINOR` | `#EBEB00` (yellow) | Minor alarm |
| 2 | `ALARM_MAJOR` | `#FF0000` (red) | Major alarm |
| 3 | `ALARM_INVALID` | `#EB00EB` (magenta) | Invalid alarm |
| 4 | `ALARM_DISCONNECTED` | `#FFFFFF` (white) | Disconnected (dashed border) |

### 7.2 Alarm-Sensitive Properties

Each widget has two alarm display modes controlled by boolean properties:

- **`alarmSensitiveBorder`** -- draws a colored border around the widget
- **`alarmSensitiveContent`** -- changes the widget's content color or background

The default stylesheet uses Qt property selectors to apply these:

```css
/* Border alarm styling */
*[alarmSensitiveBorder="true"][alarmSeverity="0"] { padding: 2px; }
*[alarmSensitiveBorder="true"][alarmSeverity="1"] { border: 2px solid #EBEB00; }
*[alarmSensitiveBorder="true"][alarmSeverity="2"] { border: 2px solid #FF0000; }
*[alarmSensitiveBorder="true"][alarmSeverity="3"] { border: 2px solid #EB00EB; }
*[alarmSensitiveBorder="true"][alarmSeverity="4"] { border: 2px dashed #FFFFFF; }

/* Content alarm styling (varies by widget type) */
PyDMLabel[alarmSensitiveContent="true"][alarmSeverity="1"] { color: #EBEB00; }
PyDMPushButton[alarmSensitiveContent="true"][alarmSeverity="2"] { background-color: #FF0000; }
```

Content styling differs per widget type:
- **Text widgets** (PyDMLabel, PyDMLineEdit): change `color` (text color)
- **Button/input widgets** (PyDMCheckbox, PyDMSpinbox, PyDMEnumComboBox, PyDMPushButton): change `background-color`
- **Drawing widgets**: change `qproperty-brush` and `qproperty-penColor`
- **Frame**: change `background-color` with `rgba` and `border-radius`

### 7.3 Custom Stylesheets

**Loading priority:**

1. `PYDM_STYLESHEET` environment variable -- colon-separated list of `.qss` file paths
2. If `PYDM_STYLESHEET_INCLUDE_DEFAULT` is set, the default stylesheet is prepended
3. If no custom stylesheet is set, the default stylesheet is used

**CLI override:**

```bash
pydm --stylesheet /path/to/custom.qss my_display.ui
```

**Per-display stylesheet:** Set a display's `styleSheet` property to a `.qss` file path (absolute or relative to the display file) or inline CSS.

**Writing custom QSS:** Use Qt property selectors to target alarm states:

```css
PyDMLabel[alarmSensitiveContent="true"][alarmSeverity="2"] {
    color: #FF0000;
    font-weight: bold;
}
```

---

## 8. Extending PyDM

### 8.1 Custom Widgets

Create a widget by subclassing the appropriate base class:

**Read-only widget:**

```python
from qtpy.QtWidgets import QLabel
from pydm.widgets.base import PyDMWidget, TextFormatter

class MyReadback(QLabel, TextFormatter, PyDMWidget):
    def __init__(self, parent=None, init_channel=None):
        QLabel.__init__(self, parent)
        PyDMWidget.__init__(self, init_channel=init_channel)

    def value_changed(self, new_val):
        super().value_changed(new_val)
        self.setText(self.format_string.format(new_val))
```

**Writable widget:**

```python
from qtpy.QtWidgets import QLineEdit
from pydm.widgets.base import PyDMWritableWidget, TextFormatter

class MyInput(QLineEdit, TextFormatter, PyDMWritableWidget):
    def __init__(self, parent=None, init_channel=None):
        QLineEdit.__init__(self, parent)
        PyDMWritableWidget.__init__(self, init_channel=init_channel)
        self.returnPressed.connect(self.send_value)

    def send_value(self):
        self.send_value_signal[float].emit(float(self.text()))

    def value_changed(self, new_val):
        super().value_changed(new_val)
        self.setText(self.format_string.format(new_val))
```

**Qt Designer registration:**

For entrypoint-based registration, optionally add `_qt_designer_` metadata:

```python
class MyWidget(PyDMWidget, QLabel):
    _qt_designer_ = {
        "is_container": False,
        "group": "My Custom Widgets",
        "extensions": None,
        "icon": None,
    }
```

Register via `pyproject.toml`:

```toml
[project.entry-points."pydm.widget"]
MyWidget = "my_package.widgets:MyWidget"
```

For file-based discovery, place widget files in a directory listed in `PYDM_DATA_PLUGINS_PATH`.

### 8.2 Custom Data Plugins

Subclass `PyDMPlugin` and `PyDMConnection`:

```python
from pydm.data_plugins.plugin import PyDMPlugin, PyDMConnection

class MyConnection(PyDMConnection):
    def __init__(self, channel, address, protocol=None, parent=None):
        super().__init__(channel, address, protocol, parent)
        self.add_listener(channel)
        # Start monitoring the data source
        # Emit signals when data arrives:
        #   self.new_value_signal[float].emit(value)
        #   self.connection_state_signal.emit(True)
        #   self.new_severity_signal.emit(severity)
        #   self.write_access_signal.emit(True)

    def put_value(self, new_val):
        # Handle writes from widgets
        pass

    def close(self):
        # Clean up connections
        pass

class MyPlugin(PyDMPlugin):
    protocol = "myproto"
    connection_class = MyConnection
```

**Available signals on `PyDMConnection`:**

| Signal | Argument Types |
|--------|---------------|
| `new_value_signal` | `float`, `int`, `str`, `bool`, `object` |
| `connection_state_signal` | `bool` |
| `new_severity_signal` | `int` |
| `write_access_signal` | `bool` |
| `enum_strings_signal` | `tuple` |
| `unit_signal` | `str` |
| `prec_signal` | `int` |
| `upper_ctrl_limit_signal` | `float`, `int` |
| `lower_ctrl_limit_signal` | `float`, `int` |
| `upper_alarm_limit_signal` | `float`, `int` |
| `lower_alarm_limit_signal` | `float`, `int` |
| `upper_warning_limit_signal` | `float`, `int` |
| `lower_warning_limit_signal` | `float`, `int` |
| `timestamp_signal` | `float` |

Register via `pyproject.toml`:

```toml
[project.entry-points."pydm.data_plugin"]
myproto = "my_package.plugins:MyPlugin"
```

Or place `*_plugin.py` files in a directory listed in `PYDM_DATA_PLUGINS_PATH`.

### 8.3 External Tools

External tools appear in the widget context menu and/or the main menu bar.

```python
from pydm.tools import ExternalTool
from qtpy.QtGui import QIcon

class MyTool(ExternalTool):
    def __init__(self):
        super().__init__(
            icon=QIcon(),
            name="My Tool",
            group="Diagnostics",
            use_with_widgets=True,
            use_without_widget=False,
        )

    def call(self, channels, sender):
        # channels: list of PyDMChannel objects from the widget
        # sender: the widget that triggered the tool
        for ch in channels:
            print(f"Channel: {ch.address}")

    def is_compatible_with(self, widget):
        # Return False to hide this tool for certain widget types
        return True
```

Discover via `pydm.tool` entrypoint or place `*_tool.py` files in `PYDM_TOOLS_PATH`.

---

## 9. Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| **`QT_API`** | **Yes** | Qt binding: `pyqt5` or `pyside6` |
| **`PYDM_DEFAULT_PROTOCOL`** | No | Default channel protocol (e.g., `ca`). Allows omitting prefix in addresses. |
| **`PYDM_STYLESHEET`** | No | Colon-separated paths to custom `.qss` stylesheet files |
| `PYDM_STYLESHEET_INCLUDE_DEFAULT` | No | If set, prepend default stylesheet to custom |
| **`PYDM_DATA_PLUGINS_PATH`** | No | Colon-separated paths to scan for `*_plugin.py` data plugin files |
| **`PYDM_DISPLAYS_PATH`** | No | Display file search paths |
| `PYDM_TOOLS_PATH` | No | Colon-separated paths to scan for `*_tool.py` external tool files |
| `PYDM_EPICS_LIB` | No | EPICS CA backend: `PYEPICS` (default), `PYCA`, `CAPROTO` |
| `PYDM_PVA_LIB` | No | PVA backend: `P4P` (default) |
| `PYDM_ARCHIVER_URL` | No | EPICS Archiver Appliance base URL |
| `PYDM_DESIGNER_ONLINE` | No | Enable live data connections in Qt Designer |
| `PYDM_CONFIRM_QUIT` | No | Prompt before quitting (`y`, `t`, `1`, `true`) |
| `PYDM_HOME_FILE` | No | Default home display file for the home button |
| `PYDM_STRING_ENCODING` | No | String encoding (default: `utf_8`) |
| `PYQTDESIGNERPATH` | No | Path to pydm package directory (PyQt5 Designer plugin registration) |
| `PYSIDE_DESIGNER_PLUGINS` | No | Path to pydm package directory (PySide6 Designer plugin registration) |

---

## 10. CLI Reference

```
pydm [options] [displayfile] [-- display_args...]
```

| Option | Description |
|--------|-------------|
| `displayfile` | `.ui`, `.py`, or `.adl` file to display |
| `-m`, `--macro` | Macro substitutions: JSON (`'{"K":"V"}'`) or `K=V,K2=V2` |
| `--homefile PATH` | Home button display file |
| `--stylesheet PATH` | Custom `.qss` stylesheet path |
| `-r`, `--recurse` | Recursively search for displayfile |
| `--read-only` | Disable all writes |
| `--fullscreen` | Start in fullscreen |
| `--hide-nav-bar` | Hide navigation bar |
| `--hide-menu-bar` | Hide menu bar |
| `--hide-status-bar` | Hide status bar |
| `--log_level LEVEL` | `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL` |
| `--perfmon` | Print CPU usage to terminal |
| `--profile` | Enable cProfile profiling |
| `--faulthandler` | Enable faulthandler for segfaults |
| `--version` | Print version and exit |
| `display_args...` | Arguments passed to the display (after `--`) |
