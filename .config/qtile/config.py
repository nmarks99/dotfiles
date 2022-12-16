# xinput set-prop 10 325 1 # enable natural scrolling
# xinput set-prop 10 346 1 # enable tapping

from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
#  from qtile_extras.widget.decorations import PowerLineDecoration, RectDecoration
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
POLYBAR_THEME = "forest"

desktop_wallpaper = "/usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png"
lockscreen_wallapaper_path = "~/Pictures/wallpaper/catpuccin/sound.png"

GAP_SIZE = 5


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
    #  Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    Key([mod], "space", lazy.spawn("rofi -show drun"), desc="Launch Rofi"),
    Key([mod], "b", lazy.spawn(browser), desc="Launch Firefox"),
    Key([mod,"shift"], "s", lazy.spawn("screenshot.py"), desc="Screenshot"),
    Key([mod,"mod1"], "i", lazy.spawn("autorandr -c"), desc="Screenshot"),
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    
    Key([], "XF86AudioLowerVolume",
        lazy.spawn("amixer sset Master 2%-"),
        desc="Lower Volume by 5%"
    ),
    Key([], "XF86AudioRaiseVolume",
        lazy.spawn("amixer sset Master 2%+"),
        desc="Raise Volume by 5%"
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



#################
#### Groups #####
#################

groups = [Group(i) for i in "12345"]
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
        ]
    )



#################
#### Layouts ####
#################

layouts = [
    layout.Columns(
        border_normal= catpuccin["base"],
        border_focus = catpuccin["peach"],
        border_focus_stack = catpuccin["lavender"],
        border_width=2,
        margin = GAP_SIZE
    ),
    layout.Max(
        margin = GAP_SIZE
    ),
]



#########################
#### Widgets/Screens ####
#########################

# Decorations
#  arrow_right = {
    #  "decorations": [PowerLineDecoration(path="arrow_right")]
#  }
#
#  arrow_left = {
    #  "decorations": [PowerLineDecoration(path="arrow_left")]
#  }
#
#  rounded_right = {
    #  "decorations": [PowerLineDecoration(path="rounded_right")]
#  }
#
#  rounded_left = {
    #  "decorations": [PowerLineDecoration(path="rounded_left")]
#  }
#
#  slash_back = {
    #  "decorations": [PowerLineDecoration(path="back_slash")]
#  }
#
#  slash_forward = {
    #  "decorations": [PowerLineDecoration(path="forward_slash")]
#  }
#
#  border = {
    #  "decorations": [RectDecoration(
        #  colour=mauve,
        #  radius=10,
        #  filled=True,
        #  padding_y=4,
        #  group=True
    #  )]
#  }

widget_defaults = dict(
    font="JetBrainsMono",
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()


#  def widgets_list():
    #  widgets_list = [
        #  widget.Spacer(
            #  background = catpuccin["crust"],
            #  length = 8
        #  ),
    #  ]


screens = [
    Screen(
        wallpaper=desktop_wallpaper,
        wallpaper_mode="fill",
        #  bottom=bar.Bar(
            #  [
                #  widget.CurrentLayoutIcon(),
                #  widget.GroupBox(
                    #  disable_drag = True,
#
                #  ),
                #  widget.Systray(),
                #  widget.Clock(format="%m-%d-%Y\t%a %I:%M %p"),
                #  widget.Battery(
                    #  format="Battery: {percent:2.0%}",
                    #  font = "Roboto, Regular",
                    #  forefround = "#ff0000",
                    #  fontsize = 12,
                    #  passing = 0
                #  )
            #  ],
            #  24,
            #  background = catpuccin["mantle"],
            #  opacity = 0.55,
            #  margin = GAP_SIZE
        #  ),
    ),
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
    border_focus = catpuccin["peach"],
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
### Startup ###
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
    subprocess.call(["polybar_launch.sh",f"--{POLYBAR_THEME}"])


#  @hook.subscribe.startup
#  def dbus_register():
    #  id = os.environ.get('DESKTOP_AUTOSTART_ID')
    #  if not id:
        #  return
    #  subprocess.Popen(['dbus-send',
                      #  '--session',
                      #  '--print-reply',
                      #  '--dest=org.gnome.SessionManager',
                      #  '/org/gnome/SessionManager',
                      #  'org.gnome.SessionManager.RegisterClient',
                      #  'string:qtile',
                      #  'string:' + id])
