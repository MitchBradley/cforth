: i2c-init  #100000 3 4 0 i2c-setup drop  ;
: bwjoin  ( l h -- w )  8 lshift or  ;
: ina@  ( reg# -- w )
  0 i2c-start  0 $40 0 i2c-address drop  0 i2c-send-byte  0 i2c-stop
  0 i2c-start  1 $40 0 i2c-address drop  1 0 i2c-recv-byte  0 0 i2c-recv-byte  0 i2c-stop
  swap bwjoin
;

#80 value port   0 value server  0 value client
: t ( adr len -- )  client send ?dup  if  ." T " . cr  then  ;
\ : tcr ( -- )  " "r"n" t  ;
: hdr  " <h1> Sensor Status</h1>" t ;
: but1  " <p>GPIO0 <a href=""?pin=ON1""><button>ON</button></a>&nbsp;<a href=""?pin=OFF1""><button>OFF</button></a></p>" t ;
: but2  " <p>GPIO2 <a href=""?pin=ON2""><button>ON</button></a>&nbsp;<a href=""?pin=OFF2""><button>OFF</button></a></p>" t ;
: rx   ( adr len handle -- )
   to client                            ( adr len )
   5 client tcp-bufcnt!
   \ client .espconn   
   http-get?  if                        ( url$ )
      2dup " /favicon.ico" compare 0=  if   ( url$ )
         2drop                          ( )
      else                              ( url$ )
flatso         ." URL: " type cr              ( )
         hdr but1 but2
      then
   else
      type
   then
   client tcp-disconnect
;
: ds ." Disconn " .espconn ;  : cn ." Conn " .espconn ;  : tx ." Sent " .espconn ;
: serve
   0 0 0  \ 0 ['] ds ['] cn
   0 ['] rx  " 0.0.0.0" port #400 tcp-listen to server
   ." Serving " .ssid space ipaddr@ .ipaddr cr
;
: unserve  ( -- )  server unlisten  ;

: reply  ( -- )  " Okay!"r"n" client send client tcp-disconnect  ;
: r1 0 parse client send " "r"n" client send  ;
: r r1 client tcp-disconnect  ;

: udp-serve   0 ' rx " 0.0.0.0" #1234 udp-listen to server  ;
serve
