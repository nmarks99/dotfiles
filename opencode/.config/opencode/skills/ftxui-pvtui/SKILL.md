---
name: ftxui-pvtui
description: Write EPICS-aware C++ terminal UI applications with FTXUI and PVTUI -- element/component systems, PV monitoring, EPICS-aware widgets, event loops, and application scaffolding
---

# FTXUI + PVTUI Skill

You are an expert at building C++ terminal user interfaces with **FTXUI** (v6.1.9) and **PVTUI** (v0.3.0). FTXUI is a C++17 library providing a DOM-like element system for layout and a component system for interactivity. PVTUI is a library built on top of FTXUI that bridges it with EPICS, providing PV-connected widgets, a PV management layer, and application scaffolding. You write standalone TUI applications and EPICS-aware TUI applications.

---

## 1. Architecture Overview

FTXUI has three libraries with a strict dependency chain:

```
ftxui::screen  <--  ftxui::dom  <--  ftxui::component
```

- **`ftxui::screen`** — Terminal cells, colors, Screen rendering surface.
- **`ftxui::dom`** — Element tree: `text`, `hbox`, `vbox`, `border`, `gauge`, `Canvas`, `Table`, decorators.
- **`ftxui::component`** — Interactive components: `Button`, `Input`, `Menu`, `Slider`, event handling, `ScreenInteractive`/`App`, `Loop`.

PVTUI adds a layer on top:

```
ftxui::component  <--  pvtui (static library)
```

PVTUI has three sub-layers:

- **PV Layer** (`pvgroup.hpp`) — `PVHandler` wraps a `pvac::ClientChannel` with monitor callbacks. `PVGroup` manages a collection of PVHandlers. Thread-safe sync copies data to user variables on the main thread.
- **Widget Layer** (`widgets.hpp`) — `Monitor<T>`, `InputWidget`, `ButtonWidget`, `ChoiceWidget`, `BitsWidget`. Each auto-registers its PV and provides an `ftxui::Component`.
- **App Layer** (`app.hpp`) — `App` struct bundles `ArgParser`, `pvac::ClientProvider`, `PVGroup`, and `ftxui::ScreenInteractive`. Owns the main loop.

**Data flow (PVTUI):**

```
EPICS IOC  →  pvac monitor callback (EPICS thread)
           →  PVHandler mutex-protected MonitorSlot
           →  PVGroup::sync() on main thread copies to user variables
           →  Post Event::Custom to trigger FTXUI re-render
           →  Renderer reads user variables → terminal output
```

---

## 2. Build System

### 2.1 Standalone FTXUI Application

```cmake
cmake_minimum_required(VERSION 3.14)
project(myapp LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)

include(FetchContent)
FetchContent_Declare(ftxui
    GIT_REPOSITORY https://github.com/ArthurSonzogni/ftxui
    GIT_TAG v6.1.9
)
FetchContent_MakeAvailable(ftxui)

add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE ftxui::component)
```

Linking `ftxui::component` transitively includes `ftxui::dom` and `ftxui::screen`. For non-interactive output-only programs, link `ftxui::dom` instead.

### 2.2 PVTUI Application (against installed pvtui)

```cmake
cmake_minimum_required(VERSION 3.22)
project(myapp LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)

find_package(pvtui REQUIRED)

add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE pvtui::pvtui)
```

Linking `pvtui::pvtui` transitively includes all three FTXUI targets plus EPICS libraries (`pvAccessCA`, `ca`, `pvAccess`, `pvData`, `Com`).

### 2.3 PVTUI Application (in-tree, as part of pvtui build)

```cmake
add_executable(myapp myapp.cpp)
target_link_libraries(myapp PRIVATE pvtui)
```

---

## 3. FTXUI Element System (DOM)

### 3.1 Core Types

```cpp
using Element   = std::shared_ptr<Node>;
using Elements  = std::vector<Element>;
using Decorator = std::function<Element(Element)>;
```

Include: `<ftxui/dom/elements.hpp>`

### 3.2 Pipe Operator

Decorators chain with `|`:

```cpp
text("hello") | bold | border | color(Color::Red)
// equivalent to: color(Color::Red, border(bold(text("hello"))))
```

Also works on Elements vectors and composes Decorators with each other.

### 3.3 Text and Content

| Function | Description |
|----------|-------------|
| `text(string_view)` | Single-line text |
| `vtext(string_view)` | Vertical text (one char per line) |
| `paragraph(string_view)` | Word-wrapping paragraph |
| `paragraphAlignLeft/Right/Center/Justify(string_view)` | Aligned paragraphs |
| `emptyElement()` | Empty element |

### 3.4 Layout

| Function | Description |
|----------|-------------|
| `hbox(Elements)` | Horizontal left-to-right |
| `vbox(Elements)` | Vertical top-to-bottom |
| `dbox(Elements)` | Stacked/overlay (last on top) |
| `flexbox(Elements, FlexboxConfig)` | CSS-like flexbox |
| `gridbox(vector<Elements>)` | 2D grid, aligned rows/columns |
| `hflow(Elements)` | Flexbox shorthand: row + wrap |
| `vflow(Elements)` | Flexbox shorthand: column + wrap |

`hbox`, `vbox`, `dbox`, `hflow` accept variadic arguments: `hbox({a, b, c})` or `hbox(a, b, c)`.

### 3.5 Flexibility and Sizing

| Function | Description |
|----------|-------------|
| `flex(Element)` | Expand and shrink |
| `flex_grow(Element)` | Can expand, won't shrink |
| `flex_shrink(Element)` | Can shrink, won't expand |
| `xflex(Element)` / `yflex(Element)` | Single-axis variants |
| `filler()` | Blank expandable spacer |
| `notflex(Element)` | Reset flex properties |

Size constraints:

```cpp
enum WidthOrHeight { WIDTH, HEIGHT };
enum Constraint { LESS_THAN, EQUAL, GREATER_THAN };
element | size(WIDTH, EQUAL, 30) | size(HEIGHT, LESS_THAN, 10)
```

### 3.6 Borders and Separators

**Borders:**

| Function | Description |
|----------|-------------|
| `border(Element)` | Default (light) border |
| `borderLight/Dashed/Heavy/Double/Rounded/Empty(Element)` | Specific styles |
| `borderStyled(BorderStyle)` | Decorator form |
| `borderStyled(BorderStyle, Color)` | Styled + colored |
| `borderStyled(Color)` | Colored (default style) |
| `window(Element title, Element content, BorderStyle)` | Titled bordered window |

`BorderStyle` enum: `LIGHT`, `DASHED`, `HEAVY`, `DOUBLE`, `ROUNDED`, `EMPTY`.

**Separators:**

| Function | Description |
|----------|-------------|
| `separator()` | Default light separator |
| `separatorLight/Dashed/Heavy/Double/Empty()` | Specific styles |
| `separatorStyled(BorderStyle)` | Styled separator |
| `separatorCharacter(string_view)` | Custom character |
| `separatorHSelector(l, r, unsel, sel)` | Horizontal scroll selector |
| `separatorVSelector(u, d, unsel, sel)` | Vertical scroll selector |

### 3.7 Style Decorators

| Decorator | Description |
|-----------|-------------|
| `bold` | Bold text |
| `dim` | Dim/faint text |
| `italic` | Italic text |
| `underlined` | Single underline |
| `underlinedDouble` | Double underline |
| `strikethrough` | Strikethrough |
| `blink` | Blinking text |
| `inverted` | Swap foreground/background |
| `color(Color)` | Foreground color |
| `bgcolor(Color)` | Background color |
| `color(LinearGradient)` | Gradient foreground |
| `bgcolor(LinearGradient)` | Gradient background |
| `hyperlink(string_view)` | Clickable hyperlink |

### 3.8 Utility Decorators

| Decorator | Description |
|-----------|-------------|
| `hcenter` / `vcenter` / `center` | Centering |
| `align_right` | Right alignment |
| `nothing` | Identity passthrough |
| `reflect(Box&)` | Capture rendered bounding box (for mouse hit-testing) |
| `clear_under` | Clear pixels beneath (useful with `dbox`) |
| `automerge` | Auto-merge adjacent box-drawing characters |
| `focusPosition(int x, int y)` | Override focus position |
| `focusPositionRelative(float x, float y)` | Relative focus (0.0-1.0) |

### 3.9 Scrolling Frames

| Function | Description |
|----------|-------------|
| `frame(Element)` | Scrollable (both axes), scrolls to focused element |
| `xframe` / `yframe` | Single-axis scroll |
| `focus(Element)` | Mark as focused/visible in a frame |
| `vscroll_indicator(Element)` | Vertical scroll indicator |
| `hscroll_indicator(Element)` | Horizontal scroll indicator |

### 3.10 Gauges, Spinners, Graphs

```cpp
gauge(0.5f)                       // horizontal progress bar
gaugeLeft/Right/Up/Down(float)    // directional gauges
gaugeDirection(float, Direction)  // Direction::Up/Down/Left/Right

spinner(int charset_index, size_t frame_index)  // 22 styles (0-21)

graph(GraphFunction)  // GraphFunction = function<vector<int>(int w, int h)>
```

### 3.11 Canvas

Sub-cell-resolution drawing. Terminal cell = 2x4 canvas coordinates for braille mode.

```cpp
auto c = Canvas(100, 100);
c.DrawPointLine(10, 10, 80, 40, Color::Red);
c.DrawPointCircle(50, 50, 20);
c.DrawText(10, 10, "Hello");   // x must be multiple of 2, y multiple of 4
auto element = canvas(c) | border;

// Or with lambda:
auto element = canvas(100, 100, [](Canvas& c) {
    c.DrawPointCircleFilled(50, 50, 20, Color::Blue);
});
```

**Drawing families** (each has Color and Stylizer overloads):
- **Braille** (1x1): `DrawPoint*`, `DrawPointLine`, `DrawPointCircle[Filled]`, `DrawPointEllipse[Filled]`
- **Block** (2x2): `DrawBlock*`, `DrawBlockLine`, `DrawBlockCircle[Filled]`, `DrawBlockEllipse[Filled]`
- **Text**: `DrawText(x, y, string)` — x multiple of 2, y multiple of 4
- **Cell/Surface**: `DrawCell(x, y, Cell)`, `DrawSurface(x, y, Surface)`

### 3.12 Table

```cpp
auto table = Table({
    {"Name", "Value"},
    {"x", "1.0"},
    {"y", "2.0"},
});
table.SelectAll().Border(LIGHT);
table.SelectRow(0).Decorate(bold);
table.SelectColumn(1).DecorateCells(align_right);
auto element = table.Render();
```

Selection API: `SelectAll()`, `SelectRow(i)`, `SelectColumn(i)`, `SelectCell(row, col)`, `SelectRectangle(row_min, col_min, row_max, col_max)`, `SelectRows(from, to)`, `SelectColumns(from, to)`. Methods on `TableSelection`: `Border()`, `Separator()`, `Decorate()`, `DecorateCells()`, `DecorateCellsAlternateRow/Column()`.

### 3.13 FlexboxConfig

Replicates CSS flexbox:

```cpp
FlexboxConfig config;
config.Set(FlexboxConfig::Direction::Row)
      .Set(FlexboxConfig::Wrap::Wrap)
      .Set(FlexboxConfig::JustifyContent::SpaceEvenly)
      .Set(FlexboxConfig::AlignItems::Center)
      .SetGap(1, 1);
auto element = flexbox(children, config);
```

Enums: `Direction` (Row, RowInversed, Column, ColumnInversed), `Wrap` (NoWrap, Wrap, WrapInversed), `JustifyContent` (FlexStart, FlexEnd, Center, Stretch, SpaceBetween, SpaceAround, SpaceEvenly), `AlignItems/AlignContent` (FlexStart, FlexEnd, Center, Stretch).

### 3.14 LinearGradient

```cpp
auto grad = LinearGradient().Angle(45).Stop(Color::Red).Stop(Color::Blue);
element | bgcolor(grad);

// Shorthand:
element | bgcolor(LinearGradient(Color::Red, Color::Blue));
element | bgcolor(LinearGradient(45, Color::Red, Color::Blue));
```

### 3.15 Dimension Namespace

Used with `Screen::Create`:

```cpp
Dimension::Fixed(int)    // Fixed size
Dimension::Full()        // Fill terminal
Dimension::Fit(element)  // Fit to element's requirements
```

---

## 4. FTXUI Component System

Include: `<ftxui/component/component.hpp>`

### 4.1 Core Types

```cpp
using Component          = std::shared_ptr<ComponentBase>;
using Components         = std::vector<Component>;
using ComponentDecorator  = std::function<Component(Component)>;
using ElementDecorator    = std::function<Element(Element)>;
```

Pipe operator works on components too:

```cpp
component | Renderer([](Element inner) { return inner | border; })
component | CatchEvent([](Event e) { return false; })
component | Maybe(&show_flag)
```

### 4.2 ComponentBase Virtual Interface

```cpp
class ComponentBase {
    virtual Element OnRender();
    virtual bool OnEvent(Event);
    virtual void OnAnimation(animation::Params&);
    virtual Component ActiveChild();
    virtual bool Focusable() const;
    virtual void SetActiveChild(ComponentBase*);
};
```

Key non-virtual: `Render()`, `Parent()`, `ChildAt(i)`, `ChildCount()`, `Add(Component)`, `Detach()`, `Active()`, `Focused()`, `TakeFocus()`, `CaptureMouse(event)`.

### 4.3 Custom Components

Subclass `ComponentBase` and instantiate with `ftxui::Make<T>(args...)`:

```cpp
class MyDisplay : public ftxui::ComponentBase {
  public:
    MyDisplay(const std::string& title) : title_(title) {
        auto container = Container::Vertical({/* child components */});
        container |= Renderer([this](Element) { return this->render(); });
        Add(container);
    }
  private:
    std::string title_;
    Element render() {
        return vbox({ text(title_) | bold | border });
    }
};

auto display = ftxui::Make<MyDisplay>("Hello");
```

### 4.4 Container Layouts

```cpp
Container::Vertical(Components children, int* selector = nullptr);
Container::Horizontal(Components children, int* selector = nullptr);
Container::Tab(Components children, int* selector);
Container::Stacked(Components children);
```

- **Vertical/Horizontal**: Arrow keys navigate between children.
- **Tab**: Only one child rendered at a time, controlled by `*selector`. No keyboard nav between tabs — use an external Menu to control `selector`.
- **Stacked**: All children overlaid. Used with `Window` components.

### 4.5 Built-in Components

**Button:**

```cpp
Button(ConstStringRef label, function<void()> on_click, ButtonOption = ButtonOption::Simple());
Button(ButtonOption options);
```

Presets: `ButtonOption::Ascii()`, `Simple()`, `Border()`, `Animated()`, `Animated(Color)`, `Animated(bg, fg)`, `Animated(bg, fg, bg_active, fg_active)`.

**Input:**

```cpp
Input(InputOption options = {});
Input(StringRef content, InputOption options = {});
Input(StringRef content, StringRef placeholder, InputOption options = {});
```

`InputOption` fields: `content`, `placeholder`, `password`, `multiline`, `insert`, `on_change`, `on_enter`, `cursor_position`. Presets: `InputOption::Default()`, `Spacious()`.

**Menu:**

```cpp
Menu(ConstStringListRef entries, int* selected, MenuOption = MenuOption::Vertical());
Menu(MenuOption options);
MenuEntry(ConstStringRef label, MenuEntryOption = {});
```

Presets: `MenuOption::Horizontal()`, `HorizontalAnimated()`, `Vertical()`, `VerticalAnimated()`, `Toggle()`.

**Checkbox / Radiobox:**

```cpp
Checkbox(ConstStringRef label, bool* checked, CheckboxOption = CheckboxOption::Simple());
Radiobox(ConstStringListRef entries, int* selected, RadioboxOption = {});
```

**Slider:**

```cpp
Slider(SliderOption<T> options);  // T = int, float, long
Slider(ConstStringRef label, Ref<int> value, ConstRef<int> min, max, increment);
```

`SliderOption<T>`: `value`, `min`, `max`, `increment`, `direction`, `color_active`, `color_inactive`, `on_change`.

**Dropdown:**

```cpp
Dropdown(ConstStringListRef entries, int* selected);
Dropdown(DropdownOption options);
```

**ResizableSplit:**

```cpp
ResizableSplitLeft(Component main, Component back, int* main_size);
ResizableSplitRight/Top/Bottom(Component main, Component back, int* main_size);
ResizableSplit(ResizableSplitOption options);
```

**Window (floating, draggable, resizable):**

```cpp
Window(WindowOptions{
    .inner = component, .title = "Title",
    .left = &x, .top = &y, .width = &w, .height = &h,
});
```

Used with `Container::Stacked`.

### 4.6 Higher-Order Components

**Renderer** — override rendering:

```cpp
Renderer(function<Element()>);                   // non-focusable
Renderer(function<Element(bool focused)>);       // focusable
Renderer(Component child, function<Element()>);  // wrap child
```

Also usable as a decorator via `|=` or `|`:

```cpp
container |= Renderer([&](Element inner) {
    return vbox({ text("Title"), inner }) | border;
});
```

When using `Renderer` as a decorator, the lambda receives the inner component's rendered `Element` as its argument. This is how you override the visual layout while preserving the container's interactivity.

**CatchEvent** — intercept events:

```cpp
CatchEvent(Component child, function<bool(Event)>);
ComponentDecorator CatchEvent(function<bool(Event)>);
```

Return `true` to consume the event (stops propagation).

**Maybe** — conditional visibility:

```cpp
Maybe(Component, const bool* show);
Maybe(Component, function<bool()>);
ComponentDecorator Maybe(const bool* show);
ComponentDecorator Maybe(function<bool()>);
```

**Modal** — overlay:

```cpp
Modal(Component main, Component modal, const bool* show_modal);
```

**Collapsible:**

```cpp
Collapsible(ConstStringRef label, Component child, Ref<bool> show = false);
```

**Hoverable:**

```cpp
Hoverable(Component, bool* hover);
Hoverable(Component, function<void(bool)> on_change);
```

---

## 5. FTXUI Screen, App, and Event Loop

Include: `<ftxui/component/screen_interactive.hpp>` (or `<ftxui/component/app.hpp>`)

Note: `ScreenInteractive` is an alias for `App` in FTXUI v6.

### 5.1 Static Rendering (no event loop)

```cpp
auto document = vbox({ text("hello") | bold | border });
auto screen = Screen::Create(Dimension::Fit(document));
Render(screen, document);
screen.Print();
```

### 5.2 Interactive App

Factory methods:

| Factory | Description |
|---------|-------------|
| `ScreenInteractive::Fullscreen()` | Alternate screen buffer, full terminal |
| `ScreenInteractive::FullscreenPrimaryScreen()` | Primary screen, full terminal |
| `ScreenInteractive::FullscreenAlternateScreen()` | Same as `Fullscreen()` |
| `ScreenInteractive::FitComponent()` | Size fits component |
| `ScreenInteractive::TerminalOutput()` | Appends to terminal output |
| `ScreenInteractive::FixedSize(w, h)` | Fixed dimensions |

Simple blocking loop:

```cpp
auto screen = ScreenInteractive::Fullscreen();
screen.Loop(component);
```

### 5.3 Custom Loop

```cpp
auto screen = ScreenInteractive::Fullscreen();
Loop loop(&screen, component);
while (!loop.HasQuitted()) {
    loop.RunOnce();   // non-blocking
    std::this_thread::sleep_for(std::chrono::milliseconds(16));
}
```

`Loop` methods: `Run()` (blocking), `RunOnce()` (non-blocking), `RunOnceBlocking()`, `HasQuitted()`.

### 5.4 Key App/ScreenInteractive Methods

| Method | Description |
|--------|-------------|
| `Loop(Component)` | Blocking main loop |
| `Exit()` | Signal quit |
| `ExitLoopClosure()` | Returns a closure that calls Exit() |
| `Post(Task)` | Thread-safe: post a task to the event loop |
| `PostEvent(Event)` | Thread-safe: inject an event |
| `RequestAnimationFrame()` | Request redraw on next animation tick |
| `TrackMouse(bool)` | Enable/disable mouse tracking (default: true) |
| `ForceHandleCtrlC(bool)` | Control Ctrl-C handling |
| `ForceHandleCtrlZ(bool)` | Control Ctrl-Z handling |
| `WithRestoredIO(Closure)` | Temporarily restore normal terminal I/O |
| `GetSelection()` | Get currently selected text |
| `Active()` | Static: returns currently active App |

---

## 6. FTXUI Events and Input

Include: `<ftxui/component/event.hpp>`, `<ftxui/component/mouse.hpp>`

### 6.1 Event Class

**Predefined constants:**

| Category | Events |
|----------|--------|
| Arrows | `Event::ArrowLeft/Right/Up/Down`, `Event::ArrowLeftCtrl/RightCtrl/UpCtrl/DownCtrl` |
| Navigation | `Event::Backspace`, `Delete`, `Return`, `Escape`, `Tab`, `TabReverse`, `Insert`, `Home`, `End`, `PageUp`, `PageDown` |
| Function keys | `Event::F1` through `Event::F12` |
| Letters | `Event::a`–`Event::z`, `Event::A`–`Event::Z`, `Event::CtrlA`–`Event::CtrlZ`, `Event::AltA`–`Event::AltZ`, `Event::CtrlAltA`–`Event::CtrlAltZ` |
| Special | `Event::Custom` (synthetic, triggers re-render) |

**Factory methods:**

```cpp
Event::Character('a')
Event::Character("string")
Event::Special({27, 91, 65})  // raw escape sequence
Event::Mouse(input, mouse)
```

**Query methods:** `is_character()`, `character()`, `is_mouse()`, `mouse()`, `input()`, `DebugString()`.

**Comparison:** `event == Event::ArrowLeft`, `event == Event::Character('q')`.

### 6.2 Mouse

```cpp
struct Mouse {
    Button button;   // Left, Middle, Right, None, WheelUp/Down/Left/Right
    Motion motion;   // Released, Pressed, Moved
    bool shift, meta, control;
    int x, y;
};
```

### 6.3 Event Flow

Events propagate from root to focused child via `OnEvent(Event)`. Return `true` to consume. `CatchEvent` intercepts before the wrapped component.

---

## 7. FTXUI Color System

Include: `<ftxui/screen/color.hpp>`

### 7.1 Color Modes

| Mode | Usage |
|------|-------|
| Default | `Color()` or `Color::Default` |
| Palette16 | `Color::Black`, `Red`, `Green`, `Yellow`, `Blue`, `Magenta`, `Cyan`, `GrayLight`, `GrayDark`, `RedLight`, `GreenLight`, `YellowLight`, `BlueLight`, `MagentaLight`, `CyanLight`, `White` |
| Palette256 | `Color::Aquamarine1`, `Color::DeepPink1`, `Color::Grey50`, etc. (240 named colors) |
| TrueColor | `Color::RGB(r, g, b)`, `Color::HSV(h, s, v)`, `Color::RGBA(r, g, b, a)`, `Color::HSVA(h, s, v, a)` |

**Literal:** `0xFF8000_rgb`

**Interpolation:** `Color::Interpolate(float t, Color a, Color b)`, `Color::Blend(Color lhs, Color rhs)`.

**Terminal detection:** `Terminal::ColorSupport()` returns `Palette1/Palette16/Palette256/TrueColor`. Override with `Terminal::SetColorSupport()`.

---

## 8. FTXUI Animation

Include: `<ftxui/component/animation.hpp>`

Request animation frames to trigger `OnAnimation()` callbacks:

```cpp
animation::RequestAnimationFrame();
```

Components override `OnAnimation(animation::Params& params)` where `params.duration()` gives elapsed time.

**Easing functions** (in `ftxui::animation::easing`, signature `float(float)`):

`Linear`, `QuadraticIn/Out/InOut`, `CubicIn/Out/InOut`, `QuarticIn/Out/InOut`, `QuinticIn/Out/InOut`, `SineIn/Out/InOut`, `CircularIn/Out/InOut`, `ExponentialIn/Out/InOut`, `ElasticIn/Out/InOut`, `BackIn/Out/InOut`, `BounceIn/Out/InOut`.

Used in `ButtonOption::Animated()`, `MenuOption::HorizontalAnimated()`, etc.

---

## 9. PVTUI PV Layer (PVGroup)

Include: `<pvtui/pvgroup.hpp>`

### 9.1 MonitorVar

```cpp
using MonitorVar = std::variant<std::monostate, std::string, int, double,
                                std::vector<std::string>, std::vector<int>,
                                std::vector<double>, PVEnum>;
```

### 9.2 PVEnum

```cpp
struct PVEnum {
    int index = 0;
    std::vector<std::string> choices;
    std::string choice = "";
};
```

Represents EPICS enumeration PVs (mbbi/mbbo, etc.).

### 9.3 ConnectionMonitor

Derives from `pvac::ClientChannel::ConnectCallback`. Tracks connection state via atomic bool.

| Method | Description |
|--------|-------------|
| `connected() const` | Returns connection state |

### 9.4 PVHandler

Manages a single EPICS PV: connection, monitoring, value distribution.

| Member/Method | Description |
|---------------|-------------|
| `channel` | `pvac::ClientChannel` — the underlying channel |
| `name` | PV name string |
| `PVHandler(provider, pv_name)` | Constructor: connects and starts monitoring |
| `connected() const` | Delegates to ConnectionMonitor |
| `sync()` | Copies latest data to registered user variables. Returns true if new data was available |
| `set_monitor<T>(T& var)` | Registers a user variable to receive updates of type T |
| `force_update()` | Synchronous `channel.get()`, queues result for next `sync()` |
| `get_monitor()` | Returns underlying `pvac::Monitor&` |
| `get_connection_monitor()` | Returns `shared_ptr<ConnectionMonitor>` |

### 9.5 PVGroup

Manages a collection of PVHandlers.

| Method | Description |
|--------|-------------|
| `PVGroup(provider, pv_list)` | Construct with initial PV names |
| `PVGroup(provider)` | Construct empty |
| `add(pv_name)` | Add a PV (no-op if exists) |
| `set_monitor<T>(pv_name, var)` | Register a monitor. **Throws** if PV not found |
| `get_pv(pv_name)` | Returns `PVHandler&`. **Throws** if not found |
| `get_pv_shared(pv_name)` | Returns `shared_ptr<PVHandler>`. **Throws** if not found |
| `operator[](pv_name)` | Returns `PVHandler&`. **Auto-creates** if not found |
| `force_update()` | Calls `force_update()` on every PV |
| `sync()` | Calls `sync()` on every PV. Returns true if any had new data |

**CRITICAL:** `get_pv()` and `set_monitor()` throw if the PV is not registered. `operator[]` auto-creates. Know the difference.

### 9.6 Using PVGroup Directly (without widgets)

For cases where you need raw PV data without a widget:

```cpp
double beam_current = 0.0;
app.pvgroup.add("S:SRcurrentAI");
app.pvgroup.set_monitor("S:SRcurrentAI", beam_current);

// In renderer, beam_current is updated automatically by sync()
auto renderer = Renderer([&] {
    return text("Current: " + std::to_string(beam_current));
});
```

---

## 10. PVTUI Widget System

Include: `<pvtui/widgets.hpp>`

All widgets inherit from `WidgetBase`. Every constructor auto-registers its PV with the `PVGroup`.

### 10.1 WidgetBase

| Method | Description |
|--------|-------------|
| `pv_name() const` | Returns PV name |
| `component() const` | Returns `ftxui::Component`. **Throws** if not set |
| `connected() const` | Returns PV connection status |
| `value_as_string() const` | Current value as string (virtual) |

### 10.2 Monitor\<T\>

Read-only display of a PV value as `ftxui::text()`.

```cpp
Monitor<std::string> rbv(app, prefix + "m1.RBV");
Monitor<int>         dmov(app, prefix + "m1.DMOV");
Monitor<double>      val(app, prefix + "m1.VAL");
Monitor<PVEnum>      status(app, prefix + "m1.STAT");
```

Template parameter `T`: `std::string`, `int`, `double`, `PVEnum`, `std::vector<double>`, `std::vector<int>`, `std::vector<std::string>`.

| Method | Description |
|--------|-------------|
| `value() const` | Returns `const T&` of current value |
| `value_as_string() const` | String conversion: strings pass through, arithmetic → `std::to_string`, PVEnum → `choice` |

Constructors: `Monitor(PVGroup&, pv_name)` or `Monitor(App&, pv_name)`.

### 10.3 InputWidget

Editable text input bound to a PV. On Enter, writes the value converted per `PVPutType`.

```cpp
InputWidget val(app, prefix + "m1.VAL", PVPutType::Double);
InputWidget desc(app, prefix + "m1.DESC", PVPutType::String);
InputWidget count(app, prefix + "counter", PVPutType::Integer);
```

```cpp
enum class PVPutType { Integer, Double, String };
```

Constructor: `InputWidget(App&, pv_name, PVPutType, fg_color = Black, hover_color = GrayLight)` or `InputWidget(PVGroup&, ...)`.

| Method | Description |
|--------|-------------|
| `value() const` | Returns `const std::string&` of current display string |
| `value_as_string() const` | Same as `value()` |

When disconnected, the display string is cleared. When focused/hovered, uses the specified colors.

### 10.4 ButtonWidget

Writes a fixed integer value to a PV when clicked.

```cpp
ButtonWidget proc(app, prefix + "calc.PROC", "Process", ButtonOption::Ascii(), 1);
ButtonWidget stop(app, prefix + "m1.STOP", " STOP ", ButtonOption::Simple());
```

Constructor: `ButtonWidget(App&, pv_name, label, ButtonOption = Ascii(), press_val = 1)` or `ButtonWidget(PVGroup&, ...)`.

Only writes when connected.

### 10.5 ChoiceWidget

Selector for enum-style PVs (mbbi/mbbo). Reads choices from the PV and writes `value.index` on selection.

```cpp
enum class ChoiceStyle { Vertical, Horizontal, Dropdown };

ChoiceWidget spmg(app, prefix + "m1.SPMG", ChoiceStyle::Vertical);
ChoiceWidget dir(app, prefix + "m1.DIR", ChoiceStyle::Horizontal);
ChoiceWidget foff(app, prefix + "m1.FOFF", ChoiceStyle::Dropdown);
```

Constructor: `ChoiceWidget(App&, pv_name, ChoiceStyle)` or `ChoiceWidget(PVGroup&, ...)`.

| Method | Description |
|--------|-------------|
| `value() const` | Returns `const PVEnum&` |
| `value_as_string() const` | Returns `PVEnum::choice` |

### 10.6 BitsWidget

Displays an integer PV as colored bit blocks.

```cpp
BitsWidget bits(app, prefix + "status", BitRange{0, 8}, Color::Green, Color::GrayDark);
```

`BitRange{start, end}` — `start` inclusive, `end` exclusive.

Constructor: `BitsWidget(App&, pv_name, BitRange, color_on = Green, color_off = GrayDark)` or `BitsWidget(PVGroup&, ...)`.

| Method | Description |
|--------|-------------|
| `value() const` | Returns `const int&` |
| `value_as_string() const` | `std::to_string(value)` |

---

## 11. PVTUI App Scaffold

Include: `<pvtui/app.hpp>` (or `<pvtui/pvtui.hpp>` for everything)

### 11.1 ArgParser

```cpp
ArgParser(int argc, char* argv[], std::initializer_list<char const* const> extra_params = {});
```

`--provider` is always registered. Pass additional named parameters via `extra_params`.

| Member/Method | Description |
|---------------|-------------|
| `provider` | `std::string`, defaults to `"ca"`. Set via `--provider pva` |
| `help(msg)` | Prints msg if `-h`/`--help` present, returns true |
| `flag(name)` | Checks if boolean flag is set |
| `param(name)` | Gets named parameter value (empty string if absent) |
| `positional_args()` | Returns all positional args (including argv[0]) |

### 11.2 App Struct

```cpp
struct App {
    int poll_period_ms = 100;
    ArgParser args;
    pvac::ClientProvider provider;
    PVGroup pvgroup;
    ftxui::ScreenInteractive screen;  // Fullscreen mode
    std::function<void(App&, const ftxui::Component&)> main_loop;

    App(int argc, char* argv[], std::initializer_list<char const* const> extra_params = {});
    void run(const ftxui::Component& renderer, int poll_period_ms = 100);
};
```

The default `main_loop`:

```cpp
[](App& app, const ftxui::Component& renderer) {
    ftxui::Loop loop(&app.screen, renderer);
    while (!loop.HasQuitted()) {
        if (app.pvgroup.sync()) {
            app.screen.PostEvent(ftxui::Event::Custom);
        }
        loop.RunOnce();
        std::this_thread::sleep_for(std::chrono::milliseconds(app.poll_period_ms));
    }
};
```

### 11.3 Custom Main Loop

Override `app.main_loop` before calling `app.run()` for custom behavior (e.g., time-based sampling):

```cpp
app.main_loop = [&](pvtui::App& app, const ftxui::Component& renderer) {
    ftxui::Loop loop(&app.screen, renderer);
    auto last_sample = std::chrono::steady_clock::now();
    while (!loop.HasQuitted()) {
        app.pvgroup.sync();
        auto now = std::chrono::steady_clock::now();
        double elapsed = std::chrono::duration<double>(now - last_sample).count();
        if (elapsed >= sample_rate) {
            /* sample data */
            app.screen.PostEvent(ftxui::Event::Custom);
            last_sample = now;
        }
        loop.RunOnce();
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
};
app.run(container);
```

---

## 12. PVTUI EPICSColor Decorators

Include: `<pvtui/widgets.hpp>` (namespace `pvtui::EPICSColor`)

Connection-aware styling. When disconnected, all return `WHITE_ON_WHITE` (white text on white bg), mimicking MEDM behavior.

| Decorator | Connected Style | Use Case |
|-----------|----------------|----------|
| `EPICSColor::edit(widget)` | Light blue bg (#57CAE4), black text | Editable input fields |
| `EPICSColor::menu(widget)` | Dark green bg (#106919), white text | Menu/selector controls |
| `EPICSColor::readback(widget)` | Gray bg (#C4C4C4), dark blue text | Read-only readbacks |
| `EPICSColor::link(widget)` | Purple bg (#9494E4), black text | Link fields |
| `EPICSColor::custom(widget, decorator)` | User-provided style | Custom with disconnect fallback |
| `EPICSColor::background()` | Gray bg (#C4C4C4) | Static background (not connection-aware) |

```cpp
val.component()->Render() | size(WIDTH, EQUAL, 10) | EPICSColor::edit(val)
rbv.component()->Render() | EPICSColor::readback(rbv)
stop.component()->Render() | EPICSColor::custom(stop, color(Color::Red)) | bold
element | EPICSColor::background()
```

---

## 13. Complete Application Pattern

### 13.1 Minimal PVTUI Application

```cpp
#include <pvtui/pvtui.hpp>
#include <ftxui/component/component.hpp>

using namespace ftxui;
using namespace pvtui;

int main(int argc, char* argv[]) {
    pvtui::App app(argc, argv, {"--prefix"});
    if (app.args.help("Usage: myapp --prefix <prefix>")) return 0;

    std::string prefix = app.args.param("--prefix");

    InputWidget desc(app, prefix + "m1.DESC", PVPutType::String);
    InputWidget val(app, prefix + "m1.VAL", PVPutType::Double);
    Monitor<std::string> rbv(app, prefix + "m1.RBV");
    ButtonWidget stop(app, prefix + "m1.STOP", "STOP");

    auto container = Container::Vertical({
        desc.component(),
        val.component(),
        stop.component(),
    });

    container |= Renderer([&](Element) {
        return vbox({
            hbox({ text("DESC: "), desc.component()->Render() | EPICSColor::edit(desc) }),
            separator(),
            hbox({ text("VAL:  "), val.component()->Render() | size(WIDTH, EQUAL, 10) | EPICSColor::edit(val) }),
            hbox({ text("RBV:  "), rbv.component()->Render() | EPICSColor::readback(rbv) }),
            separator(),
            stop.component()->Render() | EPICSColor::custom(stop, color(Color::Red)),
        }) | border;
    });

    app.run(container);
}
```

### 13.2 Application Structure Pattern

The standard PVTUI application follows this structure:

1. **Create `App`** — parses args, initializes EPICS provider, creates PVGroup and screen.
2. **Handle `--help`** — print usage and exit if requested.
3. **Extract prefix/PV names** — from `--prefix` param or positional args.
4. **Instantiate widgets** — each auto-registers its PV with the PVGroup.
5. **Build `Container`** — add all interactive widget components (inputs, buttons, selectors). Read-only `Monitor` widgets do not need to be in the container.
6. **Apply `Renderer`** — define visual layout using FTXUI elements. Call `widget.component()->Render()` and apply `EPICSColor` decorators and `size()` constraints.
7. **Call `app.run(container)`** — starts the event loop.

### 13.3 Custom ComponentBase Pattern

For complex, reusable display panels, subclass `ComponentBase`:

```cpp
class MotorPanel : public ftxui::ComponentBase {
  public:
    MotorPanel(pvtui::PVGroup& pvgroup, const std::string& record)
        : val(pvgroup, record + ".VAL", pvtui::PVPutType::Double),
          rbv(pvgroup, record + ".RBV"),
          stop(pvgroup, record + ".STOP", "STOP") {
        auto container = ftxui::Container::Vertical({
            val.component(), stop.component(),
        }) | ftxui::Renderer([this](ftxui::Element) { return this->render(); });
        Add(container);
    }

  private:
    pvtui::InputWidget val;
    pvtui::Monitor<std::string> rbv;
    pvtui::ButtonWidget stop;

    ftxui::Element render() {
        using namespace ftxui;
        using namespace pvtui;
        return vbox({
            hbox({ text("VAL: "), val.component()->Render() | EPICSColor::edit(val) }),
            hbox({ text("RBV: "), rbv.component()->Render() | EPICSColor::readback(rbv) }),
            stop.component()->Render() | EPICSColor::custom(stop, color(Color::Red)),
        }) | border;
    }
};

// Instantiate with:
auto panel = ftxui::Make<MotorPanel>(app.pvgroup, "IOC:m1");
```

---

## 14. Key Rules and Pitfalls

1. **Only interactive components go in `Container`.** `Monitor<T>` widgets render via `Renderer` and are not focusable. Include them in the `Renderer` layout lambda, not in the `Container`.

2. **Always call `widget.component()->Render()` in the Renderer lambda.** Do not store the result of `Render()` — it must be called fresh each frame.

3. **`PVGroup::sync()` must be called on the main thread.** The default `App::main_loop` handles this. If you override `main_loop`, you must call `pvgroup.sync()` yourself and post `Event::Custom` when it returns true.

4. **`PVGroup::operator[]` auto-creates PVs; `get_pv()` throws.** Use `operator[]` when you want lazy creation. Use `get_pv()` when the PV must already exist.

5. **CRITICAL: Widget constructors take `App&` or `PVGroup&` — not both.** The `App&` overload delegates to `app.pvgroup`. All widgets sharing the same `App` share the same `PVGroup` and provider.

6. **EPICSColor decorators take `const WidgetBase&`, not a Component.** Pass the widget object itself: `EPICSColor::edit(my_widget)`, not `EPICSColor::edit(my_widget.component())`.

7. **`InputWidget` clears its display when disconnected.** This is intentional (mimics MEDM). Do not add extra disconnect-handling logic for inputs.

8. **The pipe operator `|` for Renderer on a Container takes `Element` as the lambda argument.** Use `container |= Renderer([&](Element) { ... })` — the `Element` parameter is the inner rendering which you typically ignore in favor of calling `->Render()` on individual widgets for full layout control.

9. **`force_update()` is needed after manual `channel.get()` calls.** A prior `get()` consumes the initial monitor event, leaving widgets empty until the next PV change. Call `pvgroup.force_update()` to re-fetch.

10. **FTXUI `size()` constraints are decorators, not layout containers.** Apply them with `|`: `element | size(WIDTH, EQUAL, 10)`. They constrain the element's allocated space, not its content.

11. **`Container::Tab` needs an external selector.** Tab does not provide keyboard navigation between tabs. Pair it with a `Menu` or buttons that modify the `int* selector`.

12. **CRITICAL: Thread safety.** Never access PV data from EPICS monitor callbacks directly in renderers. Always go through `PVGroup::sync()` → user variable → renderer. The mutex in `PVHandler` protects the internal slot, not your user variables after sync.

13. **Custom main loops must call `loop.RunOnce()`.** Forgetting this means no FTXUI events get processed (no keyboard, no mouse, no rendering).

14. **PVTUI uses pvAccess client API (`pva/client.h`) with CA provider by default.** Switch to native pvAccess with `--provider pva`. Both protocols work through the same `pvac::ClientProvider` interface.
