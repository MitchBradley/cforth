\ Example for using MQTT on ESP32
\ It publishes keystrokes under the topic /key
\ and subscribes to messages under the topic /type

\ Change this to the IP address of your MQTT server
: server$  ( -- $ )  " 192.168.2.11"  ;

\ MQTT Configuration
: mqtt-server$  ( -- $ )  " server$" evaluate  ;
: mqtt-client-id$  ( -- $ )  " ESP32 Forth"  ;
: mqtt-username$  ( -- $ )  " "  ;
: mqtt-password$  ( -- $ )  " "  ;
: mqtt-will$  ( -- msg$ topic$ )  " "  " "  ;
0 value mqtt-will-qos     \ 0, 1, 2, 3
0 value mqtt-will-retain  \ 0 or 1
0 value mqtt-clean-session
0 value mqtt-keepalive    \ seconds

\ Implement a couple of interfaces that the MQTT code
\ uses on top of the ESP32's LWIP-flavored TCP stack
fl mqtt-interface.fth

\ Common code for MQTT protocol
fl ${CBP}/lib/mqtt.fth

\ MQTT output devices
also mqtt-topics definitions
: /type  ( value$ -- )  type  ;
previous definitions

\ MQTT sensors
1 buffer: 'key
: publish-key  ( c -- )
   'key c!  'key 1  " /key"  0 0 mqtt-publish-qos0
;

: run  ( -- )
   " wifi-on" included

   \ Start WiFi and establish a connection to the MQTT server
   mqtt-start

   \ Subscriptions
   0 " /type"  1  #1234 mqtt-subscribe

   \ Handle incoming events on subscribed topics
   \ and publish keystrokes typed on the serial console
   begin
      mqtt-fd do-tcp-poll
      key?  if
         key dup $1b =  if  drop exit  then  \ Exit when ESC pressed
         publish-key
      then
      \ Check sensors and publish data if appropriate
   again
;
