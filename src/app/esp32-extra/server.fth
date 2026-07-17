marker -server.fth lastacf .name #20 to-column .( 27-04-2026 )
\ wifi-sta-on has been replaced bij logon 

: tcp-send  ( adr len handle -- )  lwip-write drop  ;

fl ../../lib/httpserver.fth

[ifndef] listener-socket 
   -1 value listener-socket 
[then]

: http-listen  ( -- )
   #80 start-server to listener-socket
   listener-socket 0< abort" http-listen failed"
   cr ." Listening on http://" ipaddr@ .ipaddr
;

\needs d!  : d!  ( d addr -- )  tuck na1+ ! ! ;

\ Accept incoming connections, blocking for at most "milliseconds"
\ Returns true on timeout, socket under false for connection accepted
2variable xfds  2variable wfds  2variable rfds 0 , 0 ,
: timed-accept  ( millseconds -- true | socket false )
   1. listener-socket dlshift rfds d!   ( seconds )
   xfds wfds rfds  listener-socket 1+  lwip-select  ( nfds )
   0<=  if  true exit  then
   #16 sp@  here listener-socket lwip-accept nip false  ( socket false )
;

create-timer: timer-reconnect
#7 ( mimutes ) #60 * s>f f# 1000000 f* fvalue us-reconnect-after

: reconnect ( -- )
   timer-reconnect @ 0= if
      cr ." No connection." listener-socket if
         lsock lwip-close listener-socket lwip-close 0 to listener-socket 
      then
      timer-reconnect start-timer  \ no connection
   else
       us-reconnect-after timer-reconnect tElapsed? if
         try-logon if
            timer-reconnect off http-listen space
         else
            timer-reconnect start-timer
         then
      then
   then
;
: accept-reconnect  ( millseconds -- true | socket false )
   wifi-connected@ 0= if    
      vtaskdelay reconnect true
   else  
      timed-accept
   then
;
\ Hook for stuff that needs to happen periodically
defer handle-timeout  ' noop to handle-timeout

\ Set this value, perhaps dynamically, to control how often,
\ in the absence of incoming requests, the HTTP server calls
\ handle-timeout to do other stuff.  handle-timeout is also
\ called after each request is handled, so HTTP traffic will
\ not starve periodic activity.
#1000 value poll-interval

2variable &linger 1 &linger !
: set-linger ( seconds - ) &linger cell+ ! ;
#1 set-linger

$1400 constant /req-buf
/req-buf buffer: req-buf

: http-respond  ( timeout -- )
   timed-accept if  exit  then  >r
 \ Set SO_LINGER so lwip-close does not discard any pending data
 \ 8 &linger $80 $fff r@  setsockopt drop
   #200 ms req-buf /req-buf r@  try-receive ( len ) dup if
      req-buf swap r@ handle-rcv     ( )
   then
      #500 ms
   r> lwip-close
;

defer responder
' http-respond  to responder
: serve-http  ( -- )
   begin  poll-interval responder handle-timeout  key? until   key drop
;
