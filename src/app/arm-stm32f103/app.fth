\ Load file for application-specific Forth extensions
fl ../../cpu/arm/cortex-m3/bitband.fth
fl ../../lib/misc.fth
fl ../../lib/dl.fth
$3000 $5000 npatch load-base

: bitset  ( mask adr -- )  tuck l@ or swap l!  ;
: bitclr  ( mask adr -- )  tuck l@ swap invert and swap l!  ;

0 constant gpioa
1 constant gpiob
2 constant gpioc

\ If the part has more GPIO ports ...
\ 3 constant gpiod
\ 4 constant gpioe
\ 5 constant gpiof
\ 6 constant gpiog

\ GPIO modes.  This encoding matches the STM Standard Peripheral Library
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
: led-on  ( -- )  led-gpio gpio-clr  ;
: led-off ( -- )  led-gpio gpio-set  ;

0 value adc

0 value adc-channel

: init-adc  ( channel# -- )
   dup to adc-channel    ( channel# )
   8 /mod                ( pin# port# )
   if  gpiob  else  gpioa  then  ( pin port )
   ain -rot  gpio-open drop     \ Configure the GPIO for analog
   1 adc-open to adc            \ Fire up the ADC
;

\ Lower adc-time values, down to 0, result in faster conversion at lower
\ precision. Values less than 6 don't speed it up much in polled mode
\ because the software time dominates.  adc-time values of 6 and lower
\ take about 36 us, while 7 takes 46 us.

7 value adc-time  \ 7 is slow conversion for high precision

: adc@  ( -- value )
   adc-time adc-channel adc adc-start
   begin  adc adc-done?  until
   adc adc-get
;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  ." CForth" cr hex quit  ;

\ " ../objs/tester" $chdir drop

" app.dic" save
