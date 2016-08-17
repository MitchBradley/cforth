#23 constant ec-hi-gpio
#21 constant ec-lo-gpio
pinA8 constant ec-analog-pin  \ GPIO 22
: ec-setup  ( -- )
   ec-hi-gpio gpio-is-input
   ec-lo-gpio gpio-is-output
   #12 analogReadRes
;
0 [if]
fresh      2.5M -150K .254V
4 tsp/3Q   400K -400K .037V
                      
[then]

: n.nnn$
   push-decimal <# u# u# u# #46 hold u#s u#>
   pop-base save$
;

: .volts ( v{0..4095} -- )
  dup 0< if negate '-' emit then
  #3300 #4095 */ n.nnn$ type
  ." V" cr
;


\ TODO: calibrate these values
#500 value ec-scalar ( uS/cm )
: ec-very-high #30000 ;



: ec-get-charge ( -- v{0..4095} )
   ec-hi-gpio gpio-is-input
   0 ec-lo-gpio gpio-pin!
   ec-analog-pin analogRead
   dup 0> if exit then
   1 ec-lo-gpio gpio-pin!
   ec-analog-pin analogRead
   \ ." neg charge" cr
   4096 -
;

#50 value ec-bounds-lo \ 0.04V
#25 value ec-bounds-hi \ 0.02V

: ec-charge ( -- )
   ec-hi-gpio gpio-is-output
   1 ec-hi-gpio gpio-pin!
   0 ec-lo-gpio gpio-pin!
   #50 ms
   ec-hi-gpio gpio-is-input
   #50 ms
;
: ec-discharge ( -- )
   ec-hi-gpio gpio-is-output
   0 ec-hi-gpio gpio-pin!
   1 ec-lo-gpio gpio-pin!
   #50 ms
   ec-hi-gpio gpio-is-input
   #50 ms
;

: ec-auto-charge ( -- )
   begin    key? if exit then
     ec-get-charge
     \ dup ." up " .volts
     ec-bounds-lo <
   while
     ec-charge
   repeat
;
: ec-auto-discharge ( -- )
   begin    key? if exit then
     ec-get-charge
     \ dup ." down " .volts
     ec-bounds-hi >
   while
     ec-discharge
   repeat
;

: ec-normalize ( -- )
   ec-setup
   ec-auto-charge
   #200 ms
   ec-auto-discharge
   #200 ms
   ec-auto-discharge
;


: ec-look ( -- )
   ec-setup
   ec-hi-gpio gpio-is-output
   1 ec-hi-gpio gpio-pin!
   0 ec-lo-gpio gpio-pin!
   ec-analog-pin analogRead .volts
   0 ec-hi-gpio gpio-pin!
   1 ec-lo-gpio gpio-pin!
   ec-analog-pin analogRead .volts
   ec-hi-gpio gpio-is-input
;

: ec-volt-diff ( -- dv{-4095..+4095} )
   ec-setup
   ec-auto-discharge
   ec-hi-gpio gpio-is-output
   0 #20 0 do
     1 ec-hi-gpio gpio-pin!
     0 ec-lo-gpio gpio-pin!
     ec-analog-pin analogRead +
     0 ec-hi-gpio gpio-pin!
     1 ec-lo-gpio gpio-pin!
     ec-analog-pin analogRead -
   loop
   #20 /
   ec-hi-gpio gpio-is-input
;

: ec-measure ( -- ec{uS/cm} )
   ec-volt-diff          ( dv )
   #4096 over +          ( dv vcc+dv )
   #4096 rot -           ( vcc+dv vcc-dv )
   dup 0= if             ( vcc+dv vcc-dv )
     \ divide by zero?
     2drop ec-very-high exit
   then
   ec-scalar             ( vcc+dv vcc-dv c )
   -rot */               ( ec )
;
