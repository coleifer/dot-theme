# i3 config file (v4) - {{ name }}
{%- from 'macros.j2' import i3_run -%}
{%- from 'macros.j2' import i3_do -%}

set $mod Mod1
{% set colors = ('black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white') %}
{% for i in range(2) %}{% for j in range(8) %}
set_from_resource ${% if i == 1 %}alt_{% endif %}{{ colors[j] }} color{{ 8 * i + j }} #ffffff{% endfor %}{% endfor %}
set $foreground {{ foreground }}
set $background {{ background }}
set $transparent #00000000

# Font for window titles. ISO 10646 = Unicode
font {{ i3.font }}

# -- i3 helpers --
bindsym $mod+Shift+C restart
bindsym $mod+Shift+R reload
bindsym $mod+Shift+X exit

# Program launchers.
{{ i3_run('Return', 'urxvt') }}
{{ i3_run('d', 'dmenu_run') }}
{{ i3_run('e', 'te') }}
{{ i3_run('E', 'te -g') }}
{{ i3_run('o', 'blurlock') }}

# Gaps.
{{ i3_do('a', 'gaps inner current plus 5') }}
{{ i3_do('z', 'gaps inner current minus 5') }}

# Special keys.
{{ i3_run('XF86AudioRaiseVolume', 'amixer set Master 2%+ unmute', none, false) }}
{{ i3_run('XF86AudioLowerVolume', 'amixer set Master 2%- unmute', none, false) }}
{{ i3_run('XF86AudioMuteVolume', 'amixer set Master toggle', none, false) }}
{{ i3_run('XF86MonBrightnessUp', 'xbacklight -inc 10', none, false) }}
{{ i3_run('XF86MonBrightnessDown', 'xbacklight -dec 10', none, false) }}

# WM commands
{{ i3_do('space', 'focus mode_toggle') }}
{{ i3_do('Shift+space', 'floating toggle') }}
{{ i3_do('Shift+Return', 'fullscreen') }}
{{ i3_do('Q', 'kill') }}

# focus
{{ i3_do('h', 'focus left') }}
{{ i3_do('j', 'focus down') }}
{{ i3_do('k', 'focus up') }}
{{ i3_do('l', 'focus right') }}

# move focused window
{{ i3_do('H', 'move left') }}
{{ i3_do('J', 'move down') }}
{{ i3_do('K', 'move up') }}
{{ i3_do('L', 'move right') }}

{{ i3_do('minus', 'split v') }}
{{ i3_do('backslash', 'split h') }}

# Window display modes.
#bindsym $mod+Shift+S layout stacking
#bindsym $mod+Shift+W layout tabbed
#bindsym $mod+Shift+S layout default

# Scratchpad
{{ i3_do('Shift+plus', 'move scratchpad') }}
{{ i3_do('equal', 'scratchpad show') }}

# alt + click to move windows.
floating_modifier $mod

# -- workspace --

set $ws1 1:<span>1</span>
set $ws2 2:<span>2</span>
set $ws3 3:<span>3</span>
set $ws4 4:<span>4</span>
set $ws5 5:<span>5</span>
set $ws6 6:<span>6</span>
set $ws7 7:<span>7</span>
set $ws8 8:<span>8</span>

# switch to workspace
{% for i in range(1, 9) %}{{ i3_do(i, 'workspace $ws%d' % i) }}
{% endfor %}

# move focused container to workspace
{%- macro _focus_container(key, i) -%}
bindsym $mod+Shift+{{ key }} move container to workspace $ws{{ i }}
{%- endmacro %}
{{ _focus_container('exclam', 1) }}
{{ _focus_container('at', 2) }}
{{ _focus_container('numbersign', 3) }}
{{ _focus_container('dollar', 4) }}
{{ _focus_container('percent', 5) }}
{{ _focus_container('asciicircum', 6) }}
{{ _focus_container('ampersand', 7) }}
{{ _focus_container('asterisk', 8) }}

# Workspace config.
workspace_auto_back_and_forth yes
force_display_urgency_hint 500 ms
default_orientation horizontal

# Window rules
for_window [class="Dmenu"] floating enable
for_window [window_role="pop-up"] floating enable
for_window [window_role="Preferences"] floating enable
for_window [window_role="task_dialog"] floating enable
for_window [window_type="dialog"] floating enable
for_window [window_type="menu"] floating enable

for_window [urgent=latest] focus

mode "resize" {
  bindsym h resize shrink width 50 px or 5 ppt
  bindsym j resize grow height 50 px or 5 ppt
  bindsym k resize shrink height 50 px or 5 ppt
  bindsym l resize grow width 50 px or 5 ppt

  bindsym Shift+H resize shrink width 10 px or 1 ppt
  bindsym Shift+J resize grow height 10 px or 1 ppt
  bindsym Shift+K resize shrink height 10 px or 1 ppt
  bindsym Shift+L resize grow width 10 px or 1 ppt

  bindsym Return mode "default"
  bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

mode "move_win" {
  bindsym h move left 40 px
  bindsym j move down 40 px
  bindsym k move up 40 px
  bindsym l move right 40 px

  bindsym Shift+H move left 10 px
  bindsym Shift+J move down 10 px
  bindsym Shift+K move up 10 px
  bindsym Shift+L move right 10 px

  bindsym Return mode "default"
  bindsym Escape mode "default"
}
bindsym $mod+m mode "move_win"

new_window {{ i3.new_window }}
new_float {{ i3.new_float }}

{% if i3.bar.enabled %}{% set b = i3.bar %}
set $ws_border {{ b.ws.border }}
set $ws_bg {{ b.ws.bg }}
set $ws_fg {{ b.ws.fg }}
set $ws_focus_border {{ b.ws_focus.border }}
set $ws_focus_bg {{ b.ws_focus.bg }}
set $ws_focus_fg {{ b.ws_focus.fg }}

bar {
  status_command {{ b.cmd }}
  mode {{ b.mode }}
  hidden_state hide
  modifier Mod4

  position {{ b.position }}
  tray_padding {{ b.tray_padding }} px
  workspace_buttons yes
  strip_workspace_numbers yes
  binding_mode_indicator no

  # Appearance.
  font pango:{{ b.font.name }} {{ b.font.size }}
  height {{ b.height }}
  {% if b.separator_symbol %}separator_symbol {{ b.separator_symbol }}{% endif %}
  colors {
    background {{ b.bg }}
    statusline {{ b.fg }}
    separator {{ b.separator }}

    # Colors            <border>         <background> <text>
    focused_workspace   $ws_focus_border $ws_focus_bg $ws_focus_fg
    active_workspace    $ws_border       $ws_bg       $ws_fg
    inactive_workspace  $ws_border       $ws_bg       $ws_fg
    urgent_workspace    $ws_border       {{ red }}    $ws_fg
  }
}
{% endif %}

set $background {{ background }}
set $foreground {{ foreground }}
set $border {{ i3.border }}{% if i3.border_transparency %}{{ i3.border_transparency }}{% endif %}
set $border_unfocused {{ i3.border_unfocused }}{% if i3.border_transparency %}{{ i3.border_transparency }}{% endif %}

# colors                border   bg                text        indicator
client.focused          $border  $border           $background $border
client.focused_inactive $border  $border_unfocused $background $border_unfocused
client.unfocused        $border  $border_unfocused $foreground $border_unfocused
client.urgent           $warning $warning          $foreground $warning

{% if i3.gaps -%}
gaps inner {{ i3.gaps.inner }}
gaps outer {{ i3.gaps.outer }}
{%- endif %}

# Startup programs.
exec --no-startup-id xrdb -merge ~/.Xresources
