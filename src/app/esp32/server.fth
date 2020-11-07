: tcp-send  ( adr len handle -- )  lwip-write drop  ;

fl ../../lib/httpserver.fth

-1 value listener-socket
: http-listen  ( -- )
   #80 start-server to listener-socket
   listener-socket 0< abort" http-listen failed"
   ." Listening on " ipaddr@ .ipaddr ." :80" cr
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

\ Hook for stuff that needs to happen periodically
defer handle-timeout  ' noop to handle-timeout

\ Set this value, perhaps dynamically, to control how often,
\ in the absence of incoming requests, the HTTP server calls
\ handle-timeout to do other stuff.  handle-timeout is also
\ called after each request is handled, so HTTP traffic will
\ not starve periodic activity.
#1000 value poll-interval

create &linger 1 , 5 ,  \ on , 5 seconds

#1024 constant /req-buf
/req-buf buffer: req-buf

: http-respond  ( timeout -- )
   timed-accept if  exit  then  >r

   \ Set SO_LINGER so lwip-close does not discard any pending data
\   8 &linger $80 $fff r@  setsockopt drop

   req-buf /req-buf r@ lwip-read  ( len )
   req-buf swap r@ handle-rcv     ( )
   #500 ms

   r> lwip-close
;

defer responder
' http-respond  to responder
: serve-http  ( -- )
   begin  poll-interval responder handle-timeout  key? until   key drop
;
