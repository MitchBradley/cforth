\ Load file for application-specific Forth extensions

alias purpose: \

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth

fl ../arm-mmp2/hwaddrs.fth
fl addrs.fth

: +io  ( offset -- adr )  h# d4000000 +  ;
: io!  ( l offset -- )  +io l!  ;
: io@  ( offset l -- )  +io l@  ;
: io!@  ( l offset -- )  tuck io! io@ drop  ;
: +io!@  ( l offset base -- )  + io!@  ;

defer ms  defer get-msecs
fl ../arm-mmp2/timer.fth
fl ../arm-mmp2/watchdog.fth
fl ../arm-mmp2/timer2.fth
fl ../arm-mmp2/gpio.fth
fl ../arm-mmp2/mfpr.fth
fl boardgpio.fth

: alloc-mem  drop 0  ;  : free-mem 2drop  ;

: basic-setup ;
\ fl clockset.fth

fl initdram.fth
fl ../arm-mmp2/fuse.fth

: wljoin  ( w w -- l )  d# 16 lshift or  ;
: third  ( a b c -- a b c a )  2 pick  ;

[ifdef] INCLUDE-DISPLAY
fl ../arm-mmp2/lcd.fth
fl lcdcfg.fth
[then]

: short-delay ;

fl ../arm-xo-1.75/ccalls.fth
fl ../arm-xo-1.75/banner.fth

: enable-interrupts  ( -- )  psr@ h# 80 invert and psr!  ;
: disable-interrupts  ( -- )  psr@ h# 80 or psr!  ;

[ifdef] use_mmp2_keypad_control
fl ../arm-mmp2/keypad.fth
[then]

\ Thunderstone
: early-activate-cforth?  true  ;
false constant activate-cforth?
false constant show-fb?

false value fb-shown?
h# 8009.1100 constant fb-on-value

: show-fb ;
: ?visible ;

fl thermal.fth

fl ../arm-xo-1.75/memtest.fth

: board-config  ;

: init
   banner
   basic-setup
   init-timers
   enable-wdt-clock
   set-gpio-directions
   init-mfprs
[ifdef] use_mmp2_keypad_control
   keypad-on
   8 keypad-direct-mode
[then]
   board-config
;

: init1
   init-dram
;

: cforth-wait  ( -- )
   begin  wfi  activate-cforth?  until
;

\ The SP and PJ4's address maps for memory differ, apparently for the purpose
\ of accomodating the "Tightly Coupled Memory" (TCM).
\ DDR/PJ-addr   SP-addr
\ 0x0xxx.xxxx   0x1xxx.xxxx
\ 0x1xxx.xxxx   0x2xxx.xxxx
\ ...
\ 0x6xxx.xxxx   0x7xxx.xxxx
\ 0x7xxx.xxxx   inaccessible?
\
\ When TCM is on,  SP-addr 0x0xxx.xxxx goes to TCM
\ When TCM is off, SP-addr 0x0xxx.xxxx goes to main memory 0x0xxx.xxxx (alias of 0x1xxx.xxxx)

: pj4>sp-adr  ( pj4-adr -- sp-adr )  h# 1000.0000 +  ;
: pj4-l!  ( l pj4-adr -- )  pj4>sp-adr l!  ;

0 value reset-offset
: ofw-go  ( -- )
   h# ea000000 h# 0 pj4-l!  \ b 8
   'compressed reset-offset +  h# 4 pj4-l!  \ reset vector address
   h# e51f000c h# 8 pj4-l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c pj4-l!  \ mov pc,r0

   ." releasing" cr
   0 h# 050020 io!  \ Release reset for PJ4
;

: load-ofw  ( -- )
\ Get compressed OFW into memory at 'compressed
\ from image offset h# 20000 through at least the end of the reset dropin
\ Set reset-offset to the start address of the reset dropin
   ( XXX )  0 to reset-offset
;

\ Run this at startup
: app  init  ( d# 400 ms )  ( load-ofw ofw-go )  quit  ;

h# 1fa0.0000 constant ofw-pa

: ofw-go-slow  ( -- )
   h# ea000000 h# 0 pj4-l!  \ b 8
   ofw-pa      h# 4 pj4-l!  \ OFW load address
   h# e51f000c h# 8 pj4-l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c pj4-l!  \ mov pc,r0

   ." releasing" cr
   0 h# 050020 io!  \ Release reset for PJ4
;

: load-ofw-slow  ( -- )
   init-spi
   .spi-id

   ofw-pa pj4>sp-adr " firmware" load-drop-in
;
: ofw-slow  ( -- )
\   0 h# e0000 h# 20000 spi-read
\   spi-go
   activate-cforth?  if  ." Skipping OFW" cr  exit  then

   blank-display-lowres
   load-ofw-slow
   ofw-go-slow
[ifdef] enable-ps2
   enable-ps2
[then]
   cforth-wait
\   begin wfi again
;


" app.dic" save
