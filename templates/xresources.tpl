! Xft settings
Xft.dpi: {{ fontconfig.dpi|default(96, true) }}
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hinting: 1
Xft.hintstyle: hintslight
Xft.antialias: 1
Xft.rgba: rgb

! urxvt settings
URxvt.termName: rxvt-unicode
URxvt.iconFile: /usr/share/icons/acyl/scalable/apps/terminal.svg

! Allow escape sequences that echo arbitrary strings, including things like the
! icon name, locale, etc. This enables the following escape sequences:
! display-answer, locale, findfont, icon label, and window title.
URxvt.insecure: true

! disable picture mode.
URxvt.iso14755: false
URxvt.iso14755_2: false

URxvt.depth: 32
URxvt.geometry: {{ terminal.geometry }}
{% if terminal.fade %}
URxvt.fading: {{ terminal.fade }}{% if terminal.fade_color %}
URxvt.fadeColor: {{ terminal.fade_color }}{% endif %}
{% endif %}

! When receiving lots of lines of text, this instructs URxvt to only scroll
! once the whole screen-height of lines has been read, resulting in fewer
! updates while still displaying every line received.
!URxvt.jumpScroll: true

! Alternatively, using skipScroll will optimize for speed rather than ensuring
! all lines are printed. This is a good idea when using xft.
URxvt.skipScroll: true

! No scrollback buffer or automatic scrolling.
URxvt.scrollTtyOutput: false
URxvt.scrollTtyKeypress: true
URxvt.scrollWithBuffer: false

! Urgent set on bell, but do not use visual bell -- it flashes the terminal
! briefly white and isnt generally that useful.
URxvt.urgentOnBell: true
URxvt.visualBell: false

! Perl extensions.
URxvt.perl-lib: /usr/lib/urxvt/perl/:{{ home }}/.config/urxvt/perl/
URxvt.perl-ext-common: default,tabbedex,clipboard,matcher
URxvt.matcher.button: 3
URxvt.url-launcher: xdg-open

URxvt.tabbed.tabbar-fg: {{ terminal.tabs.bar_fg }}
URxvt.tabbed.tabbar-bg: {{ terminal.tabs.bar_bg }}
URxvt.tabbed.tab-fg: {{ terminal.tabs.fg }}
URxvt.tabbed.tab-bg: {{ terminal.tabs.bg }}
URxvt.tabbed.new-button: false
URxvt.tabbed.autohide: true

URxvt.clipboard.copycmd: xclip
URxvt.clipboard.pastecmd: xclip -o

URxvt.keysym.Shift-Control-C: perl:clipboard:copy
URxvt.keysym.Shift-Control-V: perl:clipboard:paste

!! Scroll
URxvt.scrollBar: false
URxvt.scrollBar_right:true
URxvt.scrollBar_floating:false
URxvt.scrollstyle:plain

!! Mouse
URxvt.pointerBlank: true

! Disable scrollback buffer for secondary screens (e.g. less).
! (unfortunately need a patch for mouse-wheel support)
!URxvt.secondaryScreen: 1
!URxvt.secondaryScroll: 0
{% if font.term.startswith('xft') %}URxvt.buffered: true  ! double buffer when using Xft{% endif %}
URxvt.hold: false  ! Kill window when shell exits.

! History
URxvt.saveLines: 32767

! Dump buffer to a timestamped file. Activate using PrntScrn (+Ctrl, +Shift)
URxvt.print-pipe: cat > $(mktemp -p "$HOME/tmp" urxvt-$(date +%-b%-d\-%-I%M).XXXXXX)

! Appearance.
URxvt.font: {{ font.term }}{% if font.fallbacks %}{% for extra in font.fallbacks %},{{ extra }}{% endfor %}{% endif %}
URxvt.boldFont: {{ font.term_b|default(font.term, true) }}
URxvt.italicFont: {{ font.term_i|default(font.term, true) }}

URxvt.background: {% if transparency %}[{{ transparency }}]{% endif %}{{ background }}
URxvt.internalBorder: {{ terminal.border.internal }}
URxvt.externalBorder: {{ terminal.border.external }}
URxvt.lineSpace: {{ terminal.line_space }}{# Sane default? #}
URxvt.letterSpace: {{ terminal.letter_space|default(0) }}
URxvt.underlineColor: {{ terminal.underlineColor|default(highlight, true) }}
URxvt.colorBD: {{ terminal.colorBD|default(active, true) }}
URxvt.colorIT: {{ terminal.colorIT|default(highlight, true) }}

! Use window titlebar and label colors for selection.
URxvt.highlightColor: {{ terminal.highlightColor|default(openbox.active.title, true) }}
URxvt.highlightTextColor: {{ terminal.highlightTextColor|default(openbox.active.label, true) }}

! Unbind alt+p
URxvt.keysym.A-p:           command:\000

! Bind ctrl+s to save a printout of the terminal window.
URxvt.keysym.C-s:           command:\033[0i

! {{ name }} colors
*background: {{ background }}
*foreground: {{ foreground }}
*cursorColor: {{ cursor|default(white, true) }}
! black
*color0: {{ black }}
*color8: {{ alt_black }}
! red
*color1: {{ red }}
*color9: {{ alt_red }}
! green
*color2: {{ green }}
*color10: {{ alt_green }}
! yellow
*color3: {{ yellow }}
*color11: {{ alt_yellow }}
! blue
*color4: {{ blue }}
*color12: {{ alt_blue }}
! magenta
*color5: {{ magenta }}
*color13: {{ alt_magenta }}
! cyan
*color6: {{ cyan }}
*color14: {{ alt_cyan }}
! white
*color7: {{ white }}
*color15: {{ alt_white }}
! underline when default
*colorIT: {% if italics %}{{ italics }}{% else %}{{ blue }}{% endif %}
*colorUL: {% if underline %}{{ underline }}{% else %}{{ cyan }}{% endif %}

! Set font for xterm as well.
xterm*font: {{ font.term }}

! Applications
dzen2.font: {{ font.term }}
dzen2.foreground: {{ foreground }}
dzen2.background: {{ background }}

Xcursor.theme: DMZ (White)

! vim: set ft=xdefaults:
