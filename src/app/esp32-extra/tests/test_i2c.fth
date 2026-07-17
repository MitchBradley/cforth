needs aht2x-setup ../../sensors/aht2x.fth \ Load it in ROM with app.fth 

 #25 to aht2x-Sda #26 to aht2x-Scl  \ ESP32
\ #5 to aht2x-Sda  #6 to aht2x-Scl  \ ESP32C3

: aht2x-setup       ( -- device-handle )
      [ifdef] i2c-open-device  
         aht2x-Scl aht2x-Sda aht2x-I2CAdr i2c-open-device \ Under the new IDF5.5.1 version
      [else]  
         aht2x-Scl aht2x-Sda i2c-open \ Under the old IDF3.21 version
      [then] 
;

: test ( -- )
   aht2x-Rcv$ 0= if  
      aht2x-setup 0= 
      abort" aht2x-setup  failed."  
   then
   get-aht2x-data  
   abort" get-aht2x-data failed 
   ." Humidity: " f. ." %  Temperature: " f. ." C  #aht2x-errors: "  aht2x-errors ? 
;

cr test
quit
\ \s
