[ifdef] mmp3
\ This value has the same effect as the value below.  The
\ difference is that the SCLK_SOURCE_SELECT field added a
\ low-order bit (bit 29), so the high nibble changed from
\ 2 to 4 even though the field value is still 1.
h# 20001102 value clkdiv  \ Display Clock 1 / 2 -> 56.93 MHz
[else]
h# 40001102 value clkdiv  \ Display Clock 1 / 2 -> 56.93 MHz
[then]
h# 00000700 value pmua-disp-clk-sel  \ PLL1 / 7 -> 113.86 MHz

d#    8 value hsync  \ Sync width
d# 1200 value hdisp  \ Display width
d# 1256 value htotal \ Display + FP + Sync + BP
d#   24 value hbp    \ Back porch

d#    3 value vsync  \ Sync width
d#  900 value vdisp  \ Display width
d#  912 value vtotal \ Display + FP + Sync + BP
d#    5 value vbp    \ Back porch

: hfp  ( -- n )  htotal hdisp -  hsync -  hbp -  ;  \ 24
: vfp  ( -- n )  vtotal vdisp -  vsync -  vbp -  ;  \ 4

0 [if]
3 constant #lanes
3 constant bytes/pixel
d# 24 constant bpp
[else]
2 constant #lanes
2 constant bytes/pixel
d# 16 constant bpp
[then]

: >bytes   ( pixels -- chunks )  bytes/pixel *  ;
: >chunks  ( pixels -- chunks )  >bytes #lanes /  ;

: lcd@  ( offset -- l )  lcd-pa + io@  ;
: lcd!  ( l offset -- )  lcd-pa + io!  ;

: init-lcd  ( -- )
   \ Turn on clocks
\ New: d12bf
   h# 08 pmua-disp-clk-sel + h# 28284c io!
   h# 09 pmua-disp-clk-sel + h# 28284c io!
   h# 19 pmua-disp-clk-sel + h# 28284c io!
   h# 1b pmua-disp-clk-sel + h# 28284c io!
\ New: d12bf h# 282910 io!

   0                  h# 190 lcd!  \ Disable LCD DMA controller
   diagfb-pa           h# f4 lcd!  \ Frame buffer area 0
   0                   h# f8 lcd!  \ Frame buffer area 1
   hdisp bytes/pixel * h# fc lcd!  \ Pitch in bytes

   hdisp vdisp wljoin  dup h# 104 lcd!  dup h# 108 lcd!  h# 118 lcd!  \ size, size after zoom, disp

   htotal >chunks  vtotal wljoin  h# 114 lcd!  \ SPUT_V_H_TOTAL

   htotal >chunks  hdisp -  hbp >chunks -  6 -  ( low )
   hbp >chunks  wljoin  h# 11c lcd!
   
   vfp vbp wljoin  h# 120 lcd!
   h# 2000FF00 h# 194 lcd!  \ DMA CTRL 1 \ New: NOT
\ New: d not 2000000d
   h# 2000000d h# 1b8 lcd!  \ Dumb panel controller - 18 bit RGB666 on LDD[17:0]
\ New: a000a not 01330133
   h# 01330133 h# 13c lcd!  \ Panel VSYNC Pulse Pixel Edge Control
   clkdiv      h# 1a8 lcd!  \ Clock divider
\  h# 08021100 h# 190 lcd!  \ DMA CTRL 0 - enable DMA, 24 bpp mode
  h# 08001100 h# 190 lcd!  \ DMA CTRL 0 - enable DMA, 16 bpp mode
;

: normal-hsv  ( -- )
   \ The brightness range is from ffff (-255) to 00ff (255) - 8 bits sign-extended
   \ 0 is the median value
   h# 0000.4000 h# 1ac lcd!  \ Brightness.contrast  0 is normal brightness, 4000 is 1.0 contrast
   h# 2000.4000 h# 1b0 lcd!  \ Multiplier(1).Saturation(1)
   h# 0000.4000 h# 1b4 lcd!  \ HueSine(0).HueCosine(1)
;
: clear-unused-regs  ( -- )
   0 h# 0c4 lcd!   \ Frame 0 U
   0 h# 0c8 lcd!   \ Frame 0 V
   0 h# 0cc lcd!   \ Frame 0 Command
   0 h# 0d0 lcd!   \ Frame 1 Y
   0 h# 0d4 lcd!   \ Frame 1 U
   0 h# 0d8 lcd!   \ Frame 1 V
   0 h# 0dc lcd!   \ Frame 1 Command
   0 h# 0e4 lcd!   \ U and V pitch
   0 h# 130 lcd!   \ Color key Y
   0 h# 134 lcd!   \ Color key U
   0 h# 138 lcd!   \ Color key V
;

: third  ( a b c -- a b c a )  2 pick  ;

: centered  ( w h -- )
   hdisp third - 2/               ( w h x )    \ X centering offset
   vdisp third - 2/               ( w h x y )  \ Y centering offset
   wljoin h# 0e8 lcd!             ( w h )

   wljoin dup h# 0ec lcd!         ( h.w )  \ Source size
   h# 0f0 lcd!                    ( )      \ Zoomed size
;
: zoomed  ( w h -- )
   0 h# 0e8 lcd!                   ( w h )  \ No offset when zooming
   wljoin h# 0ec lcd!              ( )      \ Source size
   hdisp vdisp wljoin h# 0f0 lcd!  ( )      \ Zoom to fill screen
;

defer placement ' zoomed is placement

: set-video-alpha  ( 0..ff -- )
   8 lshift                ( xx00 )
   h# 194 lcd@             ( xx00 regval )
   h# ff00 invert and      ( xx00 regval' )
   or                      ( regval' )
   h# 194 lcd!             ( )
;

\ 0:RBG565 1:RGB1555 2:RGB888packed 3:RGB888unpacked 4:RGBA888
\ 5:YUV422packed 6:YUV422planar 7:YUV420planar 8:SmartPanelCmd
\ 9:Palette4bpp  A:Palette8bpp  B:RGB888A
: set-video-mode  ( mode -- )
   d# 20 lshift            ( x00000 )
   h# 190 lcd@             ( x00000 regval )
   h# f00000 invert and    ( x00000 regval' )
   or                      ( regval' )
   h# 190 lcd!             ( )
;
: video-on  ( -- )  h# 190 lcd@ 1 or h# 190 lcd!  ;
: video-off  ( -- )  h# 190 lcd@ 1 invert and h# 190 lcd!  ;
: set-video-dma-adr  ( adr -- )  h# 0c0 lcd!  ;

\ Assumes RGB565
: start-video  ( adr w h -- )
   clear-unused-regs  normal-hsv  ( adr w h )
   over 2* h# 0e0 lcd!            ( adr w h )  \ Pitch - width * 2 bytes/pixel
   placement                      ( adr )
   set-video-dma-adr              ( )  \ Video buffer
   0 set-video-mode               ( )  \ RGB565
   d# 255 set-video-alpha         ( )  \ Opaque video
   video-on
;
: stop-video  ( -- )  video-off  ;
