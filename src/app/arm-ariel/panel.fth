\ Ariel (Dell Wyse 3020) Video Encoder configuration
\
\ Copyright (C) 2020 Lubomir Rintel <lkundrak@v3.sk>
\
\ TWSI I2C access routines based on
\ src/app/arm-mmp3-thunderstone/initdram.fth

d# 1024 to hdisp  \ Display width
d# 1344 to htotal \ Display + FP + Sync + BP

d#  768 to vdisp  \ Display width
d#  806 to vtotal \ Display + FP + Sync + BP

: twsi3!  ( n offset -- )  h# 32000 + io!  ;
: twsi3-clk-on  ( -- )
   h# 000000004 h# 1500C io!
   d# 500 us
   h# 000000007 h# 1500C io!
   d# 500 us
   h# 000000003 h# 1500C io!
   d# 500 us
;
: init-twsi3  ( -- )
   h# 4060 h# 10 twsi3!  d# 500 us
   h#   60 h# 10 twsi3!  d# 500 us
   h#    0 h# 10 twsi3!
;
: setup-twsi3  ( -- )
   \ TWSI3 pins
   h# 00000801 h# 01E2B0 +io bitset	\  Set MFPR to AF1 for TWSI3_SCL
   h# 00000801 h# 01E2B4 +io bitset	\  Set MFPR to AF1 for TWSI3_SDA
   d# 500 us

   twsi3-clk-on
   init-twsi3
;
: twsi3-put  ( n reg10-val -- )  swap 8 twsi3!  h# 10 twsi3!  d# 500 us  ;
: twsi3-reg!  ( value reg# slave-adr -- )
   h# 69 twsi3-put  h# 68 twsi3-put  h# 6a twsi3-put  d# 20000 us
;

: init-panel  ( -- )
   \ Reset
   h# 04 h# 03 h# 76 twsi3-reg!
   h# 00 h# 52 h# 76 twsi3-reg! \ Turn everything off to set all the registers to their defaults
   h# 02 h# 52 h# 76 twsi3-reg! \ Bring I/O block up

   \ Page 0
   h# 00 h# 03 h# 76 twsi3-reg!

   \ Bring up parts we need from the power down
   h# d7 h# 07 h# 76 twsi3-reg!
   h# 00 h# 08 h# 76 twsi3-reg!
   h# 1a h# 09 h# 76 twsi3-reg!
   h# 9a h# 0a h# 76 twsi3-reg!

   \ Horizontal input timing
   h# 2c h# 0b h# 76 twsi3-reg!
   h# 00 h# 0c h# 76 twsi3-reg!
   h# 40 h# 0d h# 76 twsi3-reg!
   h# 00 h# 0e h# 76 twsi3-reg!
   h# 18 h# 0f h# 76 twsi3-reg!
   h# 88 h# 10 h# 76 twsi3-reg!

   \ Vertical input timing
   h# 1b h# 11 h# 76 twsi3-reg!
   h# 00 h# 12 h# 76 twsi3-reg!
   h# 26 h# 13 h# 76 twsi3-reg!
   h# 00 h# 14 h# 76 twsi3-reg!
   h# 03 h# 15 h# 76 twsi3-reg!
   h# 06 h# 16 h# 76 twsi3-reg!

   \ Input color swap
   \ h# 00 h# 18 h# 76 twsi3-reg!
   h# 05 h# 18 h# 76 twsi3-reg!

   \ Input clock and sync polarity
   h# f8 h# 19 h# 76 twsi3-reg!
   h# c8 h# 19 h# 76 twsi3-reg!
   h# fd h# 1a h# 76 twsi3-reg!
   h# e8 h# 1b h# 76 twsi3-reg!

   \ Horizontal output timing
   h# 2c h# 1f h# 76 twsi3-reg!
   h# 00 h# 20 h# 76 twsi3-reg!
   h# 40 h# 21 h# 76 twsi3-reg!

   \ Vertical output timing
   h# 1b h# 25 h# 76 twsi3-reg!
   h# 00 h# 26 h# 76 twsi3-reg!
   h# 26 h# 27 h# 76 twsi3-reg!

   \ VGA channel bypass
   h# 09 h# 2b h# 76 twsi3-reg!

   \ Output sync polarity
   h# 27 h# 2e h# 76 twsi3-reg!

   \ HDMI horizontal output timing
   h# 80 h# 54 h# 76 twsi3-reg!
   h# 18 h# 55 h# 76 twsi3-reg!
   h# 88 h# 56 h# 76 twsi3-reg!

   \ HDMI vertical output timing
   h# 00 h# 57 h# 76 twsi3-reg!
   h# 03 h# 58 h# 76 twsi3-reg!
   h# 06 h# 59 h# 76 twsi3-reg!

   \ Pick HDMI, not LVDS
   h# 8f h# 7e h# 76 twsi3-reg!

   \ Page 1
   h# 01 h# 03 h# 76 twsi3-reg!

   \ No idea what these do, but VGA is wobbly
   \ and blinky without them
   h# 66 h# 07 h# 76 twsi3-reg!
   h# 05 h# 08 h# 76 twsi3-reg!

   \ DRI PLL
   h# 6a h# 0c h# 76 twsi3-reg!
   h# 6a h# 0c h# 76 twsi3-reg!
   h# 12 h# 6b h# 76 twsi3-reg!
   h# 00 h# 6c h# 76 twsi3-reg!

   \ This seems to be color calibration for VGA
   h# 29 h# 64 h# 76 twsi3-reg! \ LSB Blue
   h# 29 h# 65 h# 76 twsi3-reg! \ LSB Green
   h# 29 h# 66 h# 76 twsi3-reg! \ LSB Red
   h# 00 h# 67 h# 76 twsi3-reg! \ MSB Blue
   h# 00 h# 68 h# 76 twsi3-reg! \ MSB Green
   h# 00 h# 69 h# 76 twsi3-reg! \ MSB Red

   \ Page 3
   h# 03 h# 03 h# 76 twsi3-reg!

   \ More bypasses and apparently another HDMI/LVDS selector
   h# 0c h# 28 h# 76 twsi3-reg!
   h# 28 h# 2a h# 76 twsi3-reg!

   \ Page 4
   h# 04 h# 03 h# 76 twsi3-reg!

   \ Output clock
   h# 00 h# 10 h# 76 twsi3-reg!
   h# fd h# 11 h# 76 twsi3-reg!
   h# e8 h# 12 h# 76 twsi3-reg!

   \ Bring the display block up from reset
   h# 03 h# 52 h# 76 twsi3-reg!
;
