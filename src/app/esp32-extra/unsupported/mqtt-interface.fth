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
