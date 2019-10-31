\ Load file for robot car controlled from MQTT
\ Pin Assignment

\ RFID:        \ using hardware SPI
\ 0 RFID-nRST  \ fixed hardware pin
\ 5 RFID-SCK   \ fixed hardware pin
\ 6 RFID-MISO  \ fixed hardware pin
\ 7 RFID-MOSI  \ fixed hardware pin
\ 8 RFID-CS    \ hardware pin, can be changed

\ Alcohol sensor
\  A0 for analog
3 constant sober-pin

\ D1 Mini LED
4 constant led-pin

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

: init-led  ( -- )  0 gpio-output led-pin gpio-mode  ;
: led!  ( flag -- )  0<> 1 and  led-pin gpio-pin!  ;
: led-off  ( -- )  true led!  ;
: led-on  ( -- )  false led!  ;

fl ${CBP}/sensors/rc522.fth

\ The server name or IP address is read at startup
\ time from the wifi-on file
0 defer mqtt-server$
\ Example: :noname " 192.168.4.254"  ; to mqtt-server$
: mqtt-client-id$  ( -- $ )  " Bender Car Starter"  ;
: mqtt-username$  ( -- $ )  " "  ;
: mqtt-password$  ( -- $ )  " "  ;
: mqtt-will$  ( -- msg$ topic$ )  " "  " "  ;
0 value mqtt-will-qos     \ 0, 1, 2, 3
0 value mqtt-will-retain  \ 0 or 1
0 value mqtt-clean-session
0 value mqtt-keepalive    \ seconds

fl ${CBP}/lib/mqtt.fth

false value blink-led?
also mqtt-topics definitions
: starter/led  ( value$ -- )
   ." LED " 2dup type cr
   2dup  " Blink" $=  if  2drop true to blink-led?  exit  then
   false to blink-led?
   " On"  $=  if  led-on  else  led-off  then
;
previous definitions

: blip  ( -- )  led-on #200 ms led-off #400 ms  ;
: ?blink  ( -- )
   blink-led?  if
      timer@ #2000000 mod  ( n )
      #1000000 >  if  led-on  else  led-off  then
   then
;

: buf>hex$   ( adr len -- $ )
   push-hex
   <#
   1- bounds  swap  do  i c@  u# u# drop  -1 +loop
   0 u#>
   pop-base
;
: publish-rfid  ( -- )
   get-rfid-tag  if   ( adr len )
      buf>hex$ " starter/rfid" 0 0 mqtt-publish-qos0
   then   
;

: sober?  ( -- flag )  sober-pin gpio-pin@  ;
false value last-sober?
: publish-alcohol  ( -- )
   sober? dup  last-sober?  <>  if  ( sober )
      dup  if  " On"  else  " Off"  then      ( sober? $ )
      " starter/sober" 0 0 mqtt-publish-qos0  ( sober? )
      to last-sober?                          ( )
   else                                       ( sober? )
      drop
   then
;

: mqtt-loop  ( -- )
   begin
      mqtt-fd do-tcp-poll  \ Handle input
      publish-rfid
      publish-alcohol

      \ Alcohol ...

      ?blink
      #50 ms
   key? until
;

: init-mq3  ( -- )
   0 gpio-input sober-pin gpio-mode
;

: run  ( -- )
   init-led
   init-rc522
   init-mq3

   blip
   " wifi-on" included
   led-off

   begin
      ['] mqtt-start catch
   while
      blip
      ." Waiting for MQTT server" cr
      key?  if  exit  then
   repeat
   ." Connected to MQTT server" cr

   led-on
   subscribe-all

   blip blip blip
   mqtt-loop
;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
\ : app  banner  hex init-i2c  showstack  quit  ;

: app
   banner  hex
   interrupt?  if  quit  then
   ['] load-startup-file catch drop
   ['] run catch .error
   quit
;


" app.dic" save
