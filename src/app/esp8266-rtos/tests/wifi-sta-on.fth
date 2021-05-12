: StaSSID     " YourWiFiSSID" ;
: StaPassword " YourWifiPassword" ;

\ Number of milliseconds to wait for connection, irrespective of retries
#4000 to wifi-timeout

\ Retries: -1 for unlimited, 0 for none, otherwise that many
5 value wifi-#retries

0 value wifi-storage  \ 0 for FLASH, 1 for RAM

: wifi-station-on  ( -- )
   wifi-mode@ case
      0 of  endof
      1 of
        \ Do nothing if station is already on
        exit
      endof
      2 of
        ." WiFi is already on in AP mode; type wifi-off to stop it" cr
        exit
      endof
      3 of
        ." WiFi is already on in Sta+AP mode; type wifi-off to stop it" cr exit
      endof
   endcase

   wifi-#retries wifi-timeout wifi-storage StaSSID StaPassword wifi-open-station
   abort" WiFi station connection failed"
;
