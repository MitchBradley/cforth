\ Load file for application-specific Forth extensions

\ create cl2-a1
create cl2-a2

alias purpose: \

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth

fl hwaddrs.fth
fl addrs.fth

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
d# 26 ccall: 'one-uart     { -- a.value }
d# 27 ccall: reset-reason  { -- i.value }

: enable-interrupts  ( -- )  psr@ h# 80 invert and psr!  ;
: disable-interrupts  ( -- )  psr@ h# 80 or psr!  ;

fl keypad.fth

: rotate-button?  ( -- flag )
   [ifdef] cl2-a1  d# 20  [else]  d# 15  [then]
   gpio-pin@  0=
;
: check-button?  ( -- flag )  scan-keypad 2 and   0=  ;

false value fb-shown?
h# 8009.1100 constant fb-on-value
: show-fb  ( -- )  fb-on-value h# 190 lcd!  ;
: ?visible  ( -- )
   \ Stop polling after the check button is seen for the first time,
   \ thus avoiding conflicts with OFW's use of the check button
   fb-shown?  if  exit  then
   check-button?  if  show-fb  true to fb-shown?  then
;

[ifdef] notdef
d# 4 constant hdisp-lowres
d# 3 constant vdisp-lowres
[then]

fl fbnums.fth
: blank-display-lowres  ( -- )
   \ Setup the panel path with the normal resolution
   init-lcd

[ifdef] notdef
   \ This trick uses the hardware scaler so we can display a blank
   \ white screen very quickly, without spending a lot of time
   \ filling the frame buffer with a constant value.

   \ Set the source resolution to 4x3
    hdisp-lowres vdisp-lowres wljoin h# 104 lcd!

   \ Set the pitch to 0 so we only have to fill one line
   0 h# fc lcd!

   \ Fill one line of the screen
   \ Since hdisp-lowres is 4, one line is a single longword!
   display-pa  hdisp-lowres  h# ffffffff lfill

   \ Set the depth to 8 bpp
   h# 800a1100 h# 190 lcd!
[else]
   \ Start with all display data sources off
   0 h# 190 lcd!

   \ Set the source resolution to 12x9
   h# 9000c h# 104 lcd!

   \ Set the pitch to 6 (12 pixels * 4 bits/pixel / 8 bits/byte )
   6 h# fc lcd!

   \ Set the no-display-source background color to white
   h# ffffffff h# 124 lcd!

   \ Fill the rudimentary frame buffer with white
   diagfb-pa 6 9 *  h# ff fill

   \ Turn on the display if the user presses the check key
   ?visible
[then]

   \ Turn on the dcon
   init-xo-display
;

fl hackspi.fth
fl dropin.fth

fl ps2.fth
fl spicmd.fth

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

: fix-v7  ( -- )
   h# d4282c08 l@  2 and  0=  if
      ." Processor is fused in V6 mode - switching to V7" cr
      h# d4282c08 l@  2 or  h# d4282c08 l!
   then
;

: cforth-wait  ( -- )
   begin  d# 50 ms  rotate-button?  until  \ Wait until KEY_5 GPIO pressed
   ." Resuming CForth on Security Processor" cr
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
   0 h# d4050020 l!  \ Release reset for PJ4
;

: load-ofw  ( -- )
   ( init-spi ) .spi-id
   " reset" drop-in-location abort" Can't find reset dropin"  ( adr len )
   swap h# 20000 - dup to reset-offset      ( len offset )
   +                                        ( size-to-read )
   'compressed swap h# 2.0000 spi-read      ( )
;
: dbg  ( -- )  
   ." CForth stays active on second serial port" cr
   'one-uart on
;
: ofw-up?  ( -- flag )  h# fc lcd@  6 <>  ;
: ?ofw-up  ( -- )
   d# 80 0 do
      ofw-up?  if  leave  then
      ?visible
      d# 100 ms
   loop

   \ Check to see if OFW took over the display
   ofw-up?  0=  if
      show-fb
      ." CForth says: OFW seems not to have booted all the way" cr
   then
;
: ofw  ( -- )
   blank-display-lowres
   h# 00 puthex  ?visible
   load-ofw
   h# 01 puthex  ?visible
   ofw-go
   enable-ps2

   ?ofw-up

   'one-uart @  0=  if
      begin wfi again
   then
;
: maybe-ofw  ( -- )
   rotate-button?  if  ." Skipping OFW" cr  exit  then
   ofw
;

\ Start of alternative boot code.  This is used only for recovery/debugging purposes.
\ It is slower than the normal boot code.  This code performs the decompression
\ of the OFW image on the SP, whereas the normal boot code lets the PJ4 processor
\ do the decompression.

h# 1fa0.0000 constant ofw-pa

: ofw-go-slow  ( -- )
   h# ea000000 h# 0 pj4-l!  \ b 8
   ofw-pa      h# 4 pj4-l!  \ OFW load address
   h# e51f000c h# 8 pj4-l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c pj4-l!  \ mov pc,r0

   ." releasing" cr
   0 h# d4050020 l!  \ Release reset for PJ4
;

: load-ofw-slow  ( -- )
   init-spi
   .spi-id

   ofw-pa pj4>sp-adr " firmware" load-drop-in
;
: ofw-slow  ( -- )
\   0 h# e0000 h# 20000 spi-read
\   spi-go
   rotate-button?  if  ." Skipping OFW" cr  exit  then

   blank-display-lowres
   load-ofw-slow
   ofw-go-slow
   enable-ps2
\   cforth-wait
   begin wfi again
;

\ Run OFW on the security processor
\ This won't work on OFW builds that use virtual != physical addressing,
\ because the SP has no MMU.
: sp-ofw  ( -- )  load-ofw-slow  " " drop  ofw-pa pj4>sp-adr acall  ;

\ End of alternative boot code.

\ Drop the voltage to the lower level for testing
: set-voltage  ( -- )
[ifdef] notdef
   d# 11 gpio-pin@  if
      cr ." APPARENT CRASH RESET - INTERACTING - reset reason = "
      reset-reason . cr cr
      hex quit
   then
[then]
   board-id@ h# 1b1 <  if  exit  then
   ." Using lower core voltage" cr
   d# 11 gpio-set
;

: init0
   basic-setup
   init-timers
   set-gpio-directions
   init-mfprs
   init-ec-cmd
   set-voltage
;
: init1
   init-dram
\   fix-fuses
   fix-v7
   init-spi
   keyboard-power-on  \ Early to give the keyboard time to wake up
   keypad-on
   8 keypad-direct-mode
;
: init
   init0
   clk-fast
   init1
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
: app  init  ( d# 400 ms )  maybe-ofw  hex quit  ;
\ " ../objs/tester" $chdir drop

0 [if]
: fillit
   'compressed h# 48000 h# ff fill
;
: testit
   'compressed h# 48000 bounds do i @ dup -1 <> if i . . cr leave else drop then 4 +loop
;
: app  init0 clk-fast ." To init DRAM, type 'init1'.  To boot, type 'ofw'" cr  hex quit ;
[then]

" app.dic" save
