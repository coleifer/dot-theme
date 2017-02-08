## .theme

This repo contains the script I use to render my templated dotfiles, as well as
a helper script for editing theme configurations.

The way it works is you have a base config (`config.yaml`), which contains some
global settings and defaults. Each theme may override or add to the base
config, specifying different colors for titlebars, different fonts, etc.

The `ta` script is used for manaaging themes, and `te` is used for editing
theme configs.

### Sample `config.yaml`

This is a sample global config file. Note that the list of templates to be
rendered is included under the `templates` key, along with `hooks` to be run
after the theme is set.

The values of these settings are then referenced by the templates, which use
the values from the configuration to populate your dotfiles.

```yaml
settings:
  active: $red
  highlight: $cyan
  inactive: $alt_black
  transparency: 95
  window_border: $black
  window_title: $alt_black
  font:
    fallbacks:
      - "-*-icons-medium-*-*-*-15-*-*-*-*-*-*-*"
    bar: Roboto:style=Light
    bar_size: 10
    default: Roboto Light
    size: 10
    term: xft:Tamsyn:pixelsize=15
    term_b: xft:Tamsyn:pixelsize=15
    term_i: xft:Tamsyn:pixelsize=15
  i3:
    bar:
      bg: $panel
      cmd: i3status
      enabled: true
      fg: $text
      font:
        name: "Terminus, Icons"
        size: "12px"
      height: $bar_height
      mode: dock
      position: top
      separator: $wall
      separator_symbol: null
      tray_padding: 4
      ws:
        bg: $wall
        border: $active
        fg: $active
      ws_focus:
        bg: $active
        border: $active
        fg: $wall
    border: $active
    border_transparency: false
    border_unfocused: $title
    font: $font.term
    gaps:
      inner: 20
      outer: 5
    new_float: "pixel 4"
    new_window: "pixel 2"
  openbox:
    active:
      border: $border
      button: $red
      button_brightness: 0
      title: $title
      label: $text
      separator: $active
      label_brightness: 0
    border: 1
    client:
      color: $panel
      padding:
        h: 0
        w: 0
    desktops:
      - web
      - code
      - etc
    font:
      name: $font.default
      size: $font.size
    gap_size: 24
    gap_size_outer: 36
    inactive:
      border: $border
      button: $red
      button_brightness: 0
      title: $title
      label: $text
      separator: $inactive
      label_brightness: 0
    justify: right
    margin_multiplier: 2
    monitor: 1
    padding:
      h: 9
      w: 13
    panel_items: LC
  screen:
    h: 1080
    w: 1920
  terminal:
    border:
      external: 0
      internal: 24
    highlightColor: $highlight
    highlightTextColor: $white
    letter_space: 0
    line_space: 3
  vim:
    colors:
      - miromiro
templates:
  i3.tpl: i3.conf
  openbox-rc.xml: rc.xml
  openbox-themerc: themerc
  shell_colors: shell_colors
  xresources.tpl: Xresources
hooks:
  set:
    - xrdb -merge ~/.Xresources
    - echo "reload your window-manager here!"
  add: []
```

### Sample theme

An individual theme's configuration consists of a subset of the settings
defined in the global `config.yaml`. Themes can only override settings
underneath the `settings` key of the config file (and thus cannot override
things like hooks or template lists).

```yaml
active: $cyan
alt_black: '#4b4e6d'
alt_blue: $blue
alt_cyan: $cyan
alt_green: $green
alt_magenta: $magenta
alt_red: $red
alt_white: '#fefffe'
alt_yellow: '#c9cebd'
background: '#222222'
bar_height: 26
black: '#222222'
blue: '#b0d0d3'
border: '#292929'
cyan: '#1c6b7c'
foreground: '#fefffe'
green: '#84dcc6'
magenta: '#696d99'
panel: $alt_black
red: '#c08497'
white: '#95a3b3'
yellow: '#b2bcaa'
font:
  bar: Work Sans
  default: Work Sans Light
  term: xft:Iosevka Term:size=10
  term_b: xft:Iosevka Term:size=10
  term_i: xft:Iosevka Term:size=10:style=Italic
i3:
  bar:
    font:
      name: Roboto, Icons
    ws:
      bg: $i3.bar.bg
      border: $white
      fg: $white
    ws_focus:
      bg: $i3.bar.bg
      border: $text
      fg: $text
  border: $active
  border_unfocused: $title
openbox:
  active:
    separator: $text
    title: $cyan
  font:
    size: 8
  gap_size: 40
  gap_size_outer: -20
  inactive:
    separator: $text
  padding:
    h: 10
  panel_items: ''
```

### Typical usage

To create a new theme from an `.Xresources` file containing color defintions,
you can run:

```
$ ta add my-new-theme ~/path/to/cool-colors.xresources
```

To set the theme to the new theme:

```
$ ta set my-new-theme
```

To list themes:

```
$ ta ls
```

To edit the theme's config:

```
$ te
```

To edit the global config:

```
$ te -g
```
