\ Load file for application-specific Forth extensions

h# 10.0000 constant /rom
0 constant dlofw-base

fl ../arm-mmp2/mmp2drivers.fth
fl ../arm-xo-1.75/boardgpio.fth
fl ../arm-xo-1.75/clockset.fth
fl ../arm-xo-1.75/initdram.fth
fl ../arm-xo-1.75/olpcbasics.fth
fl ../arm-xo-1.75/showpmu.fth  \ Power management debugging words
fl ../arm-xo-1.75/memtest.fth

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

: fix-v7  ( -- )
   h# 282c08 io@  2 and  0=  if
      ." Processor is fused in V6 mode - switching to V7" cr
      h# 282c08 io@  2 or  h# 282c08 io!
   then
;

: late-init
   ?startup-problem

   \ Select the 1 GHz operating point - op5 - only if both the board
   \ and the SoC are rated for operation at that speed.
   1 gpio-pin@  rated-speed 2 =  and  if  op5  else  op4  then

   init-dram

   [ifdef] fix-fuses  fix-fuses  [then]
   fix-v7
   [ifdef] keyboard-power-on  keyboard-power-on  [then]
;

: release-main-cpu  ( -- )
   0 h# 050020 io!  \ Release reset for PJ4
;

fl ../arm-xo-1.75/ofw.fth

\ Run this at startup
: app  ( -- )
   init-drivers
   board-config
   early-activate-cforth?  0=  if
      ['] ofw catch .error
   then
   ." Skipping OFW" cr
   hex protect-fw quit
;

" app.dic" save
