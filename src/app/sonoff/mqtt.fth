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
\ create mqtt-server-ip  #192 c, #168 c, 2 c, #11 c,
\ : mqtt-client-id$  ( -- $ )  " Sonoff Switch Forth"  ;
\ : mqtt-username$  ( -- $ )  " thisDevice"  ;
\ : mqtt-password$  ( -- $ )  " 12344321"  ;
\ 0 value mqtt-will-qos     \ 0, 1, 2, 3
\ 0 value mqtt-will-retain  \ 0 or 1
\ 0 value mqtt-clean-session
\ 0 value mqtt-keepalive

vocabulary mqtt-topics

#1883 constant mqtt-port#  \ #8883 for TLS
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
: mqtt-sent  ( len pcb arg -- err )
   2drop  ( len )
   drop
   ERR_OK
;
: }mqtt  ( -- )
   mqtt-msg  here over -  ( adr len )
   2dup 2-  swap 1+ c!    ( adr len )  \ Set length field
   ['] mqtt-sent rx-pcb tcp-sent  ( adr len )
   rx-pcb tcp-write drop  ( )
   mqtt-release-msg       ( )
;
false value tcp-connected?
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
   ['] mqtt-topics search-wordlist  if  ( payload$ xt )
      execute                           ( )
   else                                 ( payload$ )
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
: mqtt-received  ( adr len peer -- )
   drop                 ( adr len )
   dup 2 <  if          ( adr len )
      ." Short MQTT packet" cr
      2drop exit
   then                        ( adr len )
   over 1+ c@ 2+  over <>  if  ( adr len )
      ." MQTT length mismatch " dup . cr
      push-hex cdump pop-base  ( adr len )      
      2drop exit
   then                        ( adr len )

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

: mqtt-connected  ( err pcb arg -- stat )
   drop to rx-pcb               ( err )
   ?dup  if                     ( err )
      ." Connect failed, err = " .x  cr 
   else                         ( )
      true to tcp-connected?
      ['] receiver      rx-pcb tcp-recv
      ['] error-handler rx-pcb tcp-err
      ['] mqtt-sent     rx-pcb tcp-sent
   then

   ERR_OK
;

\needs resolve fl ${CBP}/app/esp8266/resolve.fth

: mqtt-start  ( -- )
   false to tcp-connected?
   ['] mqtt-received to handle-peer-data
   ['] false to respond  \ Don't close the connection

   ['] mqtt-connected mqtt-port#  ( cb port# )
   mqtt-server$ resolve-host      ( cb port# 'host )
   tcp-new                        ( cb port# 'host pcb )
   tcp-connect  0<> abort" mqtt-start failed"
   begin  #100 ms  tcp-connected? until
   mqtt-connect
   begin  #100 ms  mqtt-connack? until
;
