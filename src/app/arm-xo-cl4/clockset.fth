: basic-setup  ( -- )  \ SoC fixups
;

: fc-delay  ( -- )  d# 500 us  ;

   \ PLL1:797, PLL2:OFF, PLL1OUTP:OFF, PLL2OUTP: OFF
   \ MP1:797, MP2:797, MM:399, ACLK:399, DDRCH1:399, DDRCH2:399, AXI1:399, AXI2:200
   \ CONFIG PLL2
   \     h# 00000100  h#  34 mpmu-clr
   \     h# 00000001  h# 418 mpmu-set
   \  h# 01090099   h# 414 mpmu!
   \  h# 001A6A00   h# 034 mpmu!
   \     h# 00000100  h# 034 mpmu-set
   \    fc-delay
   \     h# 20000000  h# 414 mpmu-set
   \    fc-delay

: set-frequency-800m  ( -- )   \  Static Frequency Change
   \ pjdiv 0, atdiv 2, reserved 3, peripheral 1, ddrdiv 0, axidiv 0, mb1 f, mb1 1
   h# 00BC02D0  04 pmua!	  	\ PMUA_CC_PJ  (octal 57001320)
   h# 01fffe07  h# 150 pmua-clr		\ PMUA_CC2_PJ  - clear divisor fields

   \  axi clk2 div = 1 (ratio = 2), mmcore pclk 1 (ratio = 2), aclk div 1 (ratio = 2)
   h# 00220001  h# 150 pmua-set
   h# 01f00000  h# 188 pmua-clr		\ PMUA_CC3_PJ  clear divisor field
   h#   100000  h# 188 pmua-set		\  set low bit of ATCLK/PCLKDBG ratio field

   \  PMUM_FCCR - PJCLKSEL 1 (use PLL1), SPCLKSEL 0 (PLL1/2),
   \ DDRCLKSEL 0 (PLL1/2),  PLL1REFD = 0, PLL1FBD = 8
   h# 20800000  h# 08 mpmu!

   \ PMUA_BUS_CLK_RES_CTRL - DCLK2_PLL_SEL = 1 (PLL1),
   \ SOC_AXI_CLK_PLL_SEL = 0 (PLL1/2), unreset both DDR channels
   h# 00000203  h# 06c pmua!

   \ h# 000FFFFF h# 088 pmua!
   \ h# 000FFFFF h# 190 pmua!
   fc-delay
   h# F0000000  h# 004 pmua-set	\  force frequency change
   fc-delay
;

: set-frequency-1g  ( -- )   \  Static Frequency Change
   h#       10  h# 68 mpmu-set      \ PMUM_PLL_DIFF_CTRL - Enable PLL1CLKOUTP

   \ pjdiv 0, atdiv 2, reserved 3, peripheral 2, ddrdiv 0, axidiv 0, mb1 f, mb1 1
   h# 00BC04D0  h# 004 pmua!	  	\ PMUA_CC_PJ  (octal 57002321)
   h# 01fffe07  h# 150 pmua-clr		\ PMUA_CC2_PJ  - clear divisor fields

   \  axi clk2 div = 1 (ratio = 2), mmcore pclk 1 (ratio = 2), aclk div 1 (ratio = 2)
   h# 00220001  h# 150 pmua-set
   h# 01f00000  h# 188 pmua-clr		\ PMUA_CC3_PJ  clear divisor field
   h#   100000  h# 188 pmua-set		\  set low bit of ATCLK/PCLKDBG ratio field

   \  PMUM_FCCR - PJCLKSEL 3 (use PLL1CLKOUTP), SPCLKSEL 0 (PLL1/2),
   \ DDRCLKSEL 1 (PLL1),  PLL1REFD = 0, PLL1FBD = 8
   h# 60800000  h# 08 mpmu!

   \ PMUA_BUS_CLK_RES_CTRL - DCLK2_PLL_SEL = 1 (PLL1),
   \ SOC_AXI_CLK_PLL_SEL = 0 (PLL1/2), unreset both DDR channels
   h# 00000203  h# 06c pmua!

   \ h# 000FFFFF h# 088 pmua!
   \ h# 000FFFFF h# 190 pmua!
   fc-delay
   h# F0000000  h# 004 pmua-set	\  force frequency change
   fc-delay
;

: set-frequency-1.2g  ( -- )   \  Static Frequency Change
   h#      100  h#  34 mpmu-clr     \ PMUM_CONF_PLL2 - Disable PLL2
   h#       e8  h# 418 mpmu-set     \ PMUM_PLL2_CTRL - Enable phase interpolators and set bias

   h# 05390699  h# 414 mpmu!        \ PMUM_PLL2_CTRL1 - post-div 2, 6 uA charge pump, 2.3-2.4 GHz VCO range

\ For now, enabling spead spectrum is causing problems.
\  h# 01566EEF  h# 41C mpmu!        \ PMUM_PLL2_CTRL3 - spread spectrum settings

   h# 001C5200  h#  34 mpmu!        \ PMUM_PLL2CR - ref div 3, fbdiv 276 (0x114) for 2392 MHz
   fc-delay
   h#      100  h#  34 mpmu-set     \ PMUM_PLL2CR - Enable PLL2
   fc-delay
   h# 20000000  h# 414 mpmu-set     \ Release PLL2 reset
   fc-delay
   h#       11  h#  68 mpmu!        \ PMUM_PLL_DIFF_CTL - Enable PLL1_CLKOUTP, postdiv 1.5
   fc-delay

   \ Static Frequency Change
   h# 00BC04D0  h#  04 pmua!        \ PMUA_CC_PJ - ddrclk/1, periphclk/6, atclk/3, pjclk/1
   h# 01fffe07  h# 150 pmua-clr
   h# 80240001  h# 150 pmua-set     \ PMUA_CC2_PJ - aclk/2, mm/1, mp2/1, mp1/1, axiclk/2

   h# 01f00000  h# 188 pmua-clr	    \ PMUA_CC3_PJ  clear divisor field
   h# 00100000  h# 188 pmua-set     \  set low bit of ATCLK/PCLKDBG ratio field

   \ PMUM_FCCR - PJCLKSEL 2 (use PLL2), SPCLKSEL 0 (PLL1/2),
   \ DDRCLKSEL 3, PLL1CEN 0
\  h# 41800000  h#  08 mpmu!  \ For running memory at 533
   h# 40800000  h#  08 mpmu!  \ For running memory at 400

   \ PMUA_BUS_CLK_RES_CTRL - DCLK2_PLL_SEL = 3 (PLL1_CLKOUTP),
   \ SOC_AXI_CLK_PLL_SEL = 0 (PLL1/2), unreset both DDR channels
\  h# 00000603  h#  6c pmua!  \ For running memory at 533
   h# 00000203  h#  6c pmua!  \ For running memory at 400
   fc-delay

   h# f0000000  h#   4 pmua-set  	\  force frequency change
   fc-delay
;
