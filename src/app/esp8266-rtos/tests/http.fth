:noname  " YourWiFiSSID" ;  to wifi-sta-ssid
:noname  " YourWifiPassword"   ;  to wifi-sta-password

wifi-sta-on abort" Cannot connect to WiFi"
http-listen
serve-http
