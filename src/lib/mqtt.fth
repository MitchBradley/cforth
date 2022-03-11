\ MQTT Client
\ MQTT is a lightweight protocol for transmitting
\ sensor data and receiving control command over TCP.
\ It relies on a server program to collect data from
\ many sensors and distribute command to controls.

\ This implementation currently supports only QOS 0 -
\ one-shot, unacknowledged transmission.  The message
\ types for supporting the QOS 1 and QOS 2 sequences
\ are defined, but the logic is stubbed-out.  See
\ handle-pub{ack,rec,rel,comp}

\ Define these configuration parameters externally, e.g.:
\ : mqtt-server$  ( -- $ )  " 192.168.2.11"  ;
\ : mqtt-client-id$  ( -- $ )  " Sonoff Switch Forth"  ;
\ : mqtt-username$  ( -- $ )  " thisDevice"  ;
\ : mqtt-password$  ( -- $ )  " 12344321"  ;
\ 0 value mqtt-will-qos     \ 0, 1, 2, 3
\ 0 value mqtt-will-retain  \ 0 or 1
\ 0 value mqtt-clean-session
\ 0 value mqtt-keepalive

: mqtt-port$  " 1883"  ;

0 value mqtt-fd
: mqtt-send  ( adr len -- )
   mqtt-fd tcp-write 0< abort" tcp-write-failed"
;

0 [if] \ esp8266 code
\ XXX change this to use mqtt-fd instead of rx-pcb
: mqtt-send  ( adr len -- )
   ['] tcp-sent rx-pcb tcp-sent  ( adr len )
   rx-pcb tcp-write drop  ( )
;
: mqtt-poll  ( -- )  #100 ms  ;
[then]
0 [if] \ ESP32
\ The server name or IP address is read at startup
\ time from the wifi-on file
: server$  " 192.168.2.11" ;

#256 constant /mqtt-buffer
defer handle-peer-data
/mqtt-buffer buffer: mqtt-buffer
: mqtt-poll  ( fd -- )
   >r
   #50 ms
   mqtt-buffer /mqtt-buffer r@ lwip-read  ( count )
   dup 0>  if  ( count )
      mqtt-buffer swap  r@ handle-peer-data
   else  ( count )
      drop
   then
   r> drop
;
[then]

vocabulary mqtt-topics

\needs be-w@  : be-w@  ( adr -- w )  dup 1+ c@  swap c@  bwjoin  ;

: mqtt-flags  ( -- b )
   0
   mqtt-username$ nip  if  $80 or  then
   mqtt-password$ nip  if  $40 or  then
   mqtt-will$ nip nip nip  if
      $04 or
      mqtt-will-qos 3 lshift or
      mqtt-will-retain 5 lshift or
   then
   mqtt-clean-session  if  $02 or  then
;

0 value mqtt-msg
: mqtt-release-msg  ( -- )
   mqtt-msg  if
      mqtt-msg here - allot
      0 to mqtt-msg
   then
;
: m,  ( byte -- )  c,  ;
: mw,  ( short -- )  dup 8 rshift m,  m,  ;
: m-payload,  ( adr len -- )
   here over allot   ( adr len dst-adr )
   swap move         ( )
;
: m$,  ( adr len -- )
   dup mw,       ( adr len )
   m-payload,
;
: ?m$,  ( adr len -- )  dup  if  m$,  else  2drop  then  ;

: mqtt{  ( control -- )  here to mqtt-msg  m,  0 m,  ; 
: }mqtt  ( -- )
   mqtt-msg  here over -  ( adr len )
   2dup 2-  swap 1+ c!    ( adr len )  \ Set length field
   mqtt-send
   mqtt-release-msg       ( )
;
false value mqtt-connack?
0 value mqtt-session-present
: mqtt-connect  ( -- )
   false to mqtt-connack?
   0 to mqtt-session-present
   $10 mqtt{
      " MQTT" m$,    \ Protocol Name
      4 m,           \ Protocol Level
      mqtt-flags m,
      mqtt-keepalive mw,
      mqtt-client-id$ m$,
      mqtt-will$  dup  if   ( msg$ topic$ )
         m$, m$,
      else
         2drop 2drop
      then
      mqtt-username$ ?m$,
      mqtt-password$ ?m$,
   }mqtt
;

: mqtt-publish-qos0  ( payload$ topic$ dup retain -- )
   $30                ( payload$ topic$ dup retain control )
   swap 0<> 1 and or  ( payload$ topic$ dup control )
   swap 0<> 8 and or  ( payload$ topic$ control )
   mqtt{              ( payload$ topic$ )
      m$,             ( payload$ )
      m-payload,      ( )
   }mqtt
;

\ There is no receiver response to a QOS 0 publish
: mqtt-publish-qos  ( payload$ topic$ dup retain id qos -- )
   swap >r                ( payload$ topic$ dup retain qos r: id )
   $30                    ( payload$ topic$ dup retain id qos control )
   swap 2 max 1 shift or  ( payload$ topic$ dup retain id control r: id )
   swap 0<> 1 and or      ( payload$ topic$ dup control r: id )
   swap 0<> 8 and or      ( payload$ topic$ control r: id )
   mqtt{                  ( payload$ topic$ r: id )
      m$,                 ( payload$ r: id )
      r> mw,              ( payload$ )
      m-payload,          ( )
   }mqtt
;

\ Receiver responds with this for QOS 1
: mqtt-puback  ( id )  $40 mqtt{ mw, }mqtt  ;

\ Receiver responds with this for QOS 2
: mqtt-pubrec  ( id )  $50 mqtt{ mw, }mqtt  ;

\ Sender then sends this third stage for QOS2
: mqtt-pubrel  ( id -- )  $60 mqtt{ mw, }mqtt  ;

\ Receiver responds with this fourth and final stage for QOS2
\ PUBCOMP $70 $02 packet-id.w  \ QOS 2
: mqtt-pubcomp  ( id )  $70 mqtt{ mw, }mqtt  ;

: mqtt-subscribe  (  n*[ qos topic$ ] n id -- )
   $82 mqtt{   ( n*[ qos topic$ ] n id )
     mw,       ( n*[ qos topic$ ] n )
     0  do     ( n*[ qos topic$ ] )
       m$, m,  ( m*[ qos topic$ ] )
     loop      ( )
   }mqtt
;

: subscribe-all  ( -- )
   ['] mqtt-topics follow
   begin  another?  while
      >name$
      ." Subscribing to " 2dup type cr
      0 -rot  1 #1234 mqtt-subscribe
   repeat
;

: mqtt-unsubscribe  ( n*topic$ n id -- )
   $a0 mqtt{  mw,      ( n*topic$ n )
      0 do  m$,  loop  ( )
   }mqtt
;

: mqtt-pingreq  ( -- )  $c0 mqtt{  }mqtt  ;

: mqtt-disconnect  ( -- )  $e0 mqtt{  }mqtt  ;

: handle-puback  ( id -- )  ." Puback " .d cr  ;
: handle-pubrec  ( id -- )  ." Pubrec " .d cr  ;
: handle-pubrel  ( id -- )  ." Pubrel " .d cr  ;
: handle-pubcomp  ( id -- )  ." Pubcomp " .d cr  ;
: handle-suback  ( adr len -- )
   dup 3 <  if    ( adr len )
      ." SUBACK short packet" cr  exit
   then             ( adr len )
   over be-w@ drop  ( adr len )
   2 /string        ( adr' len' )
   0 do             ( adr )
     dup i + c@ $80 and  if  ( adr )
        ." Subscription " i . ." failed" cr
     then                    ( adr )
   loop             ( adr )
   drop             ( )
;
: handle-unsuback  ( id -- )  drop  ." Unsubscribed" cr  ;
: handle-pingresp  ( -- )  ." PONG" cr  ;
: >payload&topic  ( adr len -- payload$ topic$ )
   over be-w@ >r  ( adr len r: topic-len )
   2 /string      ( topic-adr totlen r: topic-len )
   over r@        ( topic-adr totlen topic-adr topic-len r: topic-len)
   2swap r> /string  ( payload$ topic$ )
   2swap          ( payload$ topic$ )
;
: handle-publish  ( adr len -- )
   dup 2 <  if          ( adr len )
      ." Short MQTT PUBLISH" cr
      2drop exit
   then              ( adr len )
   >payload&topic    ( payload$ topic$ )
   2dup  ['] mqtt-topics search-wordlist  if  ( payload$ topic$ xt )
      nip nip execute                         ( )
   else                                       ( payload$ topic$ )
      ." No MQTT handler for topic " type  cr ( payload$ )
      2drop
   then
;

: ?badlen  ( len explen msg$  -- )
   2swap <>  if  ( msg$ )
      type ."  bad message length" cr
   else
      2drop
   then
;

\ Called when a TCP packet is received
: mqtt-handle-message  ( adr len -- )
   over c@  >r  2 /string  r>  ( adr' len' type )
   4 rshift  case              ( adr len )
      $2  of   \ CONNACK  $20 $02 sp ret
         2 " CONNACK" ?badlen
         dup c@ 1 and 0<> to mqtt-session-present
         1+ c@  ?dup  if       ( error )
            ." MQTT session refused - "
            case
               1 of  ." bad protocol version"   endof
               2 of  ." identifier rejected"    endof
               3 of  ." server unavailable"     endof
               4 of  ." bad username/password"  endof
               5 of  ." not authorized"         endof
               ( default )  ." ?"
            endcase
            cr
            exit
         then
         true to mqtt-connack?
      endof

      $3  of  \ PUBLISH  $30 len topic$ value$
         ( adr len ) handle-publish
      endof

      $4  of  \ PUBACK   $40 $02 packet-id.w
         2 " PUBACK" ?badlen
         be-w@ handle-puback
      endof
      $5  of  \ PUBREC   $50 $02 packet-id.w
         2 " PUBREC" ?badlen
         be-w@ handle-pubrec
      endof
      $6  of  \ PUBREL   $60 $02 packet-id.w
         2 " PUBREL" ?badlen
         be-w@ handle-pubrel
      endof
      $7  of  \ PUBCOMP  $70 $02 packet-id.w
         2 " PUBCOMP" ?badlen
         be-w@ handle-pubcomp
      endof
      $9  of  \ SUBACK   $90 len id.w (len-2)*[$80|QOS]  $80 bit means fail - it is 0 for success
         handle-suback
      endof
      $b  of  \ UNSUBACK $b0 02 id.w
         2 " UNSUBACK" ?badlen
         be-w@ handle-unsuback
      endof
      $d  of  \ PINGRESP $d0 00
         2drop handle-pingresp
      endof
      ( default )  nip nip
   endcase   
;
: mqtt-received  ( adr len peer -- )
   drop                    ( adr len )
   begin  dup 2 >=  while  ( adr len )
      over 1+ c@ 2+ >r     ( adr len r: thislen )
      over r@ mqtt-handle-message  ( adr len r: thislen )
      r> /string           ( adr' len' )
   repeat                  ( adr' len' )
   2drop
;

: mqtt-start  ( -- )
   ['] mqtt-received to handle-peer-data

   #50 mqtt-port$ mqtt-server$ stream-connect to mqtt-fd
   mqtt-fd 0< abort" Failed to connect to MQTT server"

   mqtt-connect
   begin  mqtt-fd do-tcp-poll  mqtt-connack? until
;
