hex
: a-stepping?  ( -- flag )  d4282c00 l@ h# ff0000 and  h# a0.0000 =  ;
: at-least-a1?  ( -- flag )  ffe00030 l@  h# 4131 >=  ;
: basic-setup  ( -- )
   \ Stuff from jasper.c that is not already done elsewhere
   0001ffff d42828dc l! \ PMUA_GLB_CLK_CTRL - Enable CLK66 to APB, PLL2/12/6/3/16/8/4/2/1, PLL1/12/6/3/16/8/4 
   \ Slow queue, L2 cache burst 8, bypass L2 clock gate, disable MMU xlat abort, Multi-ICE WFI, bypass clock gate
   d4282c08 l@
   a-stepping? at-least-a1? and  if
      00082000 or
   else
      00086040 or
   then
   00800000 invert and  d4282c08 l!
;
0 [if]
: set-pll2  ( -- )
   \ select PLL2 frequency, 520MHz
\   08600322 d4050414 l!  \ PMUM_PLL2_CTRL1 \ Bandgap+charge pump+VCO loading+regulator defaults, 486.3-528.55 PLL2 (bits 10:6)
\   00FFFE00 d4050034 l!  \ PMUM_PLL2_CTRL2 \ refclk divisor and feedback divisors at max, software controls activation
\   0021da00 d4050034 l!  \ PMUM_PLL2_CTRL1 \ refclk divisor=4, feedback divisor=0x76=118, software controls activation
\   0021db00 d4050034 l!  \ PMUM_PLL2_CTRL2 \ same plus enable
\   28600322 d4050414 l!  \ PMUM_PLL2_CTRL1 \ same as above plus release PLL loop filter
;
[then]

: mpmu! d4050000 + l! ; : mpmu@ d4050000 + l@ ;
: pmua! d4282800 + l! ; : pmua@ d4282800 + l@ ;
: .3bits  ( n shift -- n )  over swap  rshift 7 and .  ;
: .divisors  ( n -- )
   ." A" d# 15 .3bits
   ." D" d# 12 .3bits
   ." X"     9 .3bits
   ." B"     6 .3bits
   ." C"     3 .3bits
   ." P"     0 .3bits
   drop cr
;
: .clocks  ( -- )
   ." SP: "  8 pmua@ .divisors
   ." PJ: "  c pmua@ .divisors
;

: fccr@    ( -- n )  8 mpmu@  ;
: fccr!    ( n -- )  8 mpmu!  ;
: pj4-clksel  ( n -- )
   d# 29 lshift                               ( field )
   fccr@  h# e000.0000 invert and  or  fccr!  ( )
;
: sp-clksel  ( n -- )
   d# 26 lshift                               ( field )
   fccr@  h# 1c00.0000 invert and  or  fccr!  ( )
;
: pj4-cc!  ( n -- )  4 pmua!  ;
: sp-cc!   ( n -- )  0 pmua!  ;

\ Undocumented bits in CC regs:
\ 1000.0000 forces immediate (non-voting) change of (XPCLK), BACLK, (CSCLK), and PCLK on this processor
\ 2000.0000 forces immediate (non-voting) change of DCLK (for both processors)
\ 4000.0000 forces immediate (non-voting) change of ACLK (for both processors)

\                 PSD                 cfvaaADXBCP            cfvaaADXBCP

\ A100 D400  PJ: X100 B100 C100 P100  SP: B100 C200
: op1  ( -- )  h# 00800000 fccr!   o# 36042700301 sp-cc!  o# 36042703333 pj4-cc!  ;

\ A200 D400  PJ: X200 B200 C200 P200  SP: B100 C200
: op2  ( -- )  h# 00800000 fccr!   o# 36042300301 sp-cc!  o# 36042301111 pj4-cc!  ;

\ A200 D400  PJ: X400 B400 C400 P400  SP: B100 C200
: op3  ( -- )  h# 00800000 fccr!   o# 36042300301 sp-cc!  o# 36042300000 pj4-cc!  ;

\ A266 D400  PJ: X400 B400 C400 P800  SP: B100 C200
: op4  ( -- )  h# 20800000 fccr!   o# 36042200301 sp-cc!  o# 36042201110 pj4-cc!  ;

: clk-fast  ( -- )
   ffffffff 24 mpmu!  \ PMUM_CGR_SP     \ All clocks ON
   op4
;
