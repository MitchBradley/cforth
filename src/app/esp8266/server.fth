: tcp-send  ( adr len handle -- )
   begin       ( adr len handle )
      3dup send
      case     ( adr len handle )
         0 of  3drop  exit  endof  ( adr len handle )
        -7 of  'W' sys-emit #400 ms 'w' sys-emit  endof  ( adr len )  \ retry after a delay
        ( default )  ." TCP error " .d cr  3drop exit
      endcase
   again
;

fl ../../lib/httpserver.fth

\ Due to ESP8266 callback timing requirements, it's dangerous to
\ reply directly from within the receive callback handler, so
\ we save the incoming data in a buffer, then schedule an alarm
\ to fire 2 milliseconds later and do the work of replying then.

#256 constant /req-buf
/req-buf buffer: req-buf
0 value req-len
: save-req  ( adr len -- )
   dup to req-len      ( adr len )
   req-buf swap move   ( )
;

\ This is called from the alarm handler to do the work of
\ handling the request
: handle-rcv-later  ( -- )
   7 client tcp-bufcnt!
   \ client .espconn   
   req-buf req-len client handle-rcv
   client tcp-disconnect
;

\ This is the receive callback handler
: rcv   ( adr len handle -- )
." Client is " dup . cr
   to client   save-req    ( )
   \ Schedule the work for later so we do not have
   \ nested callbacks if the reply takes a long
   \ time and must do "ms" to avoid watchdogs.
   ['] handle-rcv-later 2 set-alarm
;

\ : ds ." Disconn " .espconn ;  : cn ." Conn " .espconn ;  : tx ." Sent " .espconn ;
0 value server
#80 value port
: serve
   server-init
   0 0 0  \ 0 ['] ds ['] cn
   0 ['] rcv  " 0.0.0.0" port #400 tcp-listen to server
   ." Serving " .ssid space ipaddr@ .ipaddr cr
;
: unserve  ( -- )  server unlisten  ;

: udp-serve   0 ['] rcv " 0.0.0.0" #1234 udp-listen to server  ;
