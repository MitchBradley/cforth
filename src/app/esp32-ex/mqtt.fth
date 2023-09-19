\ The server name or IP address is read at startup
\ time from the wifi-on file

\ XXX get this from the file system
: server$  ( -- $ )  " 192.168.2.11"  ;

: mqtt-server$  ( -- $ )  " server$" evaluate  ;
: mqtt-client-id$  ( -- $ )  " ESP32 Forth"  ;
: mqtt-username$  ( -- $ )  " "  ;
: mqtt-password$  ( -- $ )  " "  ;
: mqtt-will$  ( -- msg$ topic$ )  " "  " "  ;
0 value mqtt-will-qos     \ 0, 1, 2, 3
0 value mqtt-will-retain  \ 0 or 1
0 value mqtt-clean-session
0 value mqtt-keepalive    \ seconds

: tcp-write  ( adr len fd -- #written )  lwip-write  ;
#256 constant /mqtt-buffer
defer handle-peer-data
/mqtt-buffer buffer: mqtt-buffer
: do-tcp-poll  ( fd -- )
   >r
   #50 ms
   mqtt-buffer /mqtt-buffer r@ lwip-read  ( count )
   dup 0>  if
      mqtt-buffer swap  r@ handle-peer-data
   else
      drop
   then
   r> drop
;

fl ${CBP}/lib/mqtt.fth
