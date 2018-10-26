\ Driver for dumb RGB LED connected to 3 GPIOs
\ init-gpio-rgb-led sets the GPIO numbers and the drive polarity.

\ init-gpio-rgb-led overrides these values
6 value red-gpio
5 value green-gpio
0 value blue-gpio
0 value led-xor-mask  \ 0 for active high, 1 for active low

: led!  ( flag gpio# -- )
   swap                          ( gpio# flag )
   0<> 1 and  led-xor-mask xor   ( gpio# 0|1 )
   swap gpio-pin!
;

: init-gpio-rgb-led  ( red# green# blue# active-high? -- )
   if  0  else  1  then  to led-xor-mask      ( red# green# blue# )
   to blue-gpio  to green-gpio  to red-gpio   ( )
   false gpio-output blue-gpio   gpio-mode  false blue-gpio  led!
   false gpio-output green-gpio  gpio-mode  false green-gpio led!
   false gpio-output red-gpio    gpio-mode  false red-gpio   led!
;

: rgb-led!  ( rgb -- )
   dup 1 and blue-gpio  led!  2/
   dup 1 and green-gpio led!  2/
   dup 1 and red-gpio   led!  drop
;
: led:  ( bits "name" -- )  create , does> @ rgb-led!  ;
0 led: black-led
1 led: blue-led
2 led: green-led
3 led: cyan-led
4 led: red-led
5 led: magenta-led
6 led: yellow-led
7 led: white-led
