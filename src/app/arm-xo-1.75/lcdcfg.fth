h# 40001102 value clkdiv  \ Display Clock 1 / 2 -> 56.93 MHz
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

alias width  hdisp
alias height vdisp
alias depth  bpp
width >bytes constant /scanline  
