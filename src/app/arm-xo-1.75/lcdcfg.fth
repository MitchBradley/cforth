h# 40001102 value clkdiv  \ Display Clock 1 / 2 -> 56.93 MHz
h# 00000700 value pmua-disp-clk-sel  \ PLL1 / 7 -> 113.86 MHz 

d#    8 value hsync  \ Sync width
[ifdef] cl3
d# 1024 value hdisp  \ Display width
d# 1344 value htotal \ Display + FP + Sync + BP
[else]
d# 1200 value hdisp  \ Display width
d# 1256 value htotal \ Display + FP + Sync + BP
[then]
d#   24 value hbp    \ Back porch

d#    3 value vsync  \ Sync width
[ifdef] cl3
d#  768 value vdisp  \ Display width
d#  806 value vtotal \ Display + FP + Sync + BP
[else]
d#  900 value vdisp  \ Display width
d#  912 value vtotal \ Display + FP + Sync + BP
[then]
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

[ifdef] cl3
: bright!  ( level -- )  d# 15 min  h# 11 *  h# 1a404 io!  ;
: backlight-on  ( -- )  d# 15 bright!  ;
: backlight-off  ( -- )  0 bright!  ;
: setup-pwm2  ( -- )
   7 h# 1503c io!  3 h# 1503c io!  \ Turn on the PWM1 clock and release reset - PWM2 depends on it
   7 h# 15040 io!  3 h# 15040 io!  \ Turn on the PWM2 clock and release reset
   h#  3f h# 1a400 io!  \ Prescaler value 63, 26MHz / 64 = 406 kHz
   h# 100 h# 1a408 io!  \ Full period is 256 clocks
\   backlight-off
   d# 15 bright!
   3 sleep0 d# 49 af!         \ Switch over to PWM control of the pin
   d# 138 gpio-set
   d# 138 gpio-dir-out
;

: lcd-power-on  ( -- )
   d#  33 gpio-set   \ LCDVCC_EN
   d# 138 gpio-set   \ LCDVCC_EN
   d# 135 gpio-set   \ STBY#
   d# 500 us
   d# 130 gpio-set   \ LCD_RESET#
   d# 129 gpio-set   \ EN_LCD_PWR
   d# 50 ms          \ Frame time
   d# 130 gpio-clr   \ LCD_RESET#  (pulse low)
   d# 50 us          \ Pulse needs to be at least 50 us
   d# 130 gpio-set   \ LCD_RESET#  (end of pulse)

   d# 120 ms
   setup-pwm2
\  backlight-on
;
: init-xo-display  ( -- )
   lcd-power-on
;
[then]
