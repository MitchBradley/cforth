\ GPIO / PWM driver for Raspberry Pi (BCM2835 chip)

\needs mmap #14 ccall: mmap            { a.phys i.len i.fd -- a.virt }

0 value mem-fd
: ?open-mem  ( -- )  mem-fd 0=  if  " /dev/mem" h-open-file to mem-fd  then  ;

0 value gpio-base
: ?map-gpio  ( -- )
   ?open-mem
   gpio-base 0=  if
      $20200000 $1000 mem-fd mmap to gpio-base
   then
;
: gpio>bit,base  ( gpio# -- bitmask base )
   1 over $1f and lshift   ( n bitmask )
   swap 5 rshift           ( bitmask offset )
   gpio-base swap la+      ( bitmask base )
;

: gpio-set  ( gpio# -- )  gpio>bit,base $1c +  l!  ;
: gpio-clr  ( gpio# -- )  gpio>bit,base $28 +  l!  ;
: gpio-pin@ ( gpio# -- )  gpio>bit,base $34 +  l@  and 0<>  ;

: fsel-setup  ( gpio# -- adr shift )
   #10 /mod               ( residue word# )
   gpio-base swap la+     ( residue adr )
   swap 3 *               ( adr shift )
;
: gpio-function@  ( gpio# -- function# )  \ 0 input, 1 output, 4 alternate
   fsel-setup                  ( adr shift )
   swap l@ swap rshift 7 and   ( n )
;
: gpio-function!  ( function# gpio# -- )
   swap >r                       ( bit# r: function# )
   fsel-setup                    ( adr shift r: function# )
   over l@                       ( adr shift old-value r: function# )
   7  2 pick lshift  invert and  ( adr shift masked-value r: function# )
   r> rot lshift  or             ( adr new-value )   
   swap l!                       ( )
;

: gpio-is-input   ( gpio# -- )  0 swap gpio-function!  ;
: gpio-is-output  ( gpio -- )  1 swap gpio-function!  ;
: gpio-is-alt0    ( gpio# -- )  4 swap gpio-function!  ;

\ Example:  (as root for mmap to work)
\  ?map-gpio
\  7 gpio-is-output
\  7 gpio-set
\  7 gpio-clr

0 value clk-base
: ?map-clk  ( -- )
   ?open-mem
   clk-base 0=  if
      $20101000 $1000 mem-fd mmap to clk-base
   then
;
 
0 value pwm-base
: ?map-pwm  ( -- )
   ?open-mem
   pwm-base 0=  if
      $2020c000 $1000 mem-fd mmap to pwm-base
   then
;

#18 constant pwm0-gpio#
: pwm-ctl@  ( -- l )  pwm-base l@  ;
: pwm-ctl!  ( l -- )  pwm-base l!  ;
: pwm-sta@  ( -- l )  pwm-base 4 + l@  ;
: pwm-sta!  ( l -- )  pwm-base 4 + l!  ;
: pwm-dmac@  ( -- l )  pwm-base 8 + l@  ;
: pwm-dmac!  ( l -- )  pwm-base 8 + l!  ;
: pwm-rng1@  ( -- l )  pwm-base $10 + l@  ;
: pwm-rng1!  ( l -- )  pwm-base $10 + l!  ;
: pwm-dat1@  ( -- l )  pwm-base $14 + l@  ;
: pwm-dat1!  ( l -- )  pwm-base $14 + l!  ;
: pwm-fif1@  ( -- l )  pwm-base $18 + l@  ;
: pwm-fif1!  ( l -- )  pwm-base $18 + l!  ;
: pwm-rng2@  ( -- l )  pwm-base $20 + l@  ;
: pwm-rng2!  ( l -- )  pwm-base $20 + l!  ;
: pwm-dat2@  ( -- l )  pwm-base $24 + l@  ;
: pwm-dat2!  ( l -- )  pwm-base $24 + l!  ;

: pwm-clk-source!  ( l -- )  $5a00.0000 or  clk-base #40 la+ l!  ;
: pwm-clk-div!  ( divisor -- )  #12 lshift  $5a00.0000 or  clk-base #41 la+ l!  ;

\ Source is PLLD at 500 MHz
: pwm-divisor  ( divisor -- )  $6 pwm-clk-source!  1 ms  pwm-clk-div!  1 ms  $16 pwm-clk-source!  1 ms  ;

: pwm-clk-setup  ( -- )  ?map-clk  #50 pwm-divisor  ;

: pwm-spread-mode  ( -- )  1 pwm-ctl!  ;
: pwm-ms-mode  ( -- )  $81 pwm-ctl!  ;
: pwm-ratio  ( on-clocks total-clocks -- )  pwm-rng1!  pwm-dat1!  ;

: pwm-setup  ( -- )
   ?map-gpio   2 pwm0-gpio# gpio-function!  \ ALT5
   ?map-pwm 
   0 pwm-ctl!     \ Disable
   pwm-clk-setup
   pwm-ms-mode
   #100 #200 pwm-ratio
;
