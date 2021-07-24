\ Load file for application-specific Forth extensions

: bitset  ( mask adr -- )  tuck l@ or swap l!  ;
: bitclr  ( mask adr -- )  tuck l@ swap invert and swap l!  ;

0 constant gpioa
1 constant gpiob
2 constant gpioc
3 constant gpiod
4 constant gpioe

\ GPIO modes.  This encoding matches the GD32VF103 Firmware Library
$00 constant ain

$10 constant out_pp
$14 constant out_od

$18 constant af_pp
$1c constant af_od

$04 constant in_floating
$28 constant in_pulldown
$48 constant in_pullup

0 value led-gpio
: init-led  ( -- )
   out_pp #13 gpioc gpio-open to led-gpio
;
: led-on  ( -- )  led-gpio gpio-set  ;
: led-off ( -- )  led-gpio gpio-clr  ;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  ." CForth (GD32VF103)" cr hex quit  ;

" app.dic" save
