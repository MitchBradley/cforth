\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth

: +apb1 $40000000 +  ;
: +apb2 $40010000 +  ;
: +ahb  $40020000 +  ;
: +gpioa +ahb  ;
: +gpiob +ahb $400 + ;
: +gpioc +ahb $800 + ;
: +gpiod +ahb $c00 + ;
: +rcc   +ahb $3800 +  ;
: +i2c1  +apb1 $5400 +  ;

\ RCC offsets
$1c constant ahbenr
$20 constant apb2enr
$24 constant apb1enr

\ GPIO register offsets
$00 constant moder
$04 constant otyper
$0c constant pupdr
$10 constant idr
$14 constant odr
$18 constant bsrr
$20 constant afr0
$24 constant afr1
$28 constant brr

: clk-fast  ( -- )  ;
: clk-slow  ( -- )  ;

: bitset  ( mask adr -- )  tuck l@ or swap l!  ;
: bitclr  ( mask adr -- )  tuck l@ swap invert and swap l!  ;
: gpiob-clk-on  ( -- )  2  ahbenr +rcc bitset  ;
: i2c-clk-on    ( -- )  $200000  ahbenr +rcc bitset  ;  \ I2C1
: usart2-clk-on ( -- )  $020000  ahbenr +rcc bitset  ;
: usart3-clk-on ( -- )  $040000  ahbenr +rcc bitset  ;

: gpioa-set-mode  ( mode pin# -- )  2*  lshift  moder +gpioa  bitset  ;
: gpioa-is-input  ( pin# -- )  0 swap gpioa-set-mode  ;
: gpioa-is-output ( pin# -- )  1 swap gpioa-set-mode  ;
: gpioa-is-af     ( pin# -- )  2 swap gpioa-set-mode  ;
: gpioa-is-analog ( pin# -- )  3 swap gpioa-set-mode  ;

: gpioa-open-drain  ( pin# -- )  1 swap lshift  otyper +gpioa  bitset  ;
: gpioa-push-pull   ( pin# -- )  1 swap lshift  otyper +gpioa  bitclr  ;

: gpiob-set-mode  ( mode pin# -- )  2*  lshift  moder +gpiob  bitset  ;
: gpiob-is-input  ( pin# -- )  0 swap gpiob-set-mode  ;
: gpiob-is-output ( pin# -- )  1 swap gpiob-set-mode  ;
: gpiob-is-af     ( pin# -- )  2 swap gpiob-set-mode  ;
: gpiob-is-analog ( pin# -- )  3 swap gpiob-set-mode  ;

: gpiob-open-drain  ( pin# -- )  1 swap lshift  otyper +gpiob  bitset  ;
: gpiob-push-pull   ( pin# -- )  1 swap lshift  otyper +gpiob  bitclr  ;

: gpiob-set  ( pin# -- )  1 swap lshift  odr +gpiob  bitset  ;
: gpiob-clr  ( pin# -- )  1 swap lshift  odr +gpiob  bitclr  ;

: gpioa-set  ( pin# -- )  1 swap lshift  odr +gpioa  bitset  ;
: gpioa-clr  ( pin# -- )  1 swap lshift  odr +gpioa  bitclr  ;

: pin-sda      gpiob-clk-on 9 gpiob-open-drain  9 gpiob-clr  9 gpiob-is-output  ;
: release-sda  9 gpiob-set  ;
: reset-bcm    #12 gpioa-clr  #12 gpioa-is-output  ;
: release-bcm  #12 gpioa-set  ;
: ms  0 ?do  #1000 0 do loop  loop  ;
: idle-bcm     reset-bcm  pin-sda  release-bcm  d# 50 ms  release-sda  ;

: release-scl  gpiob-clk-on 8 gpiob-open-drain  8 gpiob-set  8 gpiob-is-output  ;

\ Mimics the tether version
: i2c-op  ( dbuf dlen abuf alen slave op -- result )
   swap 2swap swap   ( dbuf dlen  op slave  alen abuf )
   2>r  2swap swap   ( op slave  dlen dbuf  r: alen abuf )
   2r>  2swap        ( op slave  alen abuf  dlen dbuf  )
   i2c-start  i2c-wait
;
: ?result  ( result -- )  0< abort" I2C Error"  ;
: i2c-read  ( adr len slave -- )  0 0 rot 0 i2c-op  ?result  ;
: i2c-write  ( adr len slave -- )  0 0 rot 1 i2c-op  ?result  ;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  ." CForth" cr hex quit  ;

\ " ../objs/tester" $chdir drop

" app.dic" save
