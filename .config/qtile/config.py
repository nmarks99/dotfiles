from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
import datetime
import subprocess
import os
from colors import catpuccin


#################
### Variables ###
#################
mod = "mod4"
terminal = "kitty"
browser = "firefox"
polybar_theme = "forest"

desktop_wallpaper = "/home/nick/Pictures/wallpaper/milky_way.jpg"
lockscreen_wallpaper = "~/Pictures/wallpaper/catpuccin/sound.png"

WINDOW_GAP_SIZE = 5


#################
## Keybindings ##
#################
keys = [

    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key(["mod1"], "Tab", lazy.layout.next(), desc="Move window focus to other window"),
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "space", lazy.spawn("/home/nick/bin/rofi/launcher.sh"), desc="Launch Rofi"),
    Key([mod], "b", lazy.spawn(browser), desc="Launch Firefox"),
    Key([mod,"shift"], "s", lazy.spawn("screenshot.py"), desc="Screenshot"),
    Key([mod,"mod1"], "i", lazy.spawn("autorandr --change"), desc="Automatically change display"),

    Key([mod], "f",
        lazy.window.toggle_floating(),
        desc="Toggle floating",
    ),

    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    
    Key([], "XF86AudioLowerVolume",
        lazy.spawn("amixer -D pulse sset Master 2%-"),
        desc="Lower Volume"
    ),
    Key([], "XF86AudioRaiseVolume",
        lazy.spawn("amixer -D pulse sset Master 2%+"),
        desc="Raise Volume"
    ),
    Key([], "XF86AudioMute",
        lazy.spawn("amixer -D pulse set Master toggle"),
        desc="Toggle mute"
    ),
    Key([], "XF86MonBrightnessUp",
        lazy.spawn("brightnessctl s 2%+"),
        desc='Increase brightness'
    ),
    Key([], "XF86MonBrightnessDown",
        lazy.spawn("brightnessctl s 2%-"),
        desc='Decrease brightness'
    )
]

##############
#### Bar #####
##############

soft_sep = {'linewidth': 2, 'size_percent': 70,
            'foreground': '393939', 'padding': 7}

icon_theme_path = '/usr/share/icons/AwOkenWhite/clear/24x24/status/'
main_bar = bar.Bar(
            [
                widget.GroupBox(),
                widget.Mpris2(background='253253', name='spotify',
                              stop_pause_text='▶', scroll_chars=None,
                              display_metadata=['xesam:title', 'xesam:artist'],
                              objname="org.mpris.MediaPlayer2.spotify"),
                widget.Sep(linewidth=2, size_percent=100, padding=12),
                widget.Prompt(),
                widget.Volume(theme_path=icon_theme_path),
                widget.WindowName(),
                widget.Systray(),
                widget.Sep(**soft_sep),
                widget.BatteryIcon(theme_path=icon_theme_path),
                widget.Battery(foreground='247052', low_percentage=0.20,
                               low_foreground='fa5e5b', update_delay=10,
                               format='{percent:.0%} {hour:d}:{min:02d} '
                                      '{watt:.2}W'),
                widget.Sep(**soft_sep),
                widget.Clock(timezone='Europe/Paris', format='%B %-d, %H:%M'),
            ], 30)


#################
#### Groups #####
#################

groups = [Group(i) for i in "12345"]
for i in groups:
    keys.extend([
        # mod + number of group = switch to group
        Key(
            [mod],
            i.name,
            lazy.group[i.name].toscreen(),
            desc="Switch to group {}".format(i.name),
        ),
        # mod + shift + number of group = switch to & move focused window to group
        Key(
            [mod, "shift"],
            i.name,
            lazy.window.togroup(i.name, switch_group=True),
            desc="Switch to & move focused window to group {}".format(i.name),
        )
    ])



#################
#### Layouts ####
#################

layouts = [
    layout.Columns(
        border_normal= catpuccin["base"],
        border_focus = catpuccin["teal"],
        border_focus_stack = catpuccin["lavender"],
        border_width=1,
        margin = WINDOW_GAP_SIZE
    ),
    layout.Max(
        margin = WINDOW_GAP_SIZE
    )
]


#########################
#### Widgets/Screens ####
#########################

widget_defaults = dict(
    font="JetBrainsMono",
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        wallpaper=desktop_wallpaper,
        wallpaper_mode="fill",

        top=bar.Bar(
            [
                # widget.CurrentLayout(),
                widget.GroupBox(),
                widget.Prompt(),
                widget.Spacer(bar.STRETCH),
                widget.Clock(format="%a %m-%d-%Y"),
                widget.Sep(padding=10),
                widget.Clock(format="%I:%M:%S %p"),
                widget.Spacer(bar.STRETCH),
                widget.Battery(format="󰁺 {percent:2.0%} "),
                widget.Sep(padding=10),
                widget.Wlan(interface="wlp115s0", format=" \t", disconnected_message="󰖪 \t",),
                # widget.QuickExit(),
            ],
            24,
            ),
        )
]


#################
### Floating ####
#################

mouse = [
    Drag([mod], "Button1",
         lazy.window.set_position_floating(),
         start=lazy.window.get_position()
    ),
    Drag([mod], "Button3",
         lazy.window.set_size_floating(),
         start=lazy.window.get_size()
    ),
    Click([mod], "Button2",
          lazy.window.bring_to_front()
    ),
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
    ],
    border_normal= catpuccin["base"],
    border_focus = catpuccin["mauve"],
    border_focus_stack = catpuccin["lavender"]
)


#################
##### Rules #####
#################
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None
wmname = "qtile"


#################
#### Startup ####
#################
@hook.subscribe.startup_once
def autostart_once():
    '''
    This function runs upon starting Qtile the first time
    '''
    autostart_script_path = "/home/nick/.config/qtile/autostart.sh"
    subprocess.Popen([autostart_script_path])

@hook.subscribe.startup
def autostart_always():
    '''
    This function runs every time Qtile is refreshed
    '''
    # restart polybar each time qtile is restarted
    subprocess.call(["polybar_launch.sh",f"--{polybar_theme}"])

