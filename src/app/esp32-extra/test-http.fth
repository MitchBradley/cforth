:noname  " YourWiFiSSID" ;  to wifi-sta-ssid
:noname  " YourWiFiPassword"   ;  to wifi-sta-password

wifi-sta-on abort" Cannot connect to WiFi"
http-listen
serve-http
