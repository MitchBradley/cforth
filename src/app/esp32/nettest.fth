\ WIP test code for network functions

: ipaddr@  ( -- 'ip )  pad 0 ip-info@ drop  pad  ; \ 1 for AP, 0 for STA
: (.d)  ( n -- )  push-decimal (.) pop-base  ;
: .ipaddr  ( 'ip -- )
   3 0 do  dup c@ (.d) type ." ." 1+  loop  c@ (.d) type
;

-1 value listen-socket
: wifion
   0 " wifi" log-level!
   " OpenWrt-Bradley" " BunderditBaby" wifi-open drop
   #80 start-server to listen-socket
   ." Listening on " ipaddr@ .ipaddr ." :80" cr
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

: ipaddr@  ( -- 'ip )  pad 1 wifi-ip-info@ drop  pad  ; \ 1 for AP, 0 for STA
: (.d)  ( n -- )  push-decimal (.) pop-base  ;
: .ipaddr  ( 'ip -- )
   3 0 do  dup c@ (.d) type ." ." 1+  loop  c@ (.d) type
;
: .ip/port  ( adr -- )
   dup 0=  if  drop ." (NULL)" exit  then
   ." Local: " dup 2 la+ .ipaddr ." :" dup 1 la+ l@ .d
   ." Remote: " dup 3 la+ .ipaddr ." :" l@ .d
;
: .listen  ( -- )
   
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

