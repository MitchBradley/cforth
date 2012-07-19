: bitclr   ( and-val regadr -- )  tuck l@ swap invert and swap l!  ;
: bitset   ( and-val regadr -- )  tuck l@ or  swap l!  ;
: bitfld   ( set-val clr-mask regadr -- )
   tuck l@  swap invert and      ( set-val regadr regval )
   rot or  swap l!
;

: basic-setup  ( -- )  \ SoC fixups
;

: set-clock-frequency  ( -- )   \  Static Frequency Change
   \ pjdiv 0, atdiv 2, reserved 3, peripheral 1, ddrdiv 0, axidiv 0, mb1 f, mb1 1
   h# 00BC02D0  h# d4282804 l!	  	\ PMUA_CC_PJ  (octal 57001320)
   h# 01fffe07  h# d4282950 bitclr	\ PMUA_CC2_PJ  - clear divisor fields

   \  axi clk2 div = 1 (ratio = 2), mmcore pclk 1 (ratio = 2), aclk div 1 (ratio = 2)
   h# 00220001  h# d4282950 bitset
   h# 01f00000  h# d4282988 bitclr	\ PMUA_CC3_PJ  clear divisor field
   h#   100000  h# d4282988 bitset	\  set low bit of ATCLK/PCLKDBG ratio field

   \  PMUM_FCCR - PJCLKSEL 1 (use PLL1), SPCLKSEL 0 (PLL1/2),
   \ DDRCLKSEL 0 (PLL1/2),  PLL1REFD = 0, PLL1FBD = 8
   h# 20800000  h# d4050008 l!

   \ PMUA_BUS_CLK_RES_CTRL - DCLK2_PLL_SEL = 1 (PLL1),
   \ SOC_AXI_CLK_PLL_SEL = 0 (PLL1/2), unreset both DDR channels
   h# 00000203  h# d428286c l!

   \ h# 000FFFFF h# d4282888 l!
   \ h# 000FFFFF h# d4282990 l!
   d#   500 us
   h# F0000000  h# d4282804 bitset	\  force frequency change
   d#   500 us
;
