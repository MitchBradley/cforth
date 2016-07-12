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
