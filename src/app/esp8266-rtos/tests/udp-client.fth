\ It is best to put these in a separate file
\ :noname " YourWiFiSSID" ;  to wifi-sta-ssid
\ :noname " YourWifiPassword" ;  to wifi-sta-password

\ On a Linux host, you can run a simple UDP server to test this with
\   nc -lup 20000
\ If you run send-udp-hello twice, only the first message will show up.
\ The reason is because each time that send-upd-hello open a udp socket,
\ a different outgoing UDP port number is used.  nc binds to the first
\ such port and then ignores subsequent requests coming from different
\ outgoing ports.  If you restart nc before each send-udp-hello, it will
\ work.  It will also work if you send multiple messages with lwip-write,
\ without closing the UDP socket in between.

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
