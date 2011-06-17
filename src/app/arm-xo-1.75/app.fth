\ Load file for application-specific Forth extensions

\ create cl2-a1
create cl2-a2

alias purpose: \

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth

fl hwaddrs.fth

defer ms  defer get-msecs
fl timer.fth
fl timer2.fth
fl gpio.fth
fl mfpr.fth
fl boardgpio.fth

: alloc-mem  drop 0  ;  : free-mem 2drop  ;
\ fl flashif.fth
\ fl spiif.fth
\ fl spiflash.fth
\ fl sspspi.fth
fl clockset.fth
fl initdram.fth
fl fuse.fth
fl smbus.fth
h# 1fc0.0000 constant fb-pa
: wljoin  ( w w -- l )  d# 16 lshift or  ;
: third  ( a b c -- a b c a )  2 pick  ;
fl lcdcfg.fth
fl lcd.fth
fl mmp2dcon.fth

: short-delay ;

0 ccall: spi-send        { a.adr i.len -- }
1 ccall: spi-send-only   { a.adr i.len -- }
2 ccall: spi-read-slow   { a.adr i.len i.offset -- }
3 ccall: spi-read-status { -- i.status }
4 ccall: spi-send-page   { a.adr i.len i.offset -- }
5 ccall: spi-read        { a.adr i.len i.offset -- }
6 ccall: lfill           { a.adr i.len i.value -- }
7 ccall: lcheck          { a.adr i.len i.value -- i.erraddr }
8 ccall: inc-fill          { a.adr i.len -- }
9 ccall: inc-check         { a.adr i.len -- i.erraddr }
d# 10 ccall: random-fill   { a.adr i.len -- }
d# 11 ccall: random-check  { a.adr i.len -- i.erraddr }
d# 12 ccall: (inflate)     { a.compadr a.expadr i.nohdr a.workadr -- i.expsize }
d# 13 ccall: control@      { -- i.value }
d# 14 ccall: control!      { i.value -- }
d# 15 ccall: tcm-size@     { -- i.value }
d# 16 ccall: inflate-adr   { -- a.value }
d# 17 ccall: byte-checksum { a.adr i.len -- i.checksum }
d# 18 ccall: wfi           { -- }
d# 19 ccall: psr@          { -- i.value }
d# 20 ccall: psr!          { i.value -- }
d# 21 ccall: kbd-bit-in    { -- i.value }
d# 22 ccall: kbd-bit-out   { i.value -- }
d# 23 ccall: ps2-devices   { -- a.value }
d# 24 ccall: init-ps2      { -- }
d# 25 ccall: ps2-out       { i.byte i.device# -- i.ack? }

: enable-interrupts  ( -- )  psr@ h# 80 invert and psr!  ;
: disable-interrupts  ( -- )  psr@ h# 80 or psr!  ;

h# 2fc0.0000 constant sp-fb-pa

d# 4 constant hdisp-lowres
d# 3 constant vdisp-lowres
: blank-display-lowres  ( -- )
   \ Setup the panel path with the normal resolution
   init-lcd

   \ This trick uses the hardware scaler so we can display a blank
   \ white screen very quickly, without spending a lot of time
   \ filling the frame buffer with a constant value.

   \ Set the source resolution to 4x3
    hdisp-lowres vdisp-lowres wljoin h# 104 lcd!

   \ Set the pitch to 0 so we only have to fill one line
   0 h# fc lcd!

   \ Fill one line of the screen
   \ Since hdisp-lowres is 4, one line is a single longword!
   sp-fb-pa  hdisp-lowres  h# ffffffff lfill

   \ Set the depth to 8 bpp
   h# 800a1100 h# 190 lcd!

   \ Turn on the dcon
   init-xo-display
;

fl hackspi.fth
fl dropin.fth

fl ps2.fth

0 value memtest-start
h# 1000.0000 value memtest-length
: memtest  ( adr len -- )
   ." Random pattern test from " memtest-start u.
   ." to " memtest-start memtest-length + 1- u. cr
   ." Filling ..." cr
   memtest-start memtest-length random-fill
   ." Checking ..." cr
   memtest-start memtest-length random-check
   dup -1 =  if
      drop
      ." Good" cr
   else
      ." ERROR at address " u. cr
   then
;

: rotate-button?  ( -- flag )
   [ifdef] cl2-a1  d# 20  [else]  d# 15  [then]
   gpio-pin@  0=
;

: cforth-wait  ( -- )
   begin  d# 50 ms  rotate-button?  until  \ Wait until KEY_5 GPIO pressed
   ." Resuming CForth on Security Processor" cr
;
: ofw-go  ( -- )
   ." releasing" cr

   \ If the ITCM is on, we must turn it off so we can write to RAM at 0
   control@  itcm-off   ( old-value )

   h# ea000000 h# 0 l!  \ b 8
   h# 1fa00000 h# 4 l!  \ OFW load address
   h# e51f000c h# 8 l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c l!  \ mov pc,r0

   control!             \ Turn the ITCM back on if necessary

   d# 20 ms
   0 h# d4050020 l!  \ Release reset for PJ4
;

: load-ofw  ( -- )
   init-spi
   .spi-id

   h# 2fa0.0000 " firmware" load-drop-in
;
0 value reset-offset
: ofwdi-go  ( -- )
   ." releasing" cr
   \ If the ITCM is on, we must turn it off so we can write to RAM at 0
   control@  itcm-off   ( old-value )

   h# ea000000 h# 0 l!  \ b 8
   'compressed reset-offset +  h# 4 l!  \ reset vector address
   h# e51f000c h# 8 l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c l!  \ mov pc,r0

   control!             \ Turn the ITCM back on if necessary

   d# 20 ms
   0 h# d4050020 l!  \ Release reset for PJ4
;

: load-ofwdi  ( -- )
   ( init-spi ) .spi-id
   " reset" drop-in-location abort" Can't find reset dropin"  ( adr len )
   swap h# 20000 - dup to reset-offset      ( len offset )
   +                                        ( size-to-read )
   'compressed swap h# 2.0000 spi-read      ( )
;
: ofwdi  ( -- )
   rotate-button?  if  ." Skipping OFW" cr  exit  then
   blank-display-lowres
   load-ofwdi
   ofwdi-go
   begin wfi again
;
: ofw  ( -- )
\   0 h# e0000 h# 20000 spi-read
\   spi-go
   rotate-button?  if  ." Skipping OFW" cr  exit  then

   blank-display-lowres
   load-ofw
   ofw-go
\   cforth-wait
   begin wfi again
;
: sp-ofw  ( -- )  load-ofw  " " drop  h# 2fa0.0000 acall  ;

: init
   basic-setup
   init-timers
   set-gpio-directions
   init-mfprs
   clk-fast
   init-dram
\   fix-fuses
   init-spi
;

0 [if]
: t
   0 h# 0 l!
\  h# 2000.0000 dup l!
   h# 1000.0000 dup l!
   h#  800.0000 dup l!
   h#  400.0000 dup l!
   h#  200.0000 dup l!
   0 l@ .
;

: what  init-dram  t  ;
[then]

\ Run this at startup
: app  init  ofwdi  hex quit  ;
\ " ../objs/tester" $chdir drop

" app.dic" save
