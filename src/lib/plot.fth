
: scale-y  ( y -- y' )  3 *  ;
: plot-dbx2@  ( index -- value )  dbx2-buf +  c@  scale-y  ;

4 value plot-stretch
\ d#  50 value dbx2-min
d#   0 value dbx2-min
d# 191 value dbx2-max  \ 192 is theoretical max; 191 makes the grid prettier
d#  10 value dbx2-interval

: fr-plot-wh  ( -- width height )  \ in pixels
   #psd 1- plot-stretch *  dbx2-max scale-y  dbx2-min scale-y  -
;

: bin-marker  ( n -- )
   plot-stretch *          ( x-position )
   fr-plot-wh nip d# 31 -  ( x height- )
   vbar                ( )
;

d# 16 constant char-width
: vlabel-x  ( -- x )  screen-width char-width 2* -  ;
: vaxis  ( -- )
   dbx2-interval scale-y  plot0 nip       ( y-step y0 )
   dbx2-max  dbx2-min  do                 ( y-step y )
      vlabel-x over tek-at                ( y-step y )
      i 2/ push-decimal 2 u.r pop-base    ( y-step y )
      over +                              ( y-step y' )
   dbx2-interval +loop                    ( y-step y )
   2drop                                  ( )
;
: hlabel-at  ( xoffset -- x y )  plot0  rot  d# -24  xy+  tek-at  ;

: haxis  ( -- )
   0 hlabel-at ." (Hz)"
   push-decimal
   8 1  do
       i  screen-width 8 / *  char-width 2* -  hlabel-at
       i d# 1000 * 4 u.r
   loop
   pop-base
      
   screen-width char-width 4 * -  hlabel-at ." (dB)"
   cr   \ Put the cursor in a safe place
;

: grid  ( -- )
   clear-plot
   cr ."                                Frequency response"

   magenta set-fg
   \ Vertical grid lines at 1K intervals
   fr-plot-wh  #psd 1- 8 /  plot-stretch *  vgrid  \ Gray grid lines

   \ Horizontal grid lines at  5 dB intervals
   magenta set-fg
   fr-plot-wh  d# 10 scale-y  hgrid
   \ Do haxis last so the cursor is in a safe place for "label"
   vaxis   haxis
   to-vt
;

\ Add a label below the graph
: label  ( "rest of line" -- )
   0 parse  to-tek type cr  to-vt
;
