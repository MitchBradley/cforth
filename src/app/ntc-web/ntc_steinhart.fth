marker -ntc_steinhart.fth  cr lastacf .name #19 to-column .( 28-07-2023 )
\ Adapted for ntc_web.fth. Can be compiled in ROM.

\ cr .( The Steinhart-Hart equation.) \ By J.v.d.Ven
decimal

\ Used circuit:
\           R0             /~ Rt
\  Gnd ___/\/\/\______/\/\//\/\____Vs
\                  |     /
\                  Vo
\ The equation:
\ 1/T = A + B*ln(Rnct) + C*(ln(Rnct))^3

\ ntc
f# 3283e0   fvalue Vs    \ In mV, measure it
f# 10008e0  fvalue R0    \ 10K
f# 298.15e0 fconstant T0 \ Temperature in Kelvin at 25C
f# 273.15e0 fconstant 0C \ Temperature in Kelvin at 0C

\ In a test case the coefficents were calculated in a thermistor calculator at:
\ https://www.thinksrs.com/downloads/programs/therm%20calc/ntccalibrator/ntccalculator.html
\ Needed input: "R nom" for R at various temperatures T
\   R    T  came from the "ntc-resistance-temperature-curve" of NTC B57560K0493A001
\ 39517 30  at: https://www.tdk-electronics.tdk.com/web/designtool/ntc/
\ 31996 35
\ 26065 40

\ Then the thermistor calculator at:
\ https://www.thinksrs.com/downloads/programs/therm%20calc/ntccalibrator/ntccalculator.html
\ calculated then coefficents A,B and C:
f# 0.7556958984e-3 fvalue A_sh
f# 2.334204104e-4  fvalue B_sh
f# 0.6102744539e-7 fvalue C_sh

: 1/f          ( F: f - 1/f ) f# 1e0 fswap f/ ;

: Vntc         ( mV - ) ( F - Vntc ) \ Vntc=Vs-Vo ( All in mV )
   Vs s>f f-  ;

: Rntc         ( F:  mV - Rt )       \ Rt=(R0*Vntc)/(Vs-Vntc)
   fdup R0 f*   Vs frot f- f/ ;

: ntc-sh       ( Rt - Celsius )
   fln fdup  fdup fdup f* f* C_sh f* \ C*(ln(Rnct))^3
   fswap B_sh f* f+
   A_sh f+                           \ 1/T
   1/f 0C f- ;                       \ Temperature in Celsius


0 [if] \ Test case:
cr s" ntc-sh  ( Rt - Celsius ) can be used." type cr

cr .( Parameters:  )  14 set-precision
cr .( A: ) A_sh f.
cr .( B: ) B_sh f.
cr .( C: ) C_sh f.

1 set-precision
cr .( Vs:  )   Vs f. (  mV )
cr .( Resistor R0:) R0 f.

cr  6 set-precision
cr .( Rt:) f# 29456e0 fdup f>s . ntc-sh
   .( ntc-sh:) f. .(  C ) cr cr  quit \ Should calculate 36.9997
[then]

s" adc-mv" $find
[if] \ For Cforth on a ESP32:

  0 constant vref  \ The reference voltage stored in eFuse during factory calibration
#32 constant /adc_chars
0 value &adc_chars

: read-adc-mv  ( adc-channel - mV )   &adc_chars swap  adc@  adc-mv ;

70 constant /state
0 value state$

: init-ntc ( adc-channel bit_precision attenuation -- )
  /adc_chars allocate drop to &adc_chars
  /state     allocate drop to state$
   >r dup adc-width!   \ Assumes: vref, bit_precision and attenuation
   r@ rot adc-atten!   \ are the same for the used adc-channels.
\ ( a.adc_chars i.vref i.bi_width i.atten i.adc_num -- i.res )
  &adc_chars  vref   rot        r>      1 get-adc-chars drop ;

[else]

cr s" adc-mv   ( adc_chars reading - mV ) is missing." type
cr .( See: https://github.com/MitchBradley/cforth/tree/WIP )
cr .( Or define your own accurate read-adc-mv and init-ntc here)
cr .( to monitor the NTC.) cr cr quit

[then] drop

\ For the coefficents I used the thermistor calculator again at:
\ https://www.thinksrs.com/downloads/programs/therm%20calc/ntccalibrator/ntccalculator.html
\ Needed input: "R nom" for R at various temperatures T
\   R    T    from the "ntc-resistance-temperature-curve" of NTC B57164K0103
\ 35563  0    at: https://www.tdk-electronics.tdk.com/web/designtool/ntc/
\ 10000  25
\ 4102.6 45

f# 1.292290081e-3  to A_sh
f# 2.164041451e-4  to B_sh
f# 0.8776278596e-7 to C_sh
f# -1.9e0 fvalue av-trim     \ if needed

0 [if]
cr .( Parameters for NTC B57164K0103:)

#14 set-precision
cr .( A ) A_sh f.
cr .( B ) B_sh f.
cr .( C ) C_sh f.

cr 3 set-precision
cr .( av-trim    :) av-trim f.
1 set-precision
cr .( Vs         :) Vs f.
cr .( Resistor R0:) R0 f.
cr
[then]

#10 constant #adc-samples

: adc-mv-av    ( adc-channel - mV )
   #adc-samples >r 0 r@ 0
       do  over read-adc-mv +
       loop
   r> / nip ;

\ EG: One reading on adc-channel 5 with multisampling:
\ cr 2 set-precision 5 dup 3 3 init-ntc 5 adc-mv-av Vntc Rntc ntc-sh f.

#60 value /sample-buffer-ntc  \ To reduce the ADC noise further
 0  value &sample-buffer-ntc

: .sample-buffer-ntc    { - }
   /sample-buffer-ntc 0
       do   cr  i dup . &sample-buffer-ntc >circular f@  fe.
            i 0=
               if ." --- To be used. ---"
               then
       loop ;

: .ntc ( - )       \ Scans only the used records
   cr ." N  >circ-i  (C)"
   &sample-buffer-ntc circular-range
       ?do   cr i dup . 3 spaces &sample-buffer-ntc >circular-index dup . 5 spaces
             &sample-buffer-ntc >record-cbuf
             1 floats + f@ f.
       loop ;

: clr-sample-buffer-ntc    ( - )
   /sample-buffer-ntc 0
       do   f# 0e0 i &sample-buffer-ntc >circular f!
       loop
   &sample-buffer-ntc >cbuf-count off ;

: av-ntc       ( f: - av-ntc )
   f# 0e0 &sample-buffer-ntc >cbuf-count @ /sample-buffer-ntc min dup 0
       do   i floats &sample-buffer-ntc >&data-buffer @ + f@ f+
       loop
   s>f f/ ;

\ \s
