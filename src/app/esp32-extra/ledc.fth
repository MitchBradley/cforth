: ledc-conf!   $3ff59190 l!  ;
: ledc-conf@   $3ff59190 l@  ;

\ 2 bits timer select
\ 1 bit output enable
\ 1 bit idle level
\ 26 bits reserved
\ 1 bit (30) clock enable
: ledc-conf0!  $3ff59000 l!  ;
: ledc-conf0@  $3ff59000 l@  ;

\ 20 bits
: ledc-hpoint!  $3ff59004 l!  ;
: ledc-hpoint@  $3ff59004 l@  ;

\ 25 bits
: ledc-duty!   $3ff59008 l!  ;
: ledc-duty@   $3ff59008 l@  ;
: ledc-duty-r@ $3ff59010 l@  ;

\ 10 bits scale increment
\ 10 bits duty cycle increment
\ 10 bits number of increments
\ 1 bit (30) increment enable
\ 1 bit (31) commit changes to this register

0 value ledc-commit-val
: ledc-conf1!  $3ff5900c l!  ;
: ledc-conf1@  $3ff5900c l@  ;

\ 5 bits - resolution 2^n
\ 19 bits - divisor, low 8 bits are fractional/256
\ 1 bit (23) pause
\ 1 bit (24) reset counter
\ 1 bit (25) 0 for apb_clk, 1 for ref_tick
: ledc-timer-conf!  $3ff59140 l!  ;
: ledc-timer-conf@  $3ff59140 l@  ;

\ 20 bits - counter value - RO
: ledc-timer-val@   $3ff59144 l@  ;

\ uint32_t frequency = (80MHz or 1MHz)/((div_num / 256.0)*(1 << bit_num));

: clk-en!  $3ff000c0 l!  ;
: clk-en@  $3ff000c0 l@  ;
: rst-en!  $3ff000c4 l!  ;
: rst-en@  $3ff000c4 l@  ;

: ledc-setup-timer0  ( divisor #bits apb-clk -- )
   1 and   dup led-conf!

   clk-en@  1 #11 lshift or  clk-en!           \ DPORT_LEDC bit
   rst-en@  1 #11 lshift invert and  rst-en!

   #25 lshift or  swap 5 lshift or  ledc-timer-conf!
;

#80000000 constant apb-hz
: set-timer0-freq  ( #bits freq -- )
   apb-hz 8 lshift     ( #bits freq apb<<8 )
   2 pick rshift       ( #bits freq apb<<[8-#bits] )
   swap /              ( #bits divisor )
   1 ledc-setup-timer0 ( )
;

: field-set  ( mask value bit# -- )  lshift or  ;
: bit-set  ( mask bit# -- mask' )  1 swap field-set  ;

0 constant timer#
: ledc-setup0  ( idle-level -- )
   timer#  swap 3 field-set  ( mask )
   2 bit-set  \ output enable
   ledc-conf0!

   0 ledc-hpoint!

   0 ledc-duty!

   \ scale  cycle            num              inc
   0        1 #10 field-set  1 #20 field-set  #30 bit-set  dup ledc-conf1!  ( val )
   #31 bit-set  to ledc-commit-val
;
: pwm-on  ( -- )  1 #30 lshift  ledc-conf1!  ;  \ clk-enable

: set-duty  ( n -- )  ledc-duty!  ledc-commit-val ledc-conf1!  ;

#71 constant ledc-sig#
: ledc-pin  ( pin# -- )
   dup gpio-is-output  ( pin# )
   0 ledc-sig# +  swap  ( function pin# )
   0 0 2swap  gpio-matrix-out
;
