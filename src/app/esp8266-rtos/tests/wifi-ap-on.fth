: ApSSID  " ApSSID" ;
: ApPassword  " ApPassword" ;

\ Number of simultaneous connections to the access point
\ Each connection uses memory and CPU so do not make this too large.
4 value wifi-max-connections

0 value wifi-storage  \ 0 for FLASH, 1 for RAM

: wifi-station-on  ( -- )
   wifi-mode@ case
      0 of  endof
      1 of
        ." WiFi is already on in station mode; type wifi-off to stop it" cr
        exit
      endof
      2 of
        \ Do nothing if Access Point is already on
        exit
      endof
      3 of
        ." WiFi is already on in Sta+AP mode; type wifi-off to stop it" cr exit
      endof
   endcase

   wifi-max-connections wifi-storage ApSSID ApPassword wifi-open-ap
   abort" WiFi access point startup failed"
;
