
# Scroll direction and tap to click was messed up for some reason when I first
# started qtile so to fix it I adjusted the settings with xinput
# xinput list-prop 10, xinput setprop 10 325 1

from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
import subprocess

#  Key([], 'XF86MonBrightnessUp',   lazy.function(backlight('inc'))),
#  Key([], 'XF86MonBrightnessDown', lazy.function(backlight('dec'))),
#
@hook.subscribe.startup_once
def autostart():
    '''
    This function runs upon starting Qtile the first time
    '''
    autostart_script_path = "/home/nick/.config/qtile/autostart.sh"
    subprocess.Popen([autostart_script_path])


mod = "mod4"
wallpaper_path = "~/Pictures/wallpaper/desert_night.jpg"
terminal = "kitty"

keys = [

    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
   
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    
    Key([mod], "space", lazy.spawn("launcher.sh"), desc="Launch Rofi"),
    Key([mod], "b", lazy.spawn("firefox"), desc="Launch Firefox"),
    Key([],
        "XF86AudioLowerVolume",
        lazy.spawn("amixer sset Master 5%-"),
        lazy.spawn("amixer sset Headphone 5%-"),
        lazy.spawn("amixer sset 'PGA1.0 1 Master' 5%-"),
        lazy.spawn("amixer sset 'PGA3.0 3 Master' 5%-"),
        lazy.spawn("amixer sset 'PGA7.0 7 Master' 5%-"),
        lazy.spawn("amixer sset 'PGA8.0 8 Master' 5%-"),
        lazy.spawn("amixer sset 'PGA9.0 9 Master' 5%-"),
        desc="Lower Volume by 5%"
    ),
    Key([],
        "XF86AudioRaiseVolume",
        lazy.spawn("amixer sset Master 5%+"),
        lazy.spawn("amixer sset 'PGA1.0 1 Master' 5%+"),
        lazy.spawn("amixer sset 'PGA3.0 3 Master' 5%+"),
        lazy.spawn("amixer sset 'PGA7.0 7 Master' 5%+"),
        lazy.spawn("amixer sset 'PGA8.0 8 Master' 5%+"),
        lazy.spawn("amixer sset 'PGA9.0 9 Master' 5%+"),
        lazy.spawn("amixer sset Headphone 5%+"),
        desc="Raise Volume by 5%"
    )

    #  Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl s 10%+"), desc='brightness up'),
    #  Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl s 10%-"), desc='brightness down')
]

groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend(
        [
            # mod1 + letter of group = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod1 + shift + letter of group = switch to & move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc="Switch to & move focused window to group {}".format(i.name),
            ),
            # Or, use below if you prefer not to switch to that group.
            # # mod1 + shift + letter of group = move focused window to group
            # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
            #     desc="move focused window to group {}".format(i.name)),
        ]
    )

layouts = [
    layout.Columns(
        border_focus_stack=["#0af2ee", "#0af2ee"],
        border_width=4,
        margin = 6
    ),
    layout.Max(
        margin = 6
    ),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font="sans",
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        wallpaper=wallpaper_path,
        bottom=bar.Bar(
            [
                widget.CurrentLayout(),
                widget.GroupBox(),
                #  widget.Prompt(),
                widget.WindowName(),
                widget.Chord(
                    chords_colors={
                        "launch": ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),
                #  widget.TextBox("default config", name="default"),
                #  widget.TextBox("Press &lt;M-r&gt; to spawn", foreground="#d75f5f"),
                # NB Systray is incompatible with Wayland, consider using StatusNotifier instead
                # widget.StatusNotifier(),
                widget.Systray(),
                widget.Clock(format="%m-%d-%Y\t%a %I:%M %p"),
                #  widget.QuickExit(),
            ],
            24,
            # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

wmname = "qtile"
