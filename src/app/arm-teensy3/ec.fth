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



: ec-charge ( -- )
   #12 analogReadRes
   ec-lo-gpio gpio-is-output
   0 ec-lo-gpio gpio-pin!
   begin
     \ charge
     ec-hi-gpio gpio-is-output
     1 ec-hi-gpio gpio-pin!
     #5 ms
     \ check if Vin is > 1.6V
     ec-hi-gpio gpio-is-input
     ec-analog-pin analogRead
     2048 >
   until
;

: ec-volt-diff ( -- dv{0..4095} )
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
;


\ TODO
0 value ec-const-resistor ( -- r{0..4095} )

: ec-measure ( -- ec*1000 )
   ec-volt-diff         ( dv )
   4096 over +          ( dv vcc+dv )
   4096 rot -           ( vcc+dv vcc-dv )
   dup 0= if            ( vcc+dv vcc-dv )
     999999
   else
     ec-const-resistor    ( vcc+dv vcc-dv r )
     * 1000 -rot */       ( ec*1000 )
   then
;
