\ Changes the ESP8266 init_data to choose the input source for
\ the ADC - either the external A0 pin or the 3V3 supply voltage.
\ You must then reboot for the change to take effect.

\ Use adc@ from extend.c to read the ADC
\ Use vdd33@ from extend.c to read the supply voltage
\ If the init_data is set to read the supply voltage,
\ adc@ will return $ffff, and vice versa.

$1000 constant /flash-sector
: init-data-offset  ( -- n )  flash-size $4000 -  ;
: set-adc-mux  ( read-vdd? -- )
   0<>    ( read-vdd? )
   /flash-sector pad init-data-offset flash-read abort" FLASH read failed"
   dup pad #107 + c@  0<>  =  if   ( read-vdd? )
      drop                      ( )
      ." Already in the right mode" cr
   else                         ( read-vdd? )
      pad  #107 + c!            ( )
      init-data-offset /flash-sector /  flash-erase abort" FLASH erase failed"
      /flash-sector pad init-data-offset flash-write abort" FLASH write failed"
      ." Reboot for the change to take effect" cr

   then                         ( )
;
: adc-mode  ( -- )  false set-adc-mux  ;
: vdd-mode  ( -- )  true set-adc-mux  ;
