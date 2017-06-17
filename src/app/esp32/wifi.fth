defer wifi-sta-ssid
: must-set-ssid  true abort" wifi-sta-ssid needs to be set"  ;
' must-set-ssid to wifi-sta-ssid
\ Example:  :noname " Belkin123" ;  to wifi-sta-ssid

defer wifi-sta-password
: null$ " " ;  ' null$ to wifi-sta-password
\ Example:  :noname " 9876asdf" ;  to wifi-sta-password

: wifi-sta-on
   0 " wifi" log-level!
   wifi-sta-ssid wifi-sta-password wifi-open drop
;

: ipaddr@  ( -- 'ip )  pad 0 ip-info@ drop  pad  ; \ 1 for AP, 0 for STA
: (.d)  ( n -- )  push-decimal (.) pop-base  ;
: .ipaddr  ( 'ip -- )
   3 0 do  dup c@ (.d) type ." ." 1+  loop  c@ (.d) type
;
