:noname  " YourWiFiSSID" ;  to wifi-sta-ssid
:noname  " YourWifiPassword"   ;  to wifi-sta-password

#4000 to wifi-timeout
5 value wifi-#retries
0 value wifi-storage  \ 0 for FLASH, 1 for RAM
: wifi-station-on  ( -- )
   \ Bail if already on
   wifi-mode@ 1 =  if  exit  then

   wifi-storage wifi-#retries wifi-timeout
   wifi-sta-ssid wifi-sta-password wifi-open-station
   abort" WiFi station connection failed"
;
