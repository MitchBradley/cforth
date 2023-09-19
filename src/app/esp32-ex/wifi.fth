defer wifi-sta-ssid
: must-set-ssid  true abort" wifi-sta-ssid needs to be set"  ;
' must-set-ssid to wifi-sta-ssid
\ Example:  :noname " Belkin123" ;  to wifi-sta-ssid

defer wifi-sta-password
: null$ " " ;  ' null$ to wifi-sta-password
\ Example:  :noname " 9876asdf" ;  to wifi-sta-password

#20000 value wifi-timeout
: wifi-sta-on  ( -- error? )
   0 " wifi" log-level!
   wifi-sta-ssid wifi-sta-password wifi-timeout wifi-open
;
: start-wifi-sta  ( -- )
   wifi-mode@ 0=  if
      wifi-sta-on abort" Cannot connect to WiFi"
   then
;

: ipaddr@  ( -- 'ip )  pad 0 ip-info@ drop  pad  ; \ 1 for AP, 0 for STA
: (.d)  ( n -- )  push-decimal (.) pop-base  ;
: ipaddr$  ( 'ip -- $ )
   push-decimal <#       ( 'ip )
      3 bounds swap  do  ( )     \ IP address is in reverse byte order
         i c@  u#s drop  ( )     \ Convert a byte
         '.' hold        ( )
      -1 +loop           ( )
   0 u#>  pop-base       ( $ )
   1 /string             ( $' )  \ Discard leading .
;
: .ipaddr  ( 'ip -- )  ipaddr$ type  ;
