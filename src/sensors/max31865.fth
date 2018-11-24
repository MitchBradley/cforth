\ Maxim MAX31865 PT100 Temperature Sensor interface driver

9 buffer: inbuf
9 buffer: outbuf
0 value max31865-config
: max31865-reg!  ( b.val b.reg# -- )
   $80 or  outbuf c!  outbuf 1+ c!
   spi{ outbuf inbuf 2 spi-transfer }spi
;
: max31865-reg@  ( b.reg# -- b.val )
   outbuf c!
   spi{ outbuf inbuf 2 spi-transfer }spi
   inbuf 1+ c@
;
: max31865-read  ( reg# #bytes -- )
   swap outbuf c!   ( #bytes )
   outbuf 1+ over $ff fill  ( reg# #bytes )
   1+               ( #bytes' )  \ 1+ accounts for the address byte cycle
   spi{ outbuf inbuf rot spi-transfer }spi
;
#400 value max31865-ref-r

\ Constants relevant to PT thermistors:
\ A is 3.9083 e-3  (1/A = 255.866)
\ B is -5.775 e-7  (-1/B = 1731600)
\ R0 is the thermistor resistance at 0C

\ Applying a lot of algebra to the equations in
\ https://www.analog.com/media/en/technical-documentation/application-notes/AN709_0.pdf
\ yields a fast way to calculate t from R using integer arithmetic:
\ t = T0 - sqrt(Tsq + Scl * R)
\ where

\ T0 is -A/2B = (-1/B) / (1/A)
\ Tsq is T0*T0 - 1/B
\ Scl is 1/(R0*B) = (-1/B) / R0

\ Only Scl depends on the thermistor type (PT100 or PT1000)

\ The integer calculation is accurate to within a couple of degrees C
\ up to at least 500 degrees, which is consistent with the fact that the
\ resistance is measured in ohms, and one ohm resistance change corresponds
\ to about 2.5 degrees C of temperature change.

#3384 constant mx-t0  \ actually 3383.84
#13181975 constant mx-tsq
#-1731600 constant mx-1/b
#-17316 value mx-scl

: max31865-set-wires-hz-r-r0  ( #wires 50hz? ref-r therm-r0 -- )
   mx-1/b swap / to mx-scl
   to max31865-ref-r
   1 and  swap 3 =   if  $10 or  then  ( bits )
   $a2 or  to max31865-config   \ 80: vbias-on  20: 1-shot  2: clear-fault
;

: max31865-adc@  ( -- adc-val )
   max31865-config 0 max31865-reg!
   #100 ms   \ 55ms should suffice
   1 2 max31865-read   \ Read 2 bytes starting at register 1
   inbuf 1+ be-w@      \ Skip the first byte that came in during the address
   u2/       ( adc-val )
;
: max31865-r  ( -- ohms )
   max31865-adc@ max31865-ref-r * #15 rshift  ( r )
;

0 [if]
\ Only for PT100; could be adapted to PT1000 but has not been done
\ linear approximation coefficients oak for the range 0..250C
#250 value max31865-num            \ degrees C
#194 #100 - value max31865-denom   \ delta R between 0C and max31865-num C
: pt>temperature-linear  ( -- degrees-C )
   #100 -       ( r' )  \ Offset to 0 degrees C
   max31865-num max31865-denom */
;
[then]

: nr-sqrt  ( n guess -- sqrt )  \ Newton-Rhapson iteration for integer SQRT
   begin            ( n guess )
      2dup  dup *   ( n guess  n trial )
      -             ( n guess  error )
      over / 2/     ( n guess  correction )
   dup while        ( n guess  correction )
      +
   repeat           ( n guess  correction )
   drop nip         ( sqrt )
;

\ The SQRT iteration typically converges within 2 or 3 iterations
\ with this initial guess, up to about 600 ohms / 1766 degrees C
: pt>temperature  ( r -- degrees-C )
   mx-scl * mx-tsq +  mx-t0 nr-sqrt
   mx-t0 swap -
;
: max31865-temp-quadratic  ( -- degrees-C )  max31865-r pt>temperature  ;
: c>f  ( c -- f )  9 5 */ #32 +  ;

1 [if] \ Example
: init-max31865  ( -- )
   \ When using HW CS, the ESP8266 module won't boot with the sensor attached
   \ 1 true #5000000 -1 spi-open  \ Mode 1, msb, 5MHz, HW CS

   1 true #5000000 0 spi-open  \ Mode 1, msb, 5MHz, SW CS on D0

   \ MAX31865 auto-senses the clock polarity so it tends to
   \ work in any SPI mode

   \ 3-wire-sensor 60Hz 430R PT100
   3 false #430 #100 max31865-set-wires-hz-r-r0 
;
[then]
