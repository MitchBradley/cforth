\ Load file for application-specific Forth extensions
\ This particular one is sort of a "kitchen sink" build
\ with a bunch of drivers for various sensors.

fl ../esp8266/common.fth
fl ../../lib/random.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous


6 constant switch-pin
0 constant led-pin
4 constant enable-pin
3 constant step-pin
2 constant dir-pin
1 constant sensor-pin

: dir-cw  1 dir-pin gpio-pin!  ;
: dir-ccw  0 dir-pin gpio-pin!  ;

: init-gpios  ( -- )
   1 gpio-input  switch-pin  gpio-mode
   0 gpio-input  sensor-pin  gpio-mode
   0 gpio-output led-pin     gpio-mode
   0 gpio-output step-pin    gpio-mode
   0 gpio-output dir-pin     gpio-mode
   0 gpio-output enable-pin  gpio-mode
;


fl ../esp8266/wifi.fth

fl ../esp8266/tcpnew.fth

fl ../../lib/redirect.fth
fl ../esp8266/sendfile.fth
fl ../esp8266/server.fth

: pwm-off  ( -- )  0 0 led-pin set-pwm  ;
: led-bright  ( -- )  pwm-off  1 led-pin gpio-pin!  ;
: led-dim  ( -- )  #9900 #100 led-pin set-pwm  ;
: led-medium  ( -- )  #8000 #2000 led-pin set-pwm  ;
: led-off  ( -- )  pwm-off  0 led-pin gpio-pin!  ;

#150 value us/step-slow
#150 value us/step-fast
8 value microsteps
#57 #11 2constant gear-ratio
: steps/rev  ( -- n )  #200 microsteps * gear-ratio */ ;
#1350 value millirevs

false value motor-enabled?
: enable-motor  ( -- )
   1 enable-pin gpio-pin!
   true to motor-enabled?
   led-medium
;
alias em enable-motor
: disable-motor  ( -- )
   0 enable-pin gpio-pin!
   false to motor-enabled?
   led-dim
;
alias dm disable-motor

false value web-trigger?
: cycle-steps  ( -- n )  steps/rev millirevs #1000 */  ;
: cycle  ( -- )
   enable-motor
   cycle-steps  us/step-fast us/step-slow  step-pin  sensor-pin start-stepper
;
: wait-cycle  ( -- )
   cycle-steps us/step-fast #1000 */ ms begin #50 ms steps-left 0<  until
;
: sensor?   ( -- )  sensor-pin gpio-pin@ 0<>  ;
: 1step  ( -- )
   0 step-pin gpio-pin!
   5 us
   1 step-pin gpio-pin!
;
: find-barcode  ( -- )
   begin  sensor? 0=  while  1step 2 ms  repeat
;
: 1label  ( -- )
   led-bright
   cycle  wait-cycle
   disable-motor
   led-medium
;

: html-cycle  ( -- )
   .prolog
   ." Running" cr
   #3000 .reload-after
   .epilog
   true to web-trigger?
;
: html-hold-motor  ( -- )
   #500 .reload-after
   enable-motor
;
: html-release-motor  ( -- )
   #500 .reload-after
   disable-motor
;

: hdr  ." <h1>Labeler</h1>" cr ;
: motor-status
   ." <div>Motor is "
   motor-enabled?  if
      ." Holding&nbsp;"
      ." <a href='forth?cmd=html-release-motor'><button>Release</button></a>" cr
   else
      ." Released&nbsp;"
      ." <a href='forth?cmd=html-hold-motor'><button>Hold</button></a>" cr
   then
;
: run-button ." <p><a href='forth?cmd=html-cycle'><button>Label</button></a></p>" cr  ;

: chooser  ( -- )
   ." <form action='/setval' method='get'>" cr
   ." Millirevs" cr
   ." <input type='number' name='millirevs' min='1000' max='2000' step='1' size='4' value='"
   millirevs (.d) type 
   ." '>" cr
   ." <input type='submit' value='Change'>" cr
   ." </form>" cr
;

: labeler-homepage  ( -- )
   reply{ .prolog hdr motor-status run-button chooser .epilog }reply
;
' labeler-homepage to homepage

: load-startup-file  ( -- )  " start" included   ;

: start-web  ( -- )
   " wifi-on" ['] included catch  if
      2drop  ." No WiFi config" cr
      wifi-sta-disconnect
   else
      ." Starting web server" cr  
      listen
   then
;

: switch?  ( -- flag )  switch-pin gpio-pin@ 0=  ;
: wait-switch-released  ( -- long? )
   get-ticks #1500 ms>ticks +    ( time-limit )
   led-bright                    ( time )
   begin  #50 ms switch?  while  ( time-limit )
      get-ticks over - 0>  if    ( time-limit )
         drop  led-dim           ( )
         begin  #50 ms switch? 0=  until
         true exit               ( -- true )
      then                       ( time-limit )
   repeat                        ( time-limit )
   drop false
;

: wait-reenable  ( -- )
   begin  #50 ms  switch? until
   led-medium
   begin  #50 ms  switch? 0= until
;
: poll-switch  ( -- )
   begin
      #50 ms
      switch?  if
         wait-switch-released  if
            disable-motor
            wait-reenable
            enable-motor
         else
            1label
         then
      then
      web-trigger?  if
         led-bright 1label
         false to web-trigger?
      then
   key? until
;

: run  ( -- )
   start-web
   poll-switch
;

: app
   banner decimal
   init-gpios disable-motor dir-cw reinit-timer
   interrupt?  if  quit  then
   ['] load-startup-file catch drop
   ['] run catch drop
   quit
;

" app.dic" save

