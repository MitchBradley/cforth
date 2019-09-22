\ Load file for application-specific Forth extensions
\ to implement an IR remote control bridge.
\ It receives volume controls codes for the
\ "Amazon Basics Soundbar" and translates to the codes for a
\ "Digital Spectrum motorized pot remote volume control" like this
\ https://www.ebay.com/itm/2CH-Remote-Motor-ALPS-Potentiometer-12V-Volume-Control-Adjust-50KA-Remote/251972071040
\ or https://www.aliexpress.com/item/33018055749.html
\ "Amazon Basics Soundbar" is one of the choices
\ supported by an Amazon Alexa Voice Remote.


fl ../esp8266/common.fth
fl ../../lib/random.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

6 value wakeup-pin
5 constant ir-rx-pin
1 constant ir-tx-pin
7 constant feedback-pin

\ In conjunction with external circuitry, this prevents
\ the RST line from being driven while the app is operational.
\ That allows the activation buttons to be diode-or'ed into
\ the RST line to wakeup from deep sleep
: init-wakeup  ( -- )
   false gpio-output wakeup-pin gpio-mode
   0 wakeup-pin gpio-pin!
;
: init-feedback  ( -- )
   false gpio-input feedback-pin gpio-mode
;
: volume-control-off?  ( -- flag )
   feedback-pin gpio-pin@ 0=
;

: init-ir-tx  ( -- )  true ir-tx-pin ir-tx-attach  ;

fl ../esp8266/gpio-switch.fth

7 constant projector-switch-pin
6 constant down-switch-pin
5 constant up-switch-pin
: init-switches  ( -- )
   projector-switch-pin init-gpio-switch
   up-switch-pin init-gpio-switch
   down-switch-pin init-gpio-switch
;

8 constant led-pin
: init-led  ( -- )  false gpio-output led-pin gpio-mode  ;
: led-on  ( -- )  1 led-pin gpio-pin!  ;
: led-off  ( -- )  0 led-pin gpio-pin!  ;
: blip  ( -- )  led-on #100 ms led-off ;
: blips  ( -- )  blip #100 ms blip ;
: projector-switch?  ( -- flag )  projector-switch-pin gpio-pin@ 0=  ;
: up-switch?  ( -- flag )  up-switch-pin gpio-pin@ 0=  ;
: down-switch?  ( -- flag )  down-switch-pin gpio-pin@ 0=  ;

\ Input codes - from Amazon Basics Soundbar codeset
$be41ff00 value volume-up-in
$ba45ff00 value volume-down-in
$b748ff00 value mute-in

\ Output codes - for Digital Spectrum volume control
$6f905583 value projector-on/off \ be: $c1aa09f6
$fa05ff00 value volume-on/off \ be: $00ffa05f
$e41bff00 value volume-up     \ be: $00ffd827
$fc03ff00 value volume-down   \ be: $00ffc03f
$f30cff00 value brightness    \ be: $00ff30cf

: slumber  ( -- )
   ." Sleeping" cr
   blips
   4 deep-sleep-option!
   0 deep-sleep
   #1000 ms
;

#4 value sleep-seconds
0 value time-limit
: timeout?  ( -- flag )  timer@ time-limit - 0>=  ;
: reset-timeout  ( -- )
   timer@  sleep-seconds #1000000 *  +  to time-limit
;

: send  ( code -- )
   \ #60 ms
   reset-timeout
   led-off  ( code )
   ir-tx   ( )
   ir-repeat  ( -- )
   led-on ( )
   #300 ms
;
\ If the volume control is off we send the code to turn
\ it on.  We only do this if we recognize a valid input
\ code because we do not want to turn it on when codes
\ for other devices wake us up.  Turning it on results
\ in audible hum coupled from the 7-segment display
\ switching waveform.
: enable-volume-control
   begin  volume-control-off?  while
      ." !" cr  volume-on/off send
      #300 ms
   repeat

;
: disable-volume-control  ( -- )
   begin  volume-control-off?  0=  while
      ." !" cr volume-on/off send
      #300 ms
   repeat
;

: init-ir-rx  ( -- )  ir-rx-pin ir-rx-attach  ;

: run  ( -- )
   init-wakeup
   init-feedback
   init-ir-tx
   init-ir-rx
   init-led
   led-on

   reset-timeout
   begin
      key?  if  quit  then
      ir-rx ?dup  if  ( code )
         dup .x space
         case
            volume-up-in    of  ." +" enable-volume-control  volume-up     send  endof
            volume-down-in  of  ." -" enable-volume-control  volume-down   send  endof
            mute-in         of  ." !" volume-on/off send  endof
         endcase
         cr
      then
      #40 ms
   timeout? until
   disable-volume-control
   slumber
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
   run
   quit
;

" app.dic" save
