#23 constant ec-hi-gpio
#21 constant ec-lo-gpio
pinA8 constant ec-analog-pin  \ GPIO 22
: ec-setup  ( -- )
   ec-hi-gpio gpio-is-output
   ec-lo-gpio gpio-is-output
   #12 analogReadRes
;
: ec-read0  ( -- n )
   1 ec-lo-gpio gpio-pin!
   0 ec-hi-gpio gpio-pin!
   ec-analog-pin analogRead
;
: ec-read1  ( -- n )
   0 ec-lo-gpio gpio-pin!
   1 ec-hi-gpio gpio-pin!
   ec-analog-pin analogRead
;
0 [if]
fresh      2.5M -150K .254V
4 tsp/3Q   400K -400K .037V
                      
[then]


: .volts ( v{0..4095} -- )
  #330 #4095 */ n.nn$ type
  'V' emit
;


\ TODO: figure out these values
: ec-scalar ( -- uS/cm ) #500 ;
: ec-upper #30000 ;


#2730 value ec-bounds-max ( max:2.2V )
#1365 value ec-bounds-min ( min:1.1V )
: ec-charge-ms ( -- ) #200 ms ;


: ec-charge ( -- )
   #12 analogReadRes
   ec-lo-gpio gpio-is-output

   0 ec-lo-gpio gpio-pin! \ charge up
   begin
     ec-hi-gpio gpio-is-input
     ec-analog-pin analogRead
     dup .volts space
     ec-bounds-min < while
     ec-hi-gpio gpio-is-output
     1 ec-hi-gpio gpio-pin!  ec-charge-ms
   repeat
   drop

   1 ec-lo-gpio gpio-pin! \ charge down
   begin
     ec-hi-gpio gpio-is-input
     ec-analog-pin analogRead
     dup .volts space
     ec-bounds-max > while
     ec-hi-gpio gpio-is-output
     0 ec-hi-gpio gpio-pin!  ec-charge-ms
   repeat
;

: ec-volt-diff ( -- dv{-4095..+4095} )
   ec-setup
   0 #20 0 do
     1 ec-hi-gpio gpio-pin!
     0 ec-lo-gpio gpio-pin! #5 ms
     ec-analog-pin analogRead +
     0 ec-hi-gpio gpio-pin!
     1 ec-lo-gpio gpio-pin! #5 ms
     ec-analog-pin analogRead -
   loop
   #20 /
   0 ec-lo-gpio gpio-pin!
;

: ec-measure ( -- ec{uS/cm} )
   ec-volt-diff          ( dv )
   0 max                 ( dv )
   #4096 over +          ( dv vcc+dv )
   #4096 rot -           ( vcc+dv vcc-dv )
   dup 0= if             ( vcc+dv vcc-dv )
     \ divide by zero?
     2drop ec-upper exit
   then
   ec-scalar             ( vcc+dv vcc-dv c )
   -rot */               ( ec )
;
