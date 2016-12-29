\ Teensy3 GPIOs

\ Map Teensy module pin numbers to SoC GPIO ports and pins
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

: gpio-is-output  ( pin# -- )  1 swap gpio-mode  ;
: gpio-is-input  ( pin# -- )  0 swap gpio-mode  ;
: gpio-is-input-pullup  ( pin# -- )  2 swap gpio-mode  ;
: gpio-is-input-pulldown  ( pin# -- )  3 swap gpio-mode  ;
: gpio-is-output-open-drain ( pin# -- )  4 swap gpio-mode  ;
