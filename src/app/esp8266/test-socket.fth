fl wifi.fth
fl tcpnew.fth

create host #192 c, #168 c, #2 c, #100 c,
#22 constant ssh-port

: wifi-connect  ( -- )  " mySSID" " myPassword" station-connect  ;

\ This is called when data is received from the TCP connection
: handle-ssh-data  ( adr len peer -- )
   drop  ." SSH server said: " cr
   type
;

\ This is called when the connection succeeds
: ssh-connected  ( err pcb arg -- stat )
   ." Connected" cr   drop nip   ( pcb )

   \ Install handlers for TCP callbacks
   ['] receiver      over tcp-recv  ( pcb )
   ['] error-handler over tcp-err   ( pcb )
   ['] sent-handler  over tcp-sent  ( pcb )
   drop

   ERR_OK
;

: probe-ssh  ( -- )
   wifi-connect

   \ Install Rx data handler
   ['] handle-ssh-data to handle-peer-data


   \ Install responder
   \ This closes the connection after data is received
   \ Just returning true is fine for a one-shot connection
   \ where you want to grab some data and exit.  For a
   \ more complex scenario, you would have handle-peer-data
   \ save the data, do something with it, then have respond
   \ call tcp-write-wait to send some data back over the
   \ connection, only returning true when all is finished.
   ['] true to respond

   \ Install connect handler
   ['] ssh-connected to connected

   ssh-port host connect       ( pcb )
;
