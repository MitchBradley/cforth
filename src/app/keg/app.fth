\ Load file for application-specific Forth extensions
\ This particular one is sort of a "kitchen sink" build
\ with a bunch of drivers for various sensors.

fl ../esp8266/common.fth
fl ../../lib/random.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

fl ../esp8266/wifi.fth

fl ../../lib/redirect.fth
fl ../esp8266/tcpnew.fth

fl ../../lib/url.fth

fl ../../lib/colors.fth
fl ../../lib/mcp23017.fth
fl ../../lib/rgblcd.fth

: init-i2c  ( -- )  8 3 i2c-setup  ;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
\ : app  banner  hex init-i2c  showstack  quit  ;
create relay-gpio-map  \ Indexed by relay number 1..8
\ Relay#  1    2    3    4    5    6    7
( gpio#)  1 c, 2 c, 0 c, 5 c, 6 c, 7 c, 4 c,

: >relay-gpio#  ( relay#1..7 -- gpio# )  1- relay-gpio-map + c@  ;

\ We set D8 to output mode to change it from open drain (the usual
\ I2C mode) to totem-pole because D8 has a 12K pulldown that
\ interferes with I2C signaling.  D8 is the I2C clock line which
\ is okay with totem-pole drive, so long as you don't need to use
\ clock stretching.  I2C data must be open drain.
\ We can't use a strong pullup to overdrive the 12K pulldown because
\ the D8 line is sampled during ROM startup to choose the boot mode.

: keg-init-i2c  ( -- )  8 3 i2c-setup  false gpio-output 8 gpio-mode  ;
: init-beeper  ( -- )
   \ The beeper is attached to MCP GPIO 3, replacing one of the switches
   0 mcp-w@  8 invert and 0 mcp-w!   \ GPIO 3 output mode
   $c mcp-w@  8 invert and 0 mcp-w!  \ GPIO 3 pullup off
;
: beeper-on  ( -- )  3 mcp-gpio-set  ;
: beeper-off  ( -- )  3 mcp-gpio-clr  ;
: beeper-ms  ( ms -- )  beeper-on ms beeper-off ;

: relay-off  ( relay# -- )  >relay-gpio#  1 swap gpio-pin!  ;
: relay-on   ( relay# -- )  >relay-gpio#  0 swap gpio-pin!  ;
: init-relay  ( relay# -- )
   dup relay-off
   false gpio-output rot >relay-gpio# gpio-mode
;
: init-relays  ( -- )  8 1  do  i init-relay  loop  ;

: init-all  ( -- )
   init-relays
   keg-init-i2c
   init-lcd
   init-beeper
   home-lcd
   clear-lcd
   lcd-magenta
;
: clear1  ( -- )   "                 " 0 0 lcd-type-at  ;
: .status  ( msg$ -- )
   2dup type cr
   clear1
   0 0 lcd-type-at
;
: clear2  ( -- )   "                 " 0 1 lcd-type-at  ;
: .status2  ( msg$ -- )
   2dup type cr
   clear2
   0 1 lcd-type-at
;

: go-switch?  ( -- ) lcd-switches@ 2 and 0=  ;
: cleanout-switch?  ( -- ) lcd-switches@ $10 and 0=  ;
: abort-switch?  ( -- )  lcd-switches@ 1 and 0=  ;

1 constant wash-pump
2 constant sanitizer-pump
3 constant water
4 constant air
5 constant wash-return
6 constant sanitizer-return
7 constant drain

false value suppress-delay?

defer check-abort

: activator-delay  ( #seconds -- )
   suppress-delay?  if  drop exit  then
   #10 *  0 swap  do  check-abort  #100 ms  -1 +loop
;

2 value ball-valve-activate-time
: valve-open  ( relay# -- )
   relay-on ball-valve-activate-time activator-delay
;
: valve-closed ( relay# -- )
   relay-off ball-valve-activate-time activator-delay
;

1 value solenoid-valve-activate-time
: solenoid-valve-open  ( relay# -- )
   relay-on solenoid-valve-activate-time activator-delay
;
: solenoid-valve-closed ( relay# -- )
   relay-off solenoid-valve-activate-time activator-delay
;

2 value pump-activate-time
: pump-on  ( relay# -- )
   relay-on pump-activate-time activator-delay
;
: pump-off  ( relay# -- )
   relay-off pump-activate-time activator-delay
;

: drain-open    ( -- )  " Drain On"  .status2   drain valve-open    clear2  ;
: drain-closed  ( -- )  " Drain Off" .status2   drain valve-closed  clear2  ;
: wash-return-open    ( -- )  " Vinegar Rtrn On"   .status2 wash-return valve-open    clear2  ;
: wash-return-closed  ( -- )  " Vinegar Rtrn Off"  .status2 wash-return valve-closed  clear2 ;
: sanitizer-return-open    ( -- )  " PeroxideRtrn On"  .status2 sanitizer-return valve-open    clear2  ;
: sanitizer-return-closed  ( -- )  " PeroxideRtrn Off" .status2 sanitizer-return valve-closed  clear2  ;
: wash-pump-on  ( -- )  " Vinegar Pump On"  .status2 wash-pump pump-on  clear2  ;
: wash-pump-off  ( -- ) " Vinegar Pump Off" .status2 wash-pump pump-off clear2  ;
: sanitizer-pump-on  ( -- )  " PeroxidePump On"  .status2 sanitizer-pump pump-on  clear2  ;
: sanitizer-pump-off  ( -- ) " PeroxidePump Off" .status2 sanitizer-pump pump-off clear2  ;
: water-open  ( -- )    " Water On"  .status2  water valve-open    clear2  ;
: water-closed  ( -- )  " Water Off" .status2  water valve-closed  clear2  ;
: air-open  ( -- )    " Air On"  .status2  air valve-open    clear2  ;
: air-closed  ( -- )  " Air Off" .status2  air valve-closed  clear2  ;

: safe-state  ( -- )
   true to suppress-delay?
   drain-open
   wash-pump-off
   sanitizer-pump-off
   water-closed
   air-closed
   wash-return-closed
   sanitizer-return-closed
   false to suppress-delay?
;

\ Display right-justified on first line
: lcd-seconds  ( n -- )
   #13 0 lcd-at
   push-decimal
   (.)          ( adr len )
   pop-base     ( adr len )
   3 min  3 over ?do  bl lcd-emit  loop
   lcd-type
;
: .time-remaining  ( deciseconds -- )
   #10 /mod swap 0=  if  lcd-seconds  bl lcd-emit  else drop then
;
: clear-time  ( -- )  "    " #13 0 lcd-type-at  ;
: (check-abort)  ( -- )
   abort-switch?  if
      lcd-red " Aborting" .status
      #100 beeper-ms
      begin  abort-switch?  0= until
      safe-state
      abort
   then
;
' (check-abort) to check-abort
: delay  ( seconds -- )
   #10 *   ( cnt )
   0 swap  do
      i .time-remaining
      check-abort
      #100 ms
   -1 +loop
   clear-time
;

\ Run water through the wash and sanitizer outlets
#20 value cleanout-time
: cleanout-cycle  ( -- )
   " Cleanout" .status
   drain-closed

   \ Run water through the wash return hose
   wash-return-open
   water-open
   cleanout-time delay
   water-closed
   wash-return-closed

   \ Run water through the sanitizer return hose
   sanitizer-return-open
   water-open
   cleanout-time delay
   water-closed
   sanitizer-return-closed

   drain-open
;

5 value drain-time
: drain-keg  ( -- )
   " Draining" .status
   drain-open
   drain-time delay
;

3 value pressurize-time
: water-pressurize  ( -- )
   drain-closed
   "   pressurizing" .status2
   pressurize-time delay
   clear2
   drain-open
;

3 value airblast-time
: airblast  ( -- )
   air-open
   "    blowing" .status2
   airblast-time delay
   air-closed
   "    draining" .status2
   drain-time delay
   clear2
;

#10 value rinse-time
: rinse-cycle  ( -- )
   \ drain-open  \ Redundant

   water-open
   "   rinsing" .status2
   rinse-time delay
   water-pressurize
   "   rinsing" .status2
   rinse-time delay      
   water-closed
   airblast
;
: rinse0  ( -- )  " First Rinse" .status  rinse-cycle  ;
: rinse1  ( -- )  " Second Rinse" .status  rinse-cycle  ;
: rinse2  ( -- )  " Third Rinse" .status  rinse-cycle  ;

#35 value wash-time
: wash-cycle  ( -- )
   " Washing" .status
   drain-closed
   wash-return-open
   wash-pump-on
   wash-time delay
   wash-pump-off
   airblast
   wash-return-closed
   drain-open
;

#35 value sanitize-time
: sanitize-cycle  ( -- )
   " Sanitizing" .status
   drain-closed
   sanitizer-return-open
   sanitizer-pump-on
   sanitize-time delay
   sanitizer-pump-off
   airblast
   sanitizer-return-closed
   drain-open
;

: beep  ( -- )
   \ turn on beeper, probably via I2c
;
: keg-cycle  ( -- )
   lcd-green
   rinse0
   wash-cycle
   rinse1
   sanitize-cycle
   rinse2
   beep
   "    Keg is clean" .status2
   5 0 do  #300 beeper-ms #100 ms  loop
;

: run  ( -- )
   init-all
   safe-state
   begin
      lcd-blue  " Ready" .status
      begin  key? if abort then  #100 ms go-switch?  until
      #100 beeper-ms
      clear2
      cleanout-switch?  if
         ['] cleanout-cycle catch drop
      else
         ['] keg-cycle catch drop
      then
   again
;


: load-startup-file  ( -- )  " start" included   ;

: app
   banner  hex
   \ Do this early to minimize time of bad relay state
   init-relays
   interrupt?  if  quit  then
   ['] load-startup-file catch drop
   ['] run catch drop
   quit
;

" app.dic" save
