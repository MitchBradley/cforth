\ Interface to optocoupled relay board (Sain-Smart or Kootek) via
\ Raspberry Pi GPIOs

\needs ?map-gpio  fload rpi-gpio.fth

5 constant #gpio-relays
create relay-gpios  #11 c, #10 c, 7 c,  8 c,  9 c,

: relay>gpio  ( relay# -- gpio# )  relay-gpios + c@  ;
: gpio-relay-on   ( relay# -- )  relay>gpio gpio-clr  ;
: gpio-relay-off  ( relay# -- )  relay>gpio gpio-set  ;
: ?open-gpio-relays  ( -- )
   ?map-gpio
   #gpio-relays 0  do  i gpio-relay-off  i relay>gpio gpio-is-output  loop
;

: use-gpio-relays  ( -- )
   ['] ?open-gpio-relays  to ?open-relays
   ['] gpio-relay-on      to relay-on
   ['] gpio-relay-off     to relay-off
;

create electrode-gpios  #27 c,  #17 c,  #4 c,  #22 c,
: electrode>gpio  ( electrode# -- gpio# )  electrode-gpios + c@  ;

: ?gpio-out  ( electrode# -- electrode# )  dup gpio-is-output  ;
: touch-on   ( electrode# -- )  electrode>gpio ?gpio-out gpio-set  ;
: touch-off  ( electrode# -- )  electrode>gpio ?gpio-out gpio-clr  ;
