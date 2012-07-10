\ Load file for application-specific Forth extensions

alias purpose: \

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth

fl ../arm-mmp2/hwaddrs.fth
fl ../arm-xo-1.75/addrs.fth

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
fl ../arm-xo-1.75/boardgpio.fth

: alloc-mem  drop 0  ;  : free-mem 2drop  ;
\ fl flashif.fth
\ fl spiif.fth
\ fl spiflash.fth
\ fl ../arm-mmp2/sspspi.fth
fl ../arm-xo-1.75/clockset.fth
fl ../arm-xo-1.75/initdram.fth
fl ../arm-mmp2/fuse.fth
fl ../arm-xo-1.75/smbus.fth

: wljoin  ( w w -- l )  d# 16 lshift or  ;
: third  ( a b c -- a b c a )  2 pick  ;
fl ../arm-mmp2/lcd.fth

[ifdef] dcon-scl-gpio#
fl ../arm-xo-1.75/mmp2dcon.fth
[else]
fl ../arm-xo-3.0/panel.fth
[then]

: short-delay ;

fl ../arm-xo-1.75/ccalls.fth
fl ../arm-xo-1.75/banner.fth

: enable-interrupts  ( -- )  psr@ h# 80 invert and psr!  ;
: disable-interrupts  ( -- )  psr@ h# 80 or psr!  ;

[ifdef] use_mmp2_keypad_control
fl ../arm-mmp2/keypad.fth
[then]

fl ../arm-xo-1.75/controls.fth
fl ../arm-xo-1.75/showfb.fth

fl ../arm-xo-1.75/hackspi.fth
fl ../arm-xo-1.75/dropin.fth

[ifdef] soc-kbd-clk-gpio#
fl ../arm-xo-1.75/ps2.fth
[then]

fl ../arm-xo-1.75/spicmd.fth
fl ../arm-mmp2/thermal.fth
fl ../arm-xo-1.75/memtest.fth

\ Drop the voltage to the lower level for testing
: get-board-id  ( -- id )
   open-ec  ['] board-id@  catch  close-ec  ( id 0 | error )
   if  0  then
;
: board-config
[ifdef] notdef-show-crash
   vid2-gpio# gpio-pin@  if
      cr ." APPARENT CRASH RESET - INTERACTING - reset reason = "
      reset-reason . cr cr
      hex protect-fw quit
   then
[then]
   
   get-board-id  dup h# 1b1 >=  if             ( id )
      ." Using lower core voltage" cr
      vid2-gpio# gpio-set
      0 sleep1 +edge-clr  vid2-gpio#  af!  \ This is VID2 - we want it to stay high during suspend
   then                          ( id )

   dup h# 1c1 >=  if             ( id )
       \ Rev C has pullups/downs for the memory config inputs, so we turn off
       \ the pulldowns to avoid unnecessary current.  The MPFRs are initially
       \ configured for pulldowns so A and B boards will report 512 MiB memory.
       0 sleepi 0 af!
       0 sleepi 1 af!
   then                          ( id )

   drop                          ( )
;

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
: fix-v7  ( -- )
   h# 282c08 io@  2 and  0=  if
      ." Processor is fused in V6 mode - switching to V7" cr
      h# 282c08 io@  2 or  h# 282c08 io!
   then
;

: init1
   \ Select the 1 GHz operating point - op5 - only if both the board
   \ and the SoC are rated for operation at that speed.
   1 gpio-pin@  rated-speed 2 =  and  if  op5  else  op4  then
   init-dram
[ifdef] fix-fuses
   fix-fuses
[then]
   fix-v7
   init-spi
[ifdef] keyboard-power-on
   keyboard-power-on  \ Early to give the keyboard time to wake up
[then]
;

: cforth-wait  ( -- )
   begin  wfi  activate-cforth?  until
   ." Resuming CForth on Security Processor, second UART" cr
   1 'one-uart !
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
: ofw-up?  ( -- flag )  h# 190 lcd@  0<>  ;
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
   init1
   blank-display-lowres
   h# 00 puthex  ?visible
   load-ofw
   h# 01 puthex  ?visible
[ifdef] enable-ps2
   enable-ps2
[then]
   ofw-go

   ?ofw-up

   'one-uart @  0=  if
      wfi-loop
\     d# 4000 ms  cforth-wait
   then
;

fl ../arm-xo-1.75/showlog.fth

: maybe-ofw  ( -- )
   early-activate-cforth?  if  ." Skipping OFW" cr  exit  then
   thermal?  if  ." thermal power-off" cr  power-off  then
   watchdog?  if  ." watchdog restart" cr  epitaph  bye  then
   setup-thermal
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

\ Run OFW on the security processor
\ This won't work on OFW builds that use virtual != physical addressing,
\ because the SP has no MMU.
: sp-ofw  ( -- )  load-ofw-slow  " " drop  ofw-pa pj4>sp-adr acall  ;

\ End of alternative boot code.

\ Run this at startup
: app  init  ( d# 400 ms )  maybe-ofw  hex protect-fw quit  ;
\ " ../objs/tester" $chdir drop

fl ../arm-xo-1.75/showpmu.fth

" app.dic" save
