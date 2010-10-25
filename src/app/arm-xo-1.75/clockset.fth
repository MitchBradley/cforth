hex
: clk-fast
   ffffffff d4050024 l!  \ PMUM_CGR_SP     \ All clocks ON
   00061808 d4282888 l!  \ PMUA_DEBUG      \ Reserved bits, but supposed to "allow freq"

   00000000 d4050008 l!  \ Startup operation point
   08fd96d9 d4282800 l!  \ PMUA_CC_SP      \ speed change voting, ACLK:7, DCLK:5, BACLK1:1, PCLK:0
   78fd96d9 d4282804 l!  \ PMUA_CC_PJ      \ 

   \ select PLL2 frequency, 520MHz
   08600322 d4050414 l!  \ PMUM_PLL2_CTRL1 \ Bandgap+charge pump+VCO loading+regulator defaults, 486.3-528.55 PLL2 (bits 10:6)
   00FFFE00 d4050034 l!  \ PMUM_PLL2_CTRL2 \ refclk divisor and feedback divisors at max, software controls activation
   0021da00 d4050034 l!  \ PMUM_PLL2_CTRL1 \ refclk divisor=4, feedback divisor=0x76=118, software controls activation
   0021db00 d4050034 l!  \ PMUM_PLL2_CTRL2 \ same plus enable
   28600322 d4050414 l!  \ PMUM_PLL2_CTRL1 \ same as above plus release PLL loop filter
   \ select clock source, PJ4-PLL1, SP-PLL1/2, AXI/DDR-PLL1
\   20800000 d4050008 l!  \ PMUM_FCCR        PLL1 > PJ4 (bits 31:29), PLL1/2 > SP (bits 28:26), PLL1 > AXI&DDR (bits 25:23)
   24800000 d4050008 l!  \ PMUM_FCCR        PLL1 > PJ4 (bits 31:29), PLL1 > SP (bits 28:26), PLL1 > AXI&DDR (bits 25:23)
   \ divider setting and frequency change request, core-800, ddr-400, axi-200
   08fd8248 d4282800 l!  \ PMUA_CC_SP      \ speed change voting, ACLK:7, DCLK:5, BACLK1:1, PCLK:0
   78fd8248 d4282804 l!  \ PMUA_CC_PJ      \ 
;
