marker -adc_esp32.fth lastacf .name #20 to-column .( 07-06-2026 )
\ ADC for cforh under IDF version 5.5.1  Can be compiled in ROM.

\ About ADC_UNIT_1: 
\ ESP32: For pins:  GPIO32-GPIO39
\ ESP32C3: For pins:  ADC1: 5 channels (GPIO0 GPIO1 GPIO3 GPIO4), all functions
\          ADC2 oneshot mode is not supported on a ESP32-C3

 0 constant ADC_UNIT_1 

0 constant ADC_RTC_CLK_SRC_DEFAULT

0 [IF]  \ Optional under IDF v5.x
#9  constant ADC-BITWIDTH-9
#10 constant ADC-BITWIDTH-10
#11 constant ADC-BITWIDTH-11
#12 constant ADC-BITWIDTH-12
\ #13 constant ADC-BITWIDTH-13  \ Not for the esp32

 0 constant ADC-ATTEN-DB-0
#1 constant ADC-ATTEN-DB-2-5
#2 constant ADC-ATTEN-DB-6
[THEN]

#3 constant ADC-ATTEN-DB-12
\ 0 constant ADC_BITWIDTH_DEFAULT \ Uses the maximal value
#12 constant ADC-BITWIDTH-12

 0 value unit-hndl

: init-adc ( -- handle|0 )  
   ADC_RTC_CLK_SRC_DEFAULT ADC_UNIT_1 adc-new-unit 
   dup 0= abort" init-adc failed"
;

: read-adc-channel ( channel -- mv )
   >r unit-hndl 0= if
      init-adc to unit-hndl
   then   
   ADC-BITWIDTH-12 ADC-ATTEN-DB-12 r@ unit-hndl adc-config-channel abort" adc-config-channel failed"     
   -2 sp@ -1 sp@ r> unit-hndl adc-read-raw abort" adc-read-raw failed" 
   ADC-BITWIDTH-12 ADC-ATTEN-DB-12 ADC_UNIT_1 adc-create-calibration-scheme dup >r 
   adc-raw-to-mv abort" adc-raw-to-mv failed"
   r> adc-delete-calibration-scheme   
   unit-hndl adc-del-unit drop 0 to unit-hndl
;

\ Eg:
\ 5 read-adc-channel cr .( ADC: ) . .(  mV)  \ gpio32  esp32 
\ 1 read-adc-channel . \ ESP32C3
\ \s
