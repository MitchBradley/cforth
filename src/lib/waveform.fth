7 value wave-scale   \ h# ffff wave-scale >>  must be less than  screen-height

\ : plot0  ( -- x0 y0 )  5 5  ;
: plot0  ( -- x0 y0 )  0 d# 180  ;

variable ylim  variable ymin
1 value stretch
: clip-y  ( value -- value' )  ymin @ -  0 max  ylim @ min  ;
: lineplot  ( xt xmin xmax xscale ymin ymax -- )
   over - ylim !  ymin !  to stretch  ( xt xmin xmax )
   over 3 pick execute clip-y  ( xt xmin xmax y-at-xmin )
   plot0 2 pick +  moveto      ( xt xmin xmax y-at-xmin )
   -rot  swap 1+  ?do          ( xt last )
      i 2 pick execute clip-y  ( xt last value )
      tuck swap -              ( xt value delta )
      stretch swap rline       ( xt value )
   loop                        ( xt last )
   2drop                       ( )
   to-vt
;

screen-width value wave-width
screen-height 2/ 1-  dup constant max-y  negate constant min-y

: @y  ( adr -- adr' y )
   dup wa1+  swap <w@    ( adr' y-unscaled )
   wave-scale >>a        ( adr' y-scaled )
   max-y min  min-y max  ( adr' y-clipped )
;

: draw-wave  ( adr -- )  \ adr points to array of shorts
   @y                   ( adr' y )
   dup screen-height 2/ +  0 swap  moveto  ( adr last )
   wave-width  0  do    ( adr last )
      >r  @y            ( adr' this r: last )
      dup r> -          ( adr this distance )
      1 swap rline      ( adr last' )
   loop                 ( adr last )
   2drop
;
: waveform  ( adr -- )  tek-page  draw-wave  to-vt  ;

: xy+  ( x1 y1 x2 y2 -- x3 y3 )  rot + >r + r>  ;

: vbar  ( x-offset height -- )
  >r >r                      ( r: height x-offset )
  plot0  r> 0  xy+  moveto   ( r: height )
  0 r>  rline                ( )
;

: hbar  ( y-offset width -- )
   >r >r                     ( r: width y-offset )
   plot0  0 r>  xy+  moveto  ( r: width )
   r> 0  rline
;
: vgrid  ( width height interval -- )
   rot  0  ?do                   ( height interval )
      i 2 pick vbar              ( height interval )
   dup +loop                     ( height interval )
   2drop                         ( )
;
: hgrid  ( width height interval -- )
   swap  0  ?do                ( width interval )
      i 2 pick  hbar           ( width interval )
   dup +loop                   ( width interval )
   2drop                       ( )
;

