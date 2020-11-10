\ It is best to put these in a separate file
\ :noname " YourWiFiSSID" ;  to wifi-sta-ssid
\ :noname " YourWifiPassword" ;  to wifi-sta-password

\ On a Linux host, you can run a simple UDP server to test this with
\   nc -lup 20000

: udp-host$ " 192.168.2.194" ;
: udp-port$ " 20000" ;

0 value udp-socket
: send-udp-hello  ( -- )
   start-wifi-sta  \ Stays connected; can be called again

   0 " *" log-level!
   udp-port$ udp-host$ udp-connect to udp-socket
   " Hello from CForth"r"n" udp-socket lwip-write
   ." Wrote " .d ." bytes" cr
   udp-socket lwip-close  0 to udp-socket
;
