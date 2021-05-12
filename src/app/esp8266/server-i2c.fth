#80 value port   0 value server  0 value client
: t ( adr len -- )  client send ?dup  if  ." T " . cr  then  ;
\ : tcr ( -- )  " "r"n" t  ;
: hdr  " <h1> Sensor Status</h1>" t ;
: but1  " <p>GPIO0 <a href=""?pin=ON1""><button>ON</button></a>&nbsp;<a href=""?pin=OFF1""><button>OFF</button></a></p>" t ;
: but2  " <p>GPIO2 <a href=""?pin=ON2""><button>ON</button></a>&nbsp;<a href=""?pin=OFF2""><button>OFF</button></a></p>" t ;

: temperature  ( -- )
   " <p>Temperature: " t  ds18x20-temp$ t  " C</p>" t
;
0 value dist
: get-distance  ( -- )  vl-distance to dist  ;
0 value timer1
: setup-timer  ( -- )
   vl-distance to dist
   ['] get-distance new-timer to timer1
   #2000 1 1 timer1 arm-timer
;
: distance  ( -- )
\   " <p>Distance: " t  vl-distance  (.d) t  " mm</p>" t
   " <p>Distance: " t  dist (.d) t  " mm</p>" t
;
: homepage  ( -- )
   \ hdr but1 but2
   hdr
   distance
;
rats
: rcv   ( adr len handle -- )
   to client                            ( adr len )
   5 client tcp-bufcnt!
   \ client .espconn   
   http-get?  if                        ( url$ )
      2dup " /favicon.ico" compare 0=  if   ( url$ )
         2drop                          ( )
      else                              ( url$ )
         ." URL: " type cr              ( )
         homepage
      then
   else
      2drop
\      type
   then
\   client tcp-disconnect
;
: ds ." Disconn " .espconn ;  : cn ." Conn " .espconn ;  : tx ." Sent " .espconn ;
: serve
   init-all  setup-timer
   0 0 0  \ 0 ['] ds ['] cn
   0 ['] rcv  " 0.0.0.0" port #400 tcp-listen to server
   ." Serving " .ssid space ipaddr@ .ipaddr cr
;
: unserve  ( -- )  server unlisten  ;

: reply  ( -- )  " Okay!"r"n" client send client tcp-disconnect  ;
: r1 0 parse client send " "r"n" client send  ;
: r r1 client tcp-disconnect  ;

: udp-serve   0 ['] rcv " 0.0.0.0" #1234 udp-listen to server  ;
