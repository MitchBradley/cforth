4 buffer: host-ip
: resolve-host  ( ip$ -- 'ip )
   2>r
   host-ip off
   host-ip ['] dns-handler host-ip 2r> dns-gethostbyname  ( res )
   \ Returns 0 if the name is resolved immediately
   dup 0=  if  drop exit  then
   \ Returns $f4 on error
   $f4 = abort" DNS resolve argument error"
   \ Returns $fb if a request must be sent
   #100 0  do
      host-ip @   if  host-ip unloop exit  then
      #100 ms
   loop
   true abort" DNS resolve timed out"
;
