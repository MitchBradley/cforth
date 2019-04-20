\ Interface between the platform-independent HTTP server code in lib/
\ and the platform-specific TCP code.

\ Platform code defines
\  tcp-send ( adr len peer -- )  \ Call to send data back
\  defer handle-peer-data  ( adr len peer -- )  \ Called when data comes in

fl ../../lib/httpserver.fth

' handle-rcv to handle-peer-data

\ The return value of respond says whether or not to close the connection
' true to respond
