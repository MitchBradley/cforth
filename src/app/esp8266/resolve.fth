\ DNS resolver.
\ resolve-host returns the address of a buffer containing an
\ IPv4 host address, given a string containing
\ either a DNS name or a dotted-decimal address.
\ Dotted-decimal addresses can be resolved immediately,
\ while DNS names usually require interaction with a
\ server.  If the address cannot be resolved,
\ resolve-host aborts.
: dns-handler  ( 'buf 'ipaddr 'name -- )
   drop  ?dup  if  ( 'buf 'ipaddr )
      swap 4 move
   else  ( buf )
      on
   then
;
4 buffer: host-ip
: resolve-host  ( ip$ -- 'ip )
   2>r
   host-ip off
   host-ip ['] dns-handler host-ip 2r> dns-gethostbyname  ( res )
   \ Returns 0 if the name is resolved immediately
   dup 0=  if  drop host-ip exit  then
   \ Returns $f4 on error
   $f4 = abort" DNS resolve argument error"
   \ Returns $fb if a request must be sent
   #100 0  do
      host-ip @   if  host-ip unloop exit  then
      #100 ms
   loop
   true abort" DNS resolve timed out"
;
