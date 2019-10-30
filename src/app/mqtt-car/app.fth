\ Load file for robot car controlled from MQTT
\ Pin Assignment
\
\ Motor shield:
\ 0 constant LED-pin
\ 1 constant right-speed-pin
\ 2 constant left-speed-pin
\ 3 constant right-direction-pin
\ 4 constant left-direction-pin
\
\ Proximity sensor

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

: wifi-on  ( -- )
   " Bender" " " station-connect
;

: mqtt-server$  ( -- $ )  " 192.168.4.254"  ;
: mqtt-client-id$  ( -- $ )  " Bender"  ;
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

: subscribe-all  ( -- )
   0 " car/motors"  0 " car/led"  2  #1234 mqtt-subscribe
;

: run  ( -- )
   0 gpio-output LED-pin gpio-mode
   \ init-car
   wifi-on
   ." WiFi on, AP is Bender" cr
   begin
      ['] mqtt-start catch
   while
      ." Waiting for MQTT server" cr
      key?  if  exit  then
   repeat
   ." Connected to MQTT server" cr
   subscribe-all
   begin
      mqtt-fd do-tcp-poll  \ Handle input
      #10 ms
   key? until
;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
\ : app  banner  hex init-i2c  showstack  quit  ;

: app
   banner  hex
   interrupt?  if  quit  then
   ['] load-startup-file catch drop
   run
   quit
;


" app.dic" save
