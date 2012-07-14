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

: get-board-id  ( -- id )
   open-ec  ['] board-id@  catch  close-ec  ( id 0 | error )
   if  0  then
;

fl ../arm-xo-1.75/showlog.fth

: ?startup-problem  ( -- )
   thermal?  if  ." thermal power-off" cr  power-off  then
   watchdog?  if  ." watchdog restart" cr  epitaph  bye  then
   setup-thermal
;

: init-drivers
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
;
