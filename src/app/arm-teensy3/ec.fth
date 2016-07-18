#23 constant ec-hi-gpio
#21 constant ec-lo-gpio
pinA8 constant ec-analog-pin  \ GPIO 22
: ec-setup  ( -- )
   ec-hi-gpio gpio-is-output
   ec-lo-gpio gpio-is-output
   #12 analogReadRes
;
: ec-read0  ( -- n )
   0 ec-lo-gpio gpio-pin!
   1 ec-hi-gpio gpio-pin!
   ec-analog-pin analogRead
;
: ec-read1  ( -- n )
   1 ec-lo-gpio gpio-pin!
   0 ec-hi-gpio gpio-pin!
   ec-analog-pin analogRead
;
0 [if]
fresh      2.5M -150K .254V
4 tsp/3Q   400K -400K .037V
                      
[then]



/ TODO
0 value ec-const-resistor ( -- r{0..4096} )

: ec-measure ( -- ec{0..4096} )
  ec-const-resistor    ( rc )
  ec-read0 ec-read1 -  ( rc dv )
  4096 over -          ( rc dv vcc-dv )
  swap 4096 +          ( rc vcc-dv vcc+dv )
  */                   ( ec )
;
