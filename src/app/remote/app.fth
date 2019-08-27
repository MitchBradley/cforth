\ Load file for application-specific Forth extensions
\ This particular one is sort of a "kitchen sink" build
\ with a bunch of drivers for various sensors.

fl ../esp8266/common.fth
fl ../../lib/random.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

2 constant wakeup-pin
\ In conjunction with external circuitry, this prevents
\ the RST line from being driven while the app is operational.
\ That allows the activation buttons to be diode-or'ed into
\ the RST line to wakeup from deep sleep
: init-wakeup  ( -- )
  false gpio-output wakeup-pin gpio-mode
  1 wakeup-pin gpio-pin!
;

1 constant ir-pin

: init-ir  ( -- )
  false gpio-output ir-pin gpio-mode
  0 ir-pin gpio-pin!
;

fl ../esp8266/gpio-switch.fth

7 constant projector-switch-pin
6 constant down-switch-pin
5 constant up-switch-pin
: init-switches  ( -- )
   projector-switch-pin init-gpio-switch
   up-switch-pin init-gpio-switch
   down-switch-pin init-gpio-switch
;

4 constant led-pin
: init-led  ( -- )  false gpio-output led-pin gpio-mode  ;
: led-on  ( -- )  0 led-pin gpio-pin!  ;
: led-off  ( -- )  1 led-pin gpio-pin!  ;
: blips  ( -- )  led-on #100 ms led-off #100 ms led-on #100 ms led-off  ;
: projector-switch?  ( -- flag )  projector-switch-pin gpio-pin@ 0=  ;
: up-switch?  ( -- flag )  up-switch-pin gpio-pin@ 0=  ;
: down-switch?  ( -- flag )  down-switch-pin gpio-pin@ 0=  ;

$c1aa09f6 value projector-on/off
$00ffa05f value volume-on/off
$00ffd827 value volume-up
$00ffc03f value volume-down
$00ff30cf value brightness

false value done?
#10 value sleep-seconds
: sleep  ( -- )  true to done?  ;
: set-sleep  ( -- )   ['] sleep sleep-seconds #1000 * set-alarm  ;
: cancel-sleep  ( -- )  0 0 set-alarm  ;

: both?  ( -- flag )  up-switch?  down-switch?  and  ;
: either?  ( -- flag )  up-switch?  down-switch?  or  ;

0 value this-code
0 value repeat?
: volume-button  ( ir-code pin -- )
   to switch-gpio  to this-code
   switch?  if
      cancel-sleep
      led-on
      #300 ms 
      both?  if
         begin
            volume-on/off ir-pin ir-packet
            #1000 ms
         either? 0=  until
      else
         begin
            this-code ir-pin ir-packet
            #400 ms
         switch? 0= until
      then
      led-off
      set-sleep
   then
;
: projector-button  ( ir-code pin -- )
   to switch-gpio  to this-code
   switch?  if
      cancel-sleep
      led-on
      this-code ir-pin ir-packet
      begin  switch?  while  #10 ms  repeat
      led-off
      set-sleep
   then
;

: run  ( -- )
   \ wifi-sta-disconnect
   init-wakeup
   init-ir
   init-led
   init-switches
   led-on #500 ms led-off
   false to done?
   set-sleep
   begin
      key?  if  cancel-sleep quit  then
      projector-on/off projector-switch-pin projector-button
      volume-up up-switch-pin volume-button
      volume-down down-switch-pin volume-button
      #10 ms
   done? until
   ." Sleeping" cr
   blips
   4 deep-sleep-option!
   0 deep-sleep
   #1000 ms
;

\ If you have problems flashing, try:
\ a) Hitting RST then flashing quickly
\ b) interacting on the serial
\ port, then disconnecting TeraTerm, then starting the download.

: app
\   banner decimal
\   interrupt?  if  quit  then
\   ['] load-startup-file catch drop
   decimal
   cr ." Remote app.  Sleeps after " sleep-seconds . ." seconds." cr
   ." Type a key to interact" cr
   \ run
   quit
;

" app.dic" save
