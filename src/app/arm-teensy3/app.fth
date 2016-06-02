\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  ." CForth" cr decimal quit  ;

create gpio-bits
  #16 c,  #17 c,  #00 c,  #12 c,  #13 c,  #07 c,  #04 c,  #02 c,
  #03 c,  #03 c,  #04 c,  #06 c,  #07 c,  #05 c,  #01 c,  #00 c,
  #00 c,  #01 c,  #03 c,  #02 c,  #05 c,  #06 c,  #01 c,  #02 c,
  #05 c,  #19 c,  #01 c,  #09 c,  #08 c,  #10 c,  #11 c,  #00 c,
  #18 c,  #04 c,

: gpio-ports  " BBDAADDDDCCCCCDCBBBBDDCCABECCCCEBA"  ;

: >port  ( pin# -- adr )
   gpio-ports drop + c@ 'A' - #6 lshift $400ff000 +
;
: >mask&port  ( pin# -- mask port )  1 over gpio-bits + c@ lshift  swap >port  ;

: gpio-pin!  ( value pin# -- )
   >mask&port  rot  if  4  else  8  then  +  l!
;
: gpio-pin@  ( value pin# -- )  >mask&port $10 +  l@ and 0<>  ;
: gpio-toggle  ( pin# -- )  >mask&port $0c +  l!  ;

create adc-pins  
  #14 c,  #15 c,  #16 c,  #17 c,  #18 c,  #19 c,  #20 c,  #21 c,
  #22 c,  #23 c,  #34 c,  #35 c,  #36 c,  #37 c,

: gpio-is-output  ( pin# -- )  1 swap gpio-mode  ;
: gpio-is-input  ( pin# -- )  0 swap gpio-mode  ;
: gpio-is-input-pullup  ( pin# -- )  2 swap gpio-mode  ;
: gpio-is-input-pulldown  ( pin# -- )  3 swap gpio-mode  ;
: gpio-is-output-open-drain ( pin# -- )  4 swap gpio-mode  ;

\ " ../objs/tester" $chdir drop

#14 constant pinA0
#15 constant pinA1
#16 constant pinA2
#17 constant pinA3
#18 constant pinA4
#19 constant pinA5
#20 constant pinA6
#21 constant pinA7
#22 constant pinA8
#23 constant pinA9
#34 constant pinA10
#35 constant pinA11
#36 constant pinA12
#37 constant pinA13
#40 constant pinA14
#26 constant pinA15
#27 constant pinA16
#28 constant pinA17
#29 constant pinA18
#30 constant pinA19
#31 constant pinA20

\ Test for analogWrite to DAC0
decimal
3.1415926535E0 fconstant pi
pi 2E f* fconstant 2pi
2E-2 fvalue phaseinc

: sinewave  ( -- )
   ." Sine wave on DAC0 pin; type a key to stop" cr
   #12 analogWriteRes
   2pi
   begin        ( phase )
      fdup fsin 2000E0 f*  2050E0 f+
      int pinA14 analogWrite 
      phaseinc f-  fdup f0<  if  2pi f+  then
   key? until
   fdrop
;



" app.dic" save
