\ fl flashif.fth
\ fl spiif.fth
\ fl spiflash.fth
\ fl ../arm-mmp2/sspspi.fth
fl ../arm-xo-1.75/smbus.fth

fl ../arm-xo-1.75/addrs.fth

fl ../arm-mmp2/lcd.fth

[ifdef] dcon-scl-gpio#
fl ../arm-xo-1.75/mmp2dcon.fth
[else]
fl ../arm-xo-3.0/panel.fth
[then]

: short-delay ;

fl ../arm-xo-1.75/banner.fth

: enable-interrupts  ( -- )  psr@ h# 80 invert and psr!  ;
: disable-interrupts  ( -- )  psr@ h# 80 or psr!  ;

[ifdef] use_mmp2_keypad_control
fl ../arm-mmp2/keypad.fth
[then]

fl ../arm-xo-1.75/controls.fth
fl ../arm-xo-1.75/showfb.fth

[ifdef] spi-flash-cs-gpio#
fl ../arm-xo-1.75/hackspi.fth
fl ../arm-xo-1.75/dropin.fth
[then]

[ifdef] soc-kbd-clk-gpio#
fl ../arm-xo-1.75/ps2.fth
[then]

fl ../arm-xo-1.75/spicmd.fth

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
   h# 20 mpmu@ 2 and  0=  if
      ." CForth unexpected restart! - freezing PJ4" cr
      2  h# 20 mpmu-set
      quit
   then
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
