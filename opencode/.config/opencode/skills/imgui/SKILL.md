---
name: imgui
description: Write Dear ImGui application code in C++ -- windows, widgets, tables, menus, popups, docking, drag-and-drop, custom drawing, and styling
---

# Dear ImGui Application Skill

You are an expert at writing C++ application code using **Dear ImGui** (docking branch, v1.92+). ImGui is an immediate-mode GUI library: every frame you call functions to emit UI, and ImGui produces draw lists for rendering. All API functions live in `namespace ImGui`. All types/structs/enums are in global scope with `ImGui` or `Im` prefixes.

---

## 1. Initialization & Main Loop (GLFW + OpenGL3)

### imconfig.h recommended setting

```cpp
#define IMGUI_DEFINE_MATH_OPERATORS
```

This enables `+`, `-`, `*`, `/` operators on `ImVec2` and `ImVec4`. Without it, vector math won't compile.

### Initialization

```cpp
#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include <GLFW/glfw3.h>

glfwInit();
glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
GLFWwindow* window = glfwCreateWindow(1280, 800, "My App", nullptr, nullptr);
glfwMakeContextCurrent(window);
glfwSwapInterval(1);

IMGUI_CHECKVERSION();
ImGui::CreateContext();
ImGuiIO& io = ImGui::GetIO();
io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;
io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;

ImGui::StyleColorsDark();

if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable)
{
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowRounding = 0.0f;
    style.Colors[ImGuiCol_WindowBg].w = 1.0f;
}

ImGui_ImplGlfw_InitForOpenGL(window, true);
ImGui_ImplOpenGL3_Init("#version 130");
```

### Main loop

```cpp
while (!glfwWindowShouldClose(window))
{
    glfwPollEvents();

    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();

    // --- Your UI code here ---

    ImGui::Render();
    int display_w, display_h;
    glfwGetFramebufferSize(window, &display_w, &display_h);
    glViewport(0, 0, display_w, display_h);
    glClearColor(0.45f, 0.55f, 0.60f, 1.00f);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

    if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable)
    {
        GLFWwindow* backup = glfwGetCurrentContext();
        ImGui::UpdatePlatformWindows();
        ImGui::RenderPlatformWindowsDefault();
        glfwMakeContextCurrent(backup);
    }

    glfwSwapBuffers(window);
}
```

### Shutdown

```cpp
ImGui_ImplOpenGL3_Shutdown();
ImGui_ImplGlfw_Shutdown();
ImGui::DestroyContext();
glfwDestroyWindow(window);
glfwTerminate();
```

### Input ownership

After `Render()`, check `io.WantCaptureMouse` and `io.WantCaptureKeyboard` to determine whether ImGui wants to consume input. If true, don't dispatch that input to your application logic (e.g., game camera, 3D picking).

```cpp
if (!io.WantCaptureMouse) { /* handle app mouse input */ }
if (!io.WantCaptureKeyboard) { /* handle app keyboard input */ }
```

---

## 2. Windows

### Basic window with early-out

```cpp
if (!ImGui::Begin("My Window", &show_window, ImGuiWindowFlags_MenuBar))
{
    ImGui::End();
    return;
}
// ... widgets ...
ImGui::End();
```

`Begin()` returns false when collapsed. **You must still call `End()`** even if `Begin()` returns false. The early-out pattern above handles this.

The `bool* p_open` parameter adds a close button. Pass `nullptr` if not needed.

### Common ImGuiWindowFlags

| Flag | Effect |
|------|--------|
| `ImGuiWindowFlags_NoTitleBar` | No title bar |
| `ImGuiWindowFlags_NoResize` | Fixed size |
| `ImGuiWindowFlags_NoMove` | Fixed position |
| `ImGuiWindowFlags_NoCollapse` | Disable collapse |
| `ImGuiWindowFlags_MenuBar` | Has a menu bar |
| `ImGuiWindowFlags_AlwaysAutoResize` | Auto-fit to contents |
| `ImGuiWindowFlags_HorizontalScrollbar` | Enable horizontal scroll |
| `ImGuiWindowFlags_NoDocking` | Cannot be docked |

### SetNextWindow functions

```cpp
ImGui::SetNextWindowPos(ImVec2(100, 100), ImGuiCond_FirstUseEver);
ImGui::SetNextWindowSize(ImVec2(400, 300), ImGuiCond_FirstUseEver);
ImGui::Begin("Positioned Window");
```

`ImGuiCond` values: `ImGuiCond_Always`, `ImGuiCond_Once`, `ImGuiCond_FirstUseEver`, `ImGuiCond_Appearing`.

### Child windows

```cpp
ImGui::BeginChild("child_region", ImVec2(0, 200), ImGuiChildFlags_Borders);
// ... scrollable content ...
ImGui::EndChild();
```

---

## 3. Layout

```cpp
ImGui::SameLine();
ImGui::SameLine(0.0f, 20.0f);

ImGui::Separator();
ImGui::SeparatorText("Section");
ImGui::Spacing();
ImGui::Dummy(ImVec2(0, 20));

ImGui::Indent();
ImGui::Unindent();

ImGui::BeginGroup();
// ... items laid out together ...
ImGui::EndGroup();
```

### Content region and cursor

```cpp
ImVec2 avail = ImGui::GetContentRegionAvail();
ImVec2 screen_pos = ImGui::GetCursorScreenPos();
ImGui::SetCursorScreenPos(ImVec2(100, 200));
```

`GetCursorScreenPos()` returns absolute screen coordinates. Use this for custom drawing with `ImDrawList`.

### Item width

```cpp
ImGui::PushItemWidth(200);
ImGui::InputFloat("X", &x);
ImGui::PopItemWidth();

ImGui::SetNextItemWidth(200);
ImGui::InputFloat("Y", &y);

ImGui::PushItemWidth(-150);
```

Negative values for `PushItemWidth` mean "window width minus N pixels" -- useful for right-aligning widget edges.

---

## 4. ID Stack

ImGui identifies widgets by ID. IDs are built from the label string hashed with the current ID stack. Duplicate IDs within the same scope cause conflicts.

### PushID / PopID

```cpp
for (int i = 0; i < count; i++)
{
    ImGui::PushID(i);
    ImGui::InputFloat("Value", &values[i]);
    ImGui::SameLine();
    if (ImGui::Button("Reset"))
        values[i] = 0.0f;
    ImGui::PopID();
}
```

### ## and ### syntax

- `"Label##unique"` -- `##` hides everything after it from display but includes it in the ID. Use to give identical-looking widgets unique IDs.
- `"###id"` -- `###` makes the ID from only what follows. The display label is everything before `###`. Use to change the displayed label without changing the stored ID (preserves window state).

```cpp
ImGui::Button("Click##1");
ImGui::Button("Click##2");

static bool toggled = false;
char buf[64];
snprintf(buf, sizeof(buf), "%s###toggle_btn", toggled ? "ON" : "OFF");
ImGui::Begin(buf);
```

---

## 5. Widgets: Text & Labels

```cpp
ImGui::Text("Value: %d", value);
ImGui::TextUnformatted(long_string);

ImGui::TextColored(ImVec4(1, 0, 0, 1), "Error: %s", msg);
ImGui::TextDisabled("Grayed out");
ImGui::TextWrapped("Long text that wraps at window edge...");
ImGui::BulletText("Bullet point");
ImGui::SeparatorText("Section Header");
ImGui::LabelText("label", "value %d", n);
ImGui::TextLinkOpenURL("Visit docs", "https://dearimgui.com/docs");
```

Use `TextUnformatted()` for strings that don't need printf formatting -- it's faster and doesn't interpret `%` characters.

### Tooltip helper (HelpMarker pattern)

```cpp
static void HelpMarker(const char* desc)
{
    ImGui::TextDisabled("(?)");
    if (ImGui::BeginItemTooltip())
    {
        ImGui::PushTextWrapPos(ImGui::GetFontSize() * 35.0f);
        ImGui::TextUnformatted(desc);
        ImGui::PopTextWrapPos();
        ImGui::EndTooltip();
    }
}

// Usage:
ImGui::SliderFloat("Speed", &speed, 0, 100);
ImGui::SameLine();
HelpMarker("Drag to adjust speed.\nCtrl+click to type a value.");
```

### Tooltips (general)

```cpp
ImGui::Button("Hover me");
if (ImGui::BeginItemTooltip())
{
    ImGui::Text("Rich tooltip with widgets");
    ImGui::EndTooltip();
}

ImGui::Button("Simple");
ImGui::SetItemTooltip("Plain text tooltip");
```

---

## 6. Widgets: Buttons & Inputs

### Buttons

```cpp
if (ImGui::Button("OK"))
    DoAction();

if (ImGui::Button("Sized", ImVec2(120, 0)))
    DoAction();

ImGui::SmallButton("small");

if (ImGui::ArrowButton("##left", ImGuiDir_Left))
    index--;
ImGui::SameLine();
if (ImGui::ArrowButton("##right", ImGuiDir_Right))
    index++;

ImGui::InvisibleButton("canvas", ImVec2(200, 200));
```

### Checkbox and RadioButton

```cpp
static bool enabled = true;
ImGui::Checkbox("Enable", &enabled);

static int mode = 0;
ImGui::RadioButton("Mode A", &mode, 0);
ImGui::SameLine();
ImGui::RadioButton("Mode B", &mode, 1);
```

### ProgressBar

```cpp
ImGui::ProgressBar(fraction, ImVec2(-FLT_MIN, 0), "75%%");
```

### InputText

```cpp
static char buf[256] = "";
ImGui::InputText("Name", buf, sizeof(buf));
ImGui::InputText("Password", buf, sizeof(buf), ImGuiInputTextFlags_Password);
ImGui::InputTextWithHint("Search", "type here...", buf, sizeof(buf));
ImGui::InputTextMultiline("Code", buf, sizeof(buf), ImVec2(-FLT_MIN, ImGui::GetTextLineHeight() * 8));
```

#### std::string support

Include `misc/cpp/imgui_stdlib.h` (and compile `imgui_stdlib.cpp`) for `std::string` overloads:

```cpp
#include "misc/cpp/imgui_stdlib.h"

static std::string name;
ImGui::InputText("Name", &name);
```

### InputFloat / InputInt

```cpp
static float f = 0.0f;
ImGui::InputFloat("X", &f, 0.1f, 1.0f, "%.3f");

static int i = 0;
ImGui::InputInt("Count", &i);
```

### SliderFloat / SliderInt

```cpp
static float val = 0.5f;
ImGui::SliderFloat("Speed", &val, 0.0f, 10.0f);
ImGui::SliderFloat("Log", &val, 0.001f, 100.0f, "%.3f", ImGuiSliderFlags_Logarithmic);

static int n = 50;
ImGui::SliderInt("Items", &n, 0, 100);
```

### DragFloat / DragInt

```cpp
static float d = 0.0f;
ImGui::DragFloat("Drag", &d, 0.1f);
ImGui::DragFloat("Clamped", &d, 0.1f, 0.0f, 100.0f, "%.1f", ImGuiSliderFlags_AlwaysClamp);

static int di = 0;
ImGui::DragInt("Drag Int", &di, 1, 0, 100);
```

### Combo

```cpp
const char* items[] = {"Apple", "Banana", "Cherry"};
static int current = 0;
ImGui::Combo("Fruit", &current, items, IM_COUNTOF(items));
```

#### BeginCombo (for custom content)

```cpp
const char* items[] = {"Apple", "Banana", "Cherry"};
static int current = 0;
if (ImGui::BeginCombo("Fruit", items[current]))
{
    for (int i = 0; i < IM_COUNTOF(items); i++)
    {
        bool is_selected = (current == i);
        if (ImGui::Selectable(items[i], is_selected))
            current = i;
        if (is_selected)
            ImGui::SetItemDefaultFocus();
    }
    ImGui::EndCombo();
}
```

### ColorEdit

```cpp
static float col3[3] = {1.0f, 0.0f, 0.0f};
ImGui::ColorEdit3("Color", col3);

static float col4[4] = {1.0f, 0.0f, 0.0f, 1.0f};
ImGui::ColorEdit4("Color+Alpha", col4);
ImGui::ColorEdit4("No Alpha", col4, ImGuiColorEditFlags_NoAlpha);
```

---

## 7. Widgets: Trees & Selectables

### TreeNode

```cpp
if (ImGui::TreeNode("Animals"))
{
    if (ImGui::TreeNode("Cats"))
    {
        ImGui::Text("Meow");
        ImGui::TreePop();
    }
    ImGui::TreePop();
}
```

### TreeNodeEx (with flags)

```cpp
ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags_DefaultOpen | ImGuiTreeNodeFlags_SpanAllColumns;
if (ImGui::TreeNodeEx("Root", flags))
{
    ImGuiTreeNodeFlags leaf_flags = ImGuiTreeNodeFlags_Leaf | ImGuiTreeNodeFlags_NoTreePushOnOpen;
    ImGui::TreeNodeEx("Leaf Item", leaf_flags);
    ImGui::TreePop();
}
```

### CollapsingHeader

```cpp
if (ImGui::CollapsingHeader("Settings"))
{
    ImGui::SliderFloat("Speed", &speed, 0, 100);
}

static bool visible = true;
if (ImGui::CollapsingHeader("Closable", &visible))
{
    ImGui::Text("Content");
}
```

`CollapsingHeader` does not need `TreePop()`. The `bool* p_visible` overload adds a close button.

### Selectable

```cpp
const char* items[] = {"Alpha", "Beta", "Gamma"};
static int selected = 0;
for (int i = 0; i < 3; i++)
{
    if (ImGui::Selectable(items[i], selected == i))
        selected = i;
}
```

---

## 8. Tables

### Basic table

```cpp
if (ImGui::BeginTable("my_table", 3, ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg))
{
    ImGui::TableSetupColumn("Name");
    ImGui::TableSetupColumn("Value");
    ImGui::TableSetupColumn("Action");
    ImGui::TableHeadersRow();

    for (int row = 0; row < data_count; row++)
    {
        ImGui::TableNextRow();
        ImGui::TableNextColumn(); ImGui::Text("%s", data[row].name);
        ImGui::TableNextColumn(); ImGui::Text("%.2f", data[row].value);
        ImGui::TableNextColumn();
        ImGui::PushID(row);
        if (ImGui::SmallButton("Delete"))
            DeleteItem(row);
        ImGui::PopID();
    }
    ImGui::EndTable();
}
```

### Common ImGuiTableFlags

| Flag | Effect |
|------|--------|
| `ImGuiTableFlags_Borders` | All borders |
| `ImGuiTableFlags_BordersInnerV` | Vertical inner borders only |
| `ImGuiTableFlags_RowBg` | Alternating row colors |
| `ImGuiTableFlags_Resizable` | Columns can be resized |
| `ImGuiTableFlags_Sortable` | Enable sorting |
| `ImGuiTableFlags_ScrollX` | Horizontal scrolling |
| `ImGuiTableFlags_ScrollY` | Vertical scrolling (requires outer_size.y) |
| `ImGuiTableFlags_SizingFixedFit` | Fixed columns sized to contents |
| `ImGuiTableFlags_SizingStretchSame` | Stretch columns equally |

### Column setup flags

```cpp
ImGui::TableSetupColumn("ID", ImGuiTableColumnFlags_DefaultSort | ImGuiTableColumnFlags_WidthFixed, 60.0f);
ImGui::TableSetupColumn("Name", ImGuiTableColumnFlags_WidthStretch);
ImGui::TableSetupColumn("Qty", ImGuiTableColumnFlags_PreferSortDescending | ImGuiTableColumnFlags_WidthFixed, 80.0f);
ImGui::TableSetupScrollFreeze(0, 1);
```

### Sorting

```cpp
if (ImGuiTableSortSpecs* sort_specs = ImGui::TableGetSortSpecs())
{
    if (sort_specs->SpecsDirty)
    {
        std::sort(items.begin(), items.end(), [&](const auto& a, const auto& b) {
            for (int n = 0; n < sort_specs->SpecsCount; n++)
            {
                const ImGuiTableColumnSortSpecs* spec = &sort_specs->Specs[n];
                int cmp = 0;
                if (spec->ColumnIndex == 0) cmp = a.id - b.id;
                if (spec->ColumnIndex == 1) cmp = strcmp(a.name, b.name);
                if (spec->SortDirection == ImGuiSortDirection_Descending) cmp = -cmp;
                if (cmp != 0) return cmp < 0;
            }
            return false;
        });
        sort_specs->SpecsDirty = false;
    }
}
```

### ImGuiListClipper (for large tables/lists)

For tables or scrolling regions with thousands of rows, use `ImGuiListClipper` to only process visible rows:

```cpp
if (ImGui::BeginTable("big_table", 3, ImGuiTableFlags_ScrollY, ImVec2(0, 400)))
{
    ImGui::TableSetupColumn("Index");
    ImGui::TableSetupColumn("Data");
    ImGui::TableSetupColumn("Value");
    ImGui::TableSetupScrollFreeze(0, 1);
    ImGui::TableHeadersRow();

    ImGuiListClipper clipper;
    clipper.Begin(100000);
    while (clipper.Step())
    {
        for (int row = clipper.DisplayStart; row < clipper.DisplayEnd; row++)
        {
            ImGui::TableNextRow();
            ImGui::TableNextColumn(); ImGui::Text("%d", row);
            ImGui::TableNextColumn(); ImGui::Text("Item %d", row);
            ImGui::TableNextColumn(); ImGui::Text("%.2f", row * 0.1f);
        }
    }
    ImGui::EndTable();
}
```

---

## 9. Menus

### Main menu bar

```cpp
if (ImGui::BeginMainMenuBar())
{
    if (ImGui::BeginMenu("File"))
    {
        if (ImGui::MenuItem("New", "Ctrl+N")) DoNew();
        if (ImGui::MenuItem("Open", "Ctrl+O")) DoOpen();
        ImGui::Separator();
        if (ImGui::MenuItem("Quit", "Alt+F4")) DoQuit();
        ImGui::EndMenu();
    }
    if (ImGui::BeginMenu("Edit"))
    {
        if (ImGui::MenuItem("Undo", "Ctrl+Z", false, can_undo)) DoUndo();
        if (ImGui::MenuItem("Redo", "Ctrl+Y", false, can_redo)) DoRedo();
        ImGui::EndMenu();
    }
    ImGui::EndMainMenuBar();
}
```

### Window menu bar

Requires `ImGuiWindowFlags_MenuBar` on the window:

```cpp
ImGui::Begin("Editor", nullptr, ImGuiWindowFlags_MenuBar);
if (ImGui::BeginMenuBar())
{
    if (ImGui::BeginMenu("Options"))
    {
        static bool auto_save = true;
        ImGui::MenuItem("Auto-save", nullptr, &auto_save);
        ImGui::EndMenu();
    }
    ImGui::EndMenuBar();
}
ImGui::End();
```

The `bool* p_selected` overload of `MenuItem` toggles the bool and shows a checkmark.

---

## 10. Popups & Modals

### Popup (flyout)

```cpp
if (ImGui::Button("Select.."))
    ImGui::OpenPopup("select_popup");

if (ImGui::BeginPopup("select_popup"))
{
    ImGui::SeparatorText("Pick one");
    for (int i = 0; i < count; i++)
        if (ImGui::Selectable(names[i]))
            selected = i;
    ImGui::EndPopup();
}
```

### Context menu (right-click)

```cpp
ImGui::Selectable(item_name);
if (ImGui::BeginPopupContextItem())
{
    if (ImGui::MenuItem("Copy")) DoCopy();
    if (ImGui::MenuItem("Delete")) DoDelete();
    ImGui::EndPopup();
}
```

`BeginPopupContextItem()` uses the last item's ID. `BeginPopupContextWindow()` triggers on the window background.

### Modal dialog

```cpp
if (ImGui::Button("Delete.."))
    ImGui::OpenPopup("Confirm Delete");

ImVec2 center = ImGui::GetMainViewport()->GetCenter();
ImGui::SetNextWindowPos(center, ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));

if (ImGui::BeginPopupModal("Confirm Delete", nullptr, ImGuiWindowFlags_AlwaysAutoResize))
{
    ImGui::Text("This cannot be undone.");
    ImGui::Separator();

    if (ImGui::Button("OK", ImVec2(120, 0)))
    {
        DoDelete();
        ImGui::CloseCurrentPopup();
    }
    ImGui::SetItemDefaultFocus();
    ImGui::SameLine();
    if (ImGui::Button("Cancel", ImVec2(120, 0)))
        ImGui::CloseCurrentPopup();

    ImGui::EndPopup();
}
```

---

## 11. Tab Bars

```cpp
if (ImGui::BeginTabBar("my_tabs", ImGuiTabBarFlags_Reorderable))
{
    if (ImGui::BeginTabItem("General"))
    {
        ImGui::Text("General settings");
        ImGui::EndTabItem();
    }
    if (ImGui::BeginTabItem("Advanced"))
    {
        ImGui::Text("Advanced settings");
        ImGui::EndTabItem();
    }

    static bool unsaved = true;
    if (ImGui::BeginTabItem("Document", &unsaved, ImGuiTabItemFlags_UnsavedDocument))
    {
        ImGui::Text("Document content");
        ImGui::EndTabItem();
    }

    ImGui::EndTabBar();
}
```

`BeginTabItem` returns false when the tab is not selected. Only call `EndTabItem()` when `BeginTabItem()` returns true.

---

## 12. Docking

### Enable docking

In initialization:

```cpp
io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;
```

### Simple: DockSpaceOverViewport

```cpp
ImGui::DockSpaceOverViewport();
```

This creates a dockspace that fills the entire main viewport. All windows can be docked into it. For a transparent central node:

```cpp
ImGui::DockSpaceOverViewport(0, nullptr, ImGuiDockNodeFlags_PassthruCentralNode);
```

### Advanced: Explicit DockSpace

```cpp
const ImGuiViewport* viewport = ImGui::GetMainViewport();
ImGui::SetNextWindowPos(viewport->WorkPos);
ImGui::SetNextWindowSize(viewport->WorkSize);
ImGui::SetNextWindowViewport(viewport->ID);

ImGuiWindowFlags host_flags = ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_NoTitleBar |
    ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove |
    ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_NoNavFocus |
    ImGuiWindowFlags_NoBackground;

ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding, 0.0f);
ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0.0f, 0.0f));
ImGui::Begin("DockHost", nullptr, host_flags);
ImGui::PopStyleVar(3);

ImGuiID dockspace_id = ImGui::GetID("MyDockSpace");
ImGui::DockSpace(dockspace_id, ImVec2(0.0f, 0.0f));

ImGui::End();
```

### DockNodeFlags

| Flag | Effect |
|------|--------|
| `ImGuiDockNodeFlags_PassthruCentralNode` | Central node is transparent |
| `ImGuiDockNodeFlags_NoDockingOverCentralNode` | Prevent docking over center |
| `ImGuiDockNodeFlags_NoResize` | Disable resize |
| `ImGuiDockNodeFlags_NoUndocking` | Prevent undocking |
| `ImGuiDockNodeFlags_AutoHideTabBar` | Hide tab bar when single tab |

---

## 13. Drag & Drop

### Source

```cpp
ImGui::Button(label);
if (ImGui::BeginDragDropSource())
{
    ImGui::SetDragDropPayload("MY_TYPE", &data, sizeof(data));
    ImGui::Text("Dragging %s", label);
    ImGui::EndDragDropSource();
}
```

### Target

```cpp
ImGui::Button(target_label);
if (ImGui::BeginDragDropTarget())
{
    if (const ImGuiPayload* payload = ImGui::AcceptDragDropPayload("MY_TYPE"))
    {
        IM_ASSERT(payload->DataSize == sizeof(MyData));
        MyData received = *(const MyData*)payload->Data;
        HandleDrop(received);
    }
    ImGui::EndDragDropTarget();
}
```

The payload type string (e.g., `"MY_TYPE"`) must match between source and target. Data is copied internally -- the source pointer doesn't need to stay valid after `SetDragDropPayload`.

---

## 14. Custom Drawing (ImDrawList)

### Getting the draw list

```cpp
ImDrawList* draw_list = ImGui::GetWindowDrawList();
```

Use `GetBackgroundDrawList()` / `GetForegroundDrawList()` for drawing behind/in front of all windows.

### Primitives

```cpp
ImVec2 p = ImGui::GetCursorScreenPos();
ImU32 col = IM_COL32(255, 255, 0, 255);

draw_list->AddLine(ImVec2(p.x, p.y), ImVec2(p.x + 100, p.y + 50), col, 2.0f);
draw_list->AddRect(ImVec2(p.x, p.y), ImVec2(p.x + 100, p.y + 50), col, 5.0f, 1.0f);
draw_list->AddRectFilled(ImVec2(p.x, p.y), ImVec2(p.x + 100, p.y + 50), col, 5.0f);
draw_list->AddCircle(ImVec2(p.x + 50, p.y + 25), 20.0f, col, 0, 2.0f);
draw_list->AddCircleFilled(ImVec2(p.x + 50, p.y + 25), 20.0f, col);
draw_list->AddText(ImVec2(p.x, p.y), col, "Hello");
draw_list->AddBezierCubic(p1, p2, p3, p4, col, 2.0f);
```

Colors use `IM_COL32(R, G, B, A)` (0-255 per channel).

`IMGUI_DEFINE_MATH_OPERATORS` must be defined for vector arithmetic in drawing code.

### Canvas pattern

```cpp
ImVec2 canvas_p0 = ImGui::GetCursorScreenPos();
ImVec2 canvas_sz = ImGui::GetContentRegionAvail();
if (canvas_sz.x < 50.0f) canvas_sz.x = 50.0f;
if (canvas_sz.y < 50.0f) canvas_sz.y = 50.0f;
ImVec2 canvas_p1 = ImVec2(canvas_p0.x + canvas_sz.x, canvas_p0.y + canvas_sz.y);

ImDrawList* draw_list = ImGui::GetWindowDrawList();
draw_list->AddRectFilled(canvas_p0, canvas_p1, IM_COL32(50, 50, 50, 255));

ImGui::InvisibleButton("canvas", canvas_sz,
    ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight);
bool is_active = ImGui::IsItemActive();
bool is_hovered = ImGui::IsItemHovered();

draw_list->PushClipRect(canvas_p0, canvas_p1, true);
// ... draw content clipped to canvas ...
draw_list->PopClipRect();
```

---

## 15. Images & Textures

Loading and displaying a texture (OpenGL3 example):

```cpp
#include <GL/gl.h>

GLuint LoadTexture(const unsigned char* pixels, int width, int height)
{
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    return tex;
}

// After loading pixels (e.g., via stb_image):
GLuint my_tex = LoadTexture(pixels, w, h);
```

Displaying:

```cpp
ImGui::Image((ImTextureID)(intptr_t)my_tex, ImVec2(w, h));

if (ImGui::ImageButton("btn_id", (ImTextureID)(intptr_t)my_tex, ImVec2(64, 64)))
    DoAction();
```

`Image()` and `ImageButton()` take `ImTextureRef`, which has an implicit constructor from `ImTextureID` (default: `ImU64`). For OpenGL, cast your `GLuint` to `ImTextureID` via `(ImTextureID)(intptr_t)tex`.

---

## 16. Styling

### Push/Pop style colors

```cpp
ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.8f, 0.2f, 0.2f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.9f, 0.3f, 0.3f, 1.0f));
ImGui::Button("Red Button");
ImGui::PopStyleColor(2);
```

### Push/Pop style variables

```cpp
ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 12.0f);
ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(10, 10));
// ... widgets ...
ImGui::PopStyleVar(2);
```

### Common ImGuiCol values

`ImGuiCol_Text`, `ImGuiCol_WindowBg`, `ImGuiCol_FrameBg`, `ImGuiCol_Button`, `ImGuiCol_ButtonHovered`, `ImGuiCol_ButtonActive`, `ImGuiCol_Header`, `ImGuiCol_HeaderHovered`, `ImGuiCol_Tab`, `ImGuiCol_TabSelected`.

### Common ImGuiStyleVar values

`ImGuiStyleVar_WindowPadding` (ImVec2), `ImGuiStyleVar_WindowRounding` (float), `ImGuiStyleVar_FramePadding` (ImVec2), `ImGuiStyleVar_FrameRounding` (float), `ImGuiStyleVar_ItemSpacing` (ImVec2), `ImGuiStyleVar_IndentSpacing` (float), `ImGuiStyleVar_CellPadding` (ImVec2).

### Modifying style directly

```cpp
ImGuiStyle& style = ImGui::GetStyle();
style.WindowRounding = 5.0f;
style.FrameRounding = 3.0f;
style.Colors[ImGuiCol_WindowBg] = ImVec4(0.1f, 0.1f, 0.1f, 1.0f);
```

### Built-in themes

```cpp
ImGui::StyleColorsDark();
ImGui::StyleColorsLight();
ImGui::StyleColorsClassic();
```

---

## 17. Fonts

### Default font

If no fonts are loaded, ImGui uses an embedded default font. No code needed.

### Loading a TTF from disk

```cpp
ImGuiIO& io = ImGui::GetIO();
ImFont* font = io.Fonts->AddFontFromFileTTF("/path/to/font.ttf", 18.0f);
IM_ASSERT(font != nullptr);
```

The `size_pixels` parameter (18.0f above) can be 0.0f to use the atlas default size.

### Multiple fonts

```cpp
ImFont* font_default = io.Fonts->AddFontDefault();
ImFont* font_large = io.Fonts->AddFontFromFileTTF("Roboto-Medium.ttf", 24.0f);
ImFont* font_mono = io.Fonts->AddFontFromFileTTF("Cousine-Regular.ttf", 16.0f);
```

Using a specific font:

```cpp
ImGui::PushFont(font_large, 0.0f);
ImGui::Text("Large text");
ImGui::PopFont();
```

`PushFont(font, font_size)`: pass `nullptr` to keep current font, `0.0f` to keep current size.

### Icon font merging

```cpp
ImFontConfig config;
config.MergeMode = true;
config.GlyphMinAdvanceX = 18.0f;
static const ImWchar icon_ranges[] = { 0xF000, 0xF3FF, 0 };
io.Fonts->AddFontFromFileTTF("fontawesome.ttf", 18.0f, &config, icon_ranges);
```

This merges icon glyphs into the previously added font. The glyph range must be a zero-terminated array of pairs (start, end).

### Embedded fonts

Use `misc/fonts/binary_to_compressed_c.cpp` to convert a TTF to a C array, then load with `AddFontFromMemoryCompressedTTF()`.

### FreeType rasterizer

Define `IMGUI_ENABLE_FREETYPE` in `imconfig.h` and compile `misc/freetype/imgui_freetype.cpp` for higher-quality font rendering.

---

## 18. Key Rules & Pitfalls

1. **Begin/End and Push/Pop must always match.** Every `Begin*()` needs its `End*()`. Every `Push*()` needs its `Pop*()`. Mismatches cause asserts or corruption.

2. **`End()` must be called even when `Begin()` returns false.** The early-out pattern:
   ```cpp
   if (!ImGui::Begin("Win")) { ImGui::End(); return; }
   ```
   However, for `BeginChild`, `BeginTabBar`, `BeginTabItem`, `BeginTable`, `BeginCombo`, `BeginPopup`, `BeginMenu` -- only call their `End*` if the `Begin*` returned true.

3. **ID conflicts in loops.** Use `PushID(i)` / `PopID()` or `##` suffixes when creating widgets in a loop. Without this, all iterations share the same ID.

4. **Use `TextUnformatted()` for literal strings.** `Text()` runs printf formatting -- if your string contains `%`, it will be interpreted. `TextUnformatted` is also faster for large strings.

5. **State lives in your variables.** ImGui is immediate-mode -- it doesn't store widget state. Use `static` locals or struct members to persist values across frames.

6. **`BeginDisabled` / `EndDisabled` for graying out.**
   ```cpp
   ImGui::BeginDisabled(!connected);
   if (ImGui::Button("Send")) DoSend();
   ImGui::EndDisabled();
   ```

7. **Check `BeginTable` return value.** `BeginTable` can return false (e.g., if the table is clipped). Only call `EndTable()` and table functions when it returns true.

8. **Use `ImGuiListClipper` for large lists.** Naively iterating thousands of items kills performance. The clipper only processes visible rows.

9. **`SetItemDefaultFocus()` in combos and modals.** Call it after the currently-selected `Selectable` in a combo, or after the default button in a modal, to ensure keyboard focus is correct.

10. **Style push/pop count.** `PopStyleColor(n)` and `PopStyleVar(n)` accept a count. Always pass the count matching your pushes. Mismatches trigger asserts.
