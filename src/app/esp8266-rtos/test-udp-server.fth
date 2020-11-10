:noname  " YourWiFiSSID" ;  to wifi-sta-ssid
:noname  " YourWifiPassword"   ;  to wifi-sta-password

#20000 value udp-port#
0 value udp-socket
: print-udp  ( -- )
   start-wifi-sta  \ Stays connected; can be called again

   #20000 start-udp-server to udp-socket
   udp-socket 0< abort" Cannot create UDP socket"
   ." UDP listening on " ipaddr@ .ipaddr ."  port " udp-port# .d cr
   begin
      pad 100 udp-socket lwip-read  ( -n | #read )
      dup 0< if
         drop
         udp-socket lwip-close
         true abort" UDP read failed"
      then  ( #read )
      pad swap type
   again
;
