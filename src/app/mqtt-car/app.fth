\ Load file for robot car controlled from MQTT
\ Pin Assignment
\
\ Motor shield:
\ 0 constant LED-pin
\ 1 constant right-speed-pin
\ 2 constant left-speed-pin
\ 3 constant right-direction-pin
\ 4 constant left-direction-pin

\ : fl safe-parse-word 2dup type cr included ;
fl ../esp8266/common.fth

fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

fl ../esp8266/wifi.fth

fl ../esp8266/tcpnew.fth

fl ../../lib/redirect.fth
fl ../esp8266/sendfile.fth
fl ../esp8266/server.fth

fl carpwm.fth

defer mqtt-server$
: mqtt-client-id$  ( -- $ )  " Bender Car"  ;
: mqtt-username$  ( -- $ )  " "  ;
: mqtt-password$  ( -- $ )  " "  ;
: mqtt-will$  ( -- msg$ topic$ )  " "  " "  ;
0 value mqtt-will-qos     \ 0, 1, 2, 3
0 value mqtt-will-retain  \ 0 or 1
0 value mqtt-clean-session
0 value mqtt-keepalive    \ seconds

fl ${CBP}/lib/mqtt.fth

: $>duty  ( speed$ -- speed )
   push-decimal
   $number?  if  drop  else  0 0  then
   pop-base
;

also mqtt-topics definitions
\ Speed is 0..1023
: car/motors  ( value$ -- )
   ." Motors " 2dup type cr
   \ Value example: "512 -1023"
   \ for left half forward, right full backward
   bl left-parse-string  ( rem$ head$ )
   $>duty  -rot  $>duty  ( lspeed rspeed )
   motors
;
: car/led  ( value$ -- )
   ." LED " 2dup type cr
   " On"  $=  if  led-on  else  led-off  then
;
previous definitions

: blip  led-on #200 ms led-off #400 ms  ;
: mqtt-loop  ( -- )
   begin
      mqtt-fd do-tcp-poll  \ Handle input
      #10 ms
   key? until
;
: run  ( -- )
   0 gpio-output LED-pin gpio-mode
   blip
   init-car
   
   #5000 ms

   led-on
   " wifi-on" included
   led-off

   begin
      ['] mqtt-start catch
   while
      ." Waiting for MQTT server" cr
      blip
      key?  if  exit  then
   repeat
   ." Connected to MQTT server" cr
   blip blip blip
   subscribe-all
   mqtt-loop
;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
\ : app  banner  hex init-i2c  showstack  quit  ;

: app
   banner  hex
   \ interrupt?  if  quit  then
   ['] load-startup-file catch drop
   ['] run catch .error
   quit
;


" app.dic" save
