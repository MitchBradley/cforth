\ WIP test code for network functions

-1 value listen-socket
: wifion
   0 " wifi" log-level!
   " OpenWrt-Bradley" " BunderditBaby" wifi-open . dhcp-status .
   #80 start-server to listen-socket
;

create &linger 1 , 5 ,
: linger  ( socket -- )
   >r  8 &linger $80 $fff  r> setsockopt drop
;

create xfds 0 , 0 ,
create wfds 0 , 0 ,
create rfds 0 , 0 ,
: timed-accept  ( millseconds -- true | socket false )
   1 listen-socket << rfds !   ( seconds )
   xfds wfds rfds  listen-socket 1+  lwip-select  ( nfds )
   0<=  if  true exit  then
   #16 sp@  here listen-socket lwip-accept nip false  ( socket false )
;

: respond1  ( -- )
   #100 timed-accept if  exit  then  ( socket )
   >r                                 ( r: socket )
   r@ . cr
   r@ linger
   here 300 r@ lwip-read  here swap carret split-string 2drop type cr
   " Hello, there"r"n" r@ lwip-write drop
   r> lwip-close
;


: resp-key  ( -- )
   begin  key? 0=  while  respond1  repeat  key drop
;

wifion
resp-key

