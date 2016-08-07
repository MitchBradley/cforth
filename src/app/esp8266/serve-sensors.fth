: hdr  " <h1> Sensor Status</h1>" t ;
: but1  " <p>GPIO0 <a href=""?pin=ON1""><button>ON</button></a>&nbsp;<a href=""?pin=OFF1""><button>OFF</button></a></p>" t ;
: but2  " <p>GPIO2 <a href=""?pin=ON2""><button>ON</button></a>&nbsp;<a href=""?pin=OFF2""><button>OFF</button></a></p>" t ;

: temperature  ( -- )
   " <p>Temperature: " t  ds18x20-temp$ t  " C</p>" t
;
0 value dist
: get-distance  ( -- )  vl-distance to dist  ;
0 value timer1
: setup-timer  ( -- )
   vl-distance to dist
   ['] get-distance new-timer to timer1
   #2000 1 1 timer1 arm-timer
;
: distance  ( -- )
\   " <p>Distance: " t  vl-distance  (.d) t  " mm</p>" t
   " <p>Distance: " t  dist (.d) t  " mm</p>" t
;
: sensor-homepage  ( -- )
   \ hdr but1 but2
   hdr
   distance
;
' sensor-homepage to homepage

: init-all  ( -- )
   ['] init-vl6180x catch  if  ." VL6180x init failed" cr  else  setup-timer  then
   ['] init-ds18x20 catch  if  ." DS18x20 init failed" cr  then
   ['] init-ads     catch  if  ." ADS1115 init failed" cr  then
   ['] init-bme     catch  if  ." BME280 init failed" cr  then
   ['] init-pca     catch  if  ." PCA9685 init failed" cr  then
   ['] init-hcsr04  catch  if  ." HC-SR04 init failed" cr  then
;
' init-all to server-init
