\ TeraTERM must be in AutoSwitch mode - Setup>Terminal - for to-tek and to-vt
\ to work.  Otherwise you have to invoke the Tek emulator manually (Control>Open TEK)
\ and switch back and forth with the mouse
: to-tek  ( -- )  h# 1f emit  ;
: to-vt  ( -- )  h# 1b emit  [char] 2 emit  ;

: tek-page  ( -- )  h# 1b emit  h# c emit  ;  \ Clear screen

: tek-alpha  ( -- )  h# 1f emit  ;
: tek-plot  ( -- )  h# 1d emit  ;

: component  ( n tag -- )  swap  h# 1f and  or  emit  ;

d# 1024 constant screen-width
d#  780 constant screen-height

: tek-move  ( x y -- )
   \ Clip the xy components so they can be represented in the
   \ 10 bit width of the encoding protocol.
   d# 1023 min                          ( x y' )
   dup 5 rshift  h# 20 component        ( x y ) \ hi-y
   h# 60 component                      ( x )   \ lo-y
   d# 1023 min                          ( x' )
   dup 5 rshift  h# 20 component        ( x )   \ hi-x
   h# 40 component                      ( )     \ lo-x
;
\ Here's how line drawing works.  Starting in alphanumeric mode:
\ Execute tek-plot to get into line drawing mode.  The pen is
\ now up, so the first line is invisible, i.e. it's a move.
\ The pen automatically goes down after the first move, and
\ subsequent moves draw lines.  tek-alpha gets you out of
\ drawing mode.

: tek-box  ( -- )
   to-tek
   tek-plot
   10 10 tek-move   \ initial non-drawn move
   40 10 tek-move
   40 60 tek-move
   10 60 tek-move
   10 10 tek-move
   tek-alpha
   to-vt
;

\ PostScript-style line drawing commands

variable cur-x  variable cur-y
: moveto  ( x y -- )  cur-y !  cur-x !  ;
: tek-at  ( x y -- )
   moveto tek-plot     cur-x @ cur-y @ tek-move  tek-alpha
;
: lineto  ( x y -- )
\   to-tek
   tek-plot
   cur-x @ cur-y @ tek-move  ( x y )
   2dup moveto  tek-move     ( )
   tek-alpha
\   to-vt
;
: rline  ( dx dy -- )  swap cur-x @ +  swap cur-y @ +  lineto  ;

: box2  ( -- )
   tek-page
   10 10 moveto
   40 10 lineto
   40 60 lineto
   10 60 lineto
   10 10 lineto
   to-vt
;

alias clear-plot tek-page
0 constant white
1 constant black
2 constant red
3 constant green
4 constant blue
5 constant cyan
6 constant magenta
7 constant yellow
: set-fg  ( n -- )  h# 1b emit ." ML"  h# 30 + emit  ;

0 [if]
\ Incremental plotting mode; not very useful.  Exit with tek-alpha
: tek-turtle  ( -- )  h# 1e emit  ;
: unpen  ( -- )  bl emit  ;
: pen  ( -- )  [char] P emit  ;
: east  ( -- )  [char] A emit  ;
: west  ( -- )  [char] B emit  ;
: north  ( -- )  [char] D emit  ;
: south  ( -- )  [char] H emit  ;
: nw  ( -- )  [char] F emit  ;
: ne  ( -- )  [char] E emit  ;
: sw  ( -- )  [char] J emit  ;
: se  ( -- )  [char] I emit  ;
[then]

