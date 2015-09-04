\ linux framebuffer on raspberry pi

: l@+  dup l@ swap la1+  ;

-1 value console-fd

\ from <linux/vt.h>
$5606 constant vt_activate
$5607 constant vt_waitactive

: open-console ( -- )
   console-fd -1 <>  if exit then
   " /dev/console" h-open-file  dup 0< abort" Can't open console."
   to console-fd
;

: close-console ( -- )
   console-fd -1 =  if exit then
   console-fd h-close-handle
   -1 to console-fd
;

0 constant fb#
-1 value fb-fd

: fbioget_vscreeninfo
   0 0 0 'F' >ioctl
;

: fbioget_fscreeninfo
   2 0 0 'F' >ioctl
;

#68 constant /finfo
#160 constant /vinfo

/finfo buffer: 'finfo
/vinfo buffer: 'vinfo

: open-framebuffer  ( -- )
   fb-fd -1 <>  if  exit  then
   fb# " /dev/fb%d" sprintf
   h-open-file dup 0<  abort" Can't open framebuffer device."
   to fb-fd
;

: get-vinfo  ( -- adr len )
   'vinfo fbioget_vscreeninfo fb-fd  ioctl  ?posix-err
   'vinfo /vinfo
;

: vinfo>width  ( adr len -- adr len width )
   over l@
;
: vinfo>height  ( adr len -- adr len height )
   over la1+ l@
;
: vinfo>bpp  ( adr len -- adr len bpp )
   over /l 6 * + l@
;

: finfo>/line  ( adr len -- adr len line-len )
   over /l #11 * + l@
;

: get-finfo  ( -- adr len )
   'finfo fbioget_fscreeninfo fb-fd  ioctl  ?posix-err
   'finfo /finfo
;

-1 value 'fb
-1 value /fb

0 value width
0 value height
0 value bpp
0 value /scanline

: map-framebuffer  ( -- )
   fb-fd -1 =  if  open-framebuffer  then
   'fb -1 <>  if  exit  then

   get-vinfo
   vinfo>width to width
   vinfo>height to height
   vinfo>bpp 8 / to bpp
   2drop

   get-finfo
   finfo>/line to /scanline
   2drop

   height /scanline * to /fb
   0 /fb fb-fd mmap to 'fb
   'fb true =  if  'fb ?posix-err  then
;

: unmap-framebuffer  ( -- )
   'fb -1 =  if  exit  then
   'fb /fb munmap ?posix-err
   -1 to 'fb
   -1 to /fb
;

: close-framebuffer  ( -- )
   fb-fd -1 =  if  exit  then
   fb-fd h-close-handle
   -1 to fb-fd
;

: test-framebuffer ( -- )
   map-framebuffer
   'fb /fb bounds do
      #31 i w!
   2 +loop
   unmap-framebuffer
;

: dump-framebuffer-info ( -- )
   open-framebuffer
   ." Fixed framebuffer info:" cr
   get-finfo dump cr
   ." Variable framebuffer info:" cr
   get-vinfo dump cr
   close-framebuffer
;

: chvt  ( vt# -- )
   open-console

   dup vt_activate console-fd ioctl drop
   vt_waitactive   console-fd ioctl drop

   close-console
;

\ The following is a pastiche of ofw/gui/mouse.fth and ofw/termemu/fb8.fth specific to
\ a 16bpp 5-6-5 framebuffer as found on Raspberry Pi.

\ necessary defines for including ofw files.
: copyright: [compile] \ ;

\ Indices into a color table?
0 value background-color
0 value foreground-color

\ from rectangle16.fth
: 565-rectangle-setup  ( x y w h -- w fbadr h )
   2swap  /scanline * 'fb +   ( w h x line-adr )
   swap bpp * +               ( w h fbadr )
   swap                       ( w fbadr h )
;

: draw-rectangle  ( adr x y w h -- )
   565-rectangle-setup  0  ?do             ( adr w fbadr )
\     3dup swap                            ( adr w fbadr  adr fbadr w )
      2 pick over 3 pick                   ( adr w fbadr  adr fbadr w )
      /w* move                             ( adr w fbadr )
      >r  tuck wa+ swap  r>                ( adr' w fbadr )
      /scanline +                          ( adr' w fbadr' )
   loop                                    ( adr' w fbadr' )
   3drop
;
: read-rectangle  ( adr x y w h -- )
   565-rectangle-setup 0  ?do              ( adr w fbadr )
\     3dup -rot                            ( adr w fbadr  fbadr adr w )
      2dup 4 pick rot                      ( adr w fbadr  fbadr adr w )
      /w* move                             ( adr w fbadr )
      >r  tuck wa+ swap  r>                ( adr' w fbadr )
      /scanline +                          ( adr' w fbadr' )
   loop                                    ( adr' w fbadr' )
   3drop
;

\ from fb16.fth
: rgb>565  ( r g b -- w )
   3 rshift
   swap 2 rshift  5 lshift or
   swap 3 rshift  d# 11 lshift or
;


\ from ofw graphics.fth
0 constant black
4 constant red
2 constant green
1 constant blue
7 constant gray
h# f constant white

h# ff h# ff h# ff rgb>565 value background
0     0     h# 80 rgb>565 value selected-color
h# ff h# ff h# ff rgb>565 value ready-color

defer pointer-cursor?  ' false to pointer-cursor?

\ Current mouse cursor position

0 value xpos  0 value ypos

d# 18 constant cursor-w
d# 31 constant cursor-h

create white-bits
binary
   11000000000000000000000000000000 ,
   11100000000000000000000000000000 ,
   11011000000000000000000000000000 ,
   11001100000000000000000000000000 ,
   11000110000000000000000000000000 ,
   11000011000000000000000000000000 ,
   11000001100000000000000000000000 ,
   11000000110000000000000000000000 ,
   11000000011000000000000000000000 ,
   11000000001100000000000000000000 ,
   11000000000110000000000000000000 ,
   11000000000011000000000000000000 ,
   11000000000001100000000000000000 ,
   11000000000000110000000000000000 ,
   11000000000000011000000000000000 ,
   11000000000000001100000000000000 ,
   11000000000111111000000000000000 ,
   11000000000011000000000000000000 ,
   11000110000011000000000000000000 ,
   11001110000001100000000000000000 ,
   11010011000001100000000000000000 ,
   11100011000000110000000000000000 ,
   00000001100000110000000000000000 ,
   00000001100000011000000000000000 ,
   00000000110000011000000000000000 ,
   00000000110000001100000000000000 ,
   00000000011000001100000000000000 ,
   00000000011000001100000000000000 ,
   00000000001100001100000000000000 ,
   00000000000111111000000000000000 ,
   00000000000111110000000000000000 ,
create black-bits
   00000000000000000000000000000000 ,
   00000000000000000000000000000000 ,
   00100000000000000000000000000000 ,
   00110000000000000000000000000000 ,
   00111000000000000000000000000000 ,
   00111100000000000000000000000000 ,
   00111110000000000000000000000000 ,
   00111111000000000000000000000000 ,
   00111111100000000000000000000000 ,
   00111111110000000000000000000000 ,
   00111111111000000000000000000000 ,
   00111111111100000000000000000000 ,
   00111111111110000000000000000000 ,
   00111111111111000000000000000000 ,
   00111111111111100000000000000000 ,
   00111111111111110000000000000000 ,
   00111111111000000000000000000000 ,
   00111111111100000000000000000000 ,
   00111001111100000000000000000000 ,
   00110001111110000000000000000000 ,
   00100000111110000000000000000000 ,
   00000000111111000000000000000000 ,
   00000000011111000000000000000000 ,
   00000000011111100000000000000000 ,
   00000000001111100000000000000000 ,
   00000000001111110000000000000000 ,
   00000000000111110000000000000000 ,
   00000000000111110000000000000000 ,
   00000000000011110000000000000000 ,
   00000000000000000000000000000000 ,
   00000000000000000000000000000000 ,
hex

: arrow-cursor  ( -- 'fg 'bg w h )
   black-bits white-bits
   cursor-w  cursor-h
;

0 value hardware-cursor?

0 value /rect
0 value old-rect
0 value new-rect

: pix*
   /w*
;

: alloc-pixels  ( pixels -- adr )
  pix* allocate abort" Couldn't allocate memory."
;

: alloc-mouse-cursor  ( -- )
   false to hardware-cursor?
   cursor-w cursor-h *  pix*  to /rect
   cursor-w cursor-h *  alloc-pixels to old-rect
   cursor-w cursor-h *  alloc-pixels to new-rect
;

: fb16-merge  ( color bits dst-adr width -- )
   /w*  bounds  ?do              ( color mask )
      dup h# 80000000 and  if    ( color mask )
         over i w!               ( color mask )
      then                       ( color mask )
      2*                         ( color mask' )
   /w +loop                      ( color mask )
   2drop                         ( )
;

: merge-rect-565  ( color mask-adr dst-adr width height -- )
   0  ?do                          ( color mask-adr rect-adr width )
      2over @  2over  fb16-merge   ( color mask-adr rect-adr width )
      rot na1+ -rot                ( color mask-adr' rect-adr width )
      tuck wa+  swap               ( color mask-adr rect-adr' width )
   loop
   4drop
;

: merge-cursor  ( -- )
   background  white-bits new-rect cursor-w cursor-h merge-rect-565
   black       black-bits new-rect cursor-w cursor-h merge-rect-565
;

: put-cursor  ( x y adr -- )
   -rot  cursor-w cursor-h  draw-rectangle
;

: remove-mouse-cursor  ( -- )
\   pointer-cursor? 0=  if  exit  then
\   hardware-cursor?  if  " cursor-off" $call-screen  exit  then
   xpos ypos  old-rect  put-cursor
;

: draw-mouse-cursor  ( -- )
\   pointer-cursor? 0=  if  exit  then
\   hardware-cursor?  if
\      xpos ypos " cursor-xy!" $call-screen
\      exit
\   then
   xpos ypos 2dup old-rect -rot         ( x y adr x y )
   cursor-w cursor-h  read-rectangle    ( x y )
   old-rect  new-rect /rect move        ( x y )
   merge-cursor                         ( x y )
   new-rect  put-cursor
;

: update-mouse-pos ( -- )
  xpos #10 * ypos +
  case
     #1100 of  #200 to xpos  endof
     #2100 of  #200 to ypos  endof
     #2200 of  #100 to xpos  endof
     #1200 of  #100 to ypos  endof
     ( default ) #100 to xpos #100 to ypos
   endcase
;
: key-move-mouse-cursor ( -- )
   ." Press a key to move the cursor." cr
   0 5 do
      i .d ."  keys left." cr
      begin  #10 ms key?  until  key drop
      remove-mouse-cursor
      update-mouse-pos
      draw-mouse-cursor
   -1 +loop
;
: test-mouse ( -- )
   ." allocating buffers." cr
   alloc-mouse-cursor
   ." Opening framebuffer." cr
   map-framebuffer
   ." Placing cursor!" cr
   #100 to xpos #100 to ypos
   draw-mouse-cursor
   key-move-mouse-cursor
   remove-mouse-cursor
;

: clamp  ( n min max - m )  rot min max  ;
: wclamp ( x - x' )  0  width cursor-w - clamp  ;
: hclamp ( y - y' )  0 height cursor-h - clamp  ;

\ Apply the specified delta to the mouse cursor, clipping to the screen.
: move-cursor ( y x -- )
   remove-mouse-cursor
   xpos + wclamp  to xpos
   ypos + hclamp  to ypos
   draw-mouse-cursor
;
