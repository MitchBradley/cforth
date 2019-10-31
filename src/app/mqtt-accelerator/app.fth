\ Weight sensor accelerator
\ Pin Assignment
\ HX711:
\   1 SCK
\   3 DOUT
\ RGB LED
\   2 LED control pin

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

\ LED on D1 Mini CPU module
4 constant d1mini-led-pin
: init-d1mini-led  ( -- )  0 gpio-output d1mini-led-pin gpio-mode  ;
: led-on  ( -- )  0 d1mini-led-pin gpio-pin!  ;
: led-off  ( -- )  1 d1mini-led-pin gpio-pin!  ;

fl ../esp8266/wemos-rgb-led.fth
fl ../../sensors/hx711.fth
1 to hx711-sck-pin
3 to hx711-dout-pin
-1 to hx711-polarity

defer mqtt-server$
: mqtt-client-id$  ( -- $ )  " Bender Car Accelerator"  ;
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

\needs sprintfs fl ${CBP}/cforth/printf.fth

: hex?  ( $ -- n true | $ false )
   2dup push-hex $number? pop-base  if  ( $ n 0 )
      drop nip nip true                 ( n true )
   else                                 ( $ )
      false
   then
;
false value send-weight?
false value blink-led?
: ?blink-led  ( -- )
   blink-led?  if
      timer@ #2000000 mod
      #1000000 >  if  $2200  else  0  then  led!
   then
;

also mqtt-topics definitions
\ Value is a color - black blue green red cyan yellow magenta white orange
: accelerator/led  ( value$ -- )
   ." LED " 2dup type cr      ( value$ )
   2dup " Blink" $=  if
      2drop  true to blink-led?  exit
   then
   false to blink-led?
   hex?  if  led! exit  then  ( value$ )
   " %s-led" sprintf          ( cmd$ )
   $find  if  execute  else  2drop  then  ( )
;
\ Value is On or Off
: accelerator/send  ( value$ -- )
   ." Send " 2dup type
   " On" $=  to send-weight?
   send-weight?  if  $220800 led!  ( dim orange )   else  black-led  then
;
previous definitions

: mqtt-loop  ( -- )
   begin
      mqtt-fd do-tcp-poll  \ Handle input
      hx711-sample >lbs$ 2dup type (cr  ( lbs$ )
      send-weight?  if
         " accelerator/lbs"  0 0 mqtt-publish-qos0
      else
         2drop
      then
      ?blink-led
      #10 ms
   key? until  key drop
;
: blip  ( -- )  led-on #200 ms led-off #400 ms  ;
: run  ( -- )
   init-d1mini-led
   init-wemos-led
   init-hx711
   led-on
   hx711-tare

   blip
   " wifi-on" included
   led-off

   begin
      ['] mqtt-start catch
   while
      blip
      ." Waiting for MQTT server" cr
      key?  if  key drop exit  then
   repeat

   led-on
   subscribe-all

   blip blip blip
   mqtt-loop
;

: app
   banner  hex
   interrupt?  if  quit  then
   ['] load-startup-file catch drop
   ['] run catch .error
   quit
;


" app.dic" save
