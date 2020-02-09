\ Quick access to power management registers for debugging

: s@  h# 282c00 + io@  ;
: a@  h# 015000 + io@  ;
: p@  h# 282800 + io@  ;
: m@  h# 050000 + io@  ;
: s!  h# 282c00 + io!  ;
: a!  h# 015000 + io!  ;
: p!  h# 282800 + io!  ;
: m!  h# 050000 + io!  ;
: a.  a@ .  ;
: p.  p@ .  ;
: m.  m@ .  ;
: s.8  dup 3 u.r ." :" s@ 9 u.r  2 spaces ;
: a.4  dup 3 u.r ." :" a@ 3 u.r  2 spaces ;
: m.8  dup 4 u.r ." :" m@ 9 u.r  2 spaces ;
: p.8  dup 4 u.r ." :" p@ 9 u.r  2 spaces ;

: .scu
   ." ==SCU==" cr
   ." PJ4_CPU_CONF     " h# 08 s.8  ." CORESIGHT_CONFIG " h# 4c s.8  cr
   ." SP_CONFIG        " h# 50 s.8 cr
   ." AXIFAB_CKGT_CTRL0" h# 64 s.8  ." AXIFAB_CKGT_CTRL1" h# 68 s.8  cr
;
: .mpmu  ( -- )
   ." ==MPMU==" cr
   ." PCR_SP     "       0 m.8  ." PSR_SP   "       4 m.8  ." FCCR       "       8 m.8  cr
   ." POCR       " h#    c m.8  ." POSR     " h#   10 m.8  ." SUCCR      " h#   14 m.8  cr
   ." VRCR       " h#   18 m.8  ." PRR_SP   " h#   20 m.8  ." CGR_SP     " h#   24 m.8  cr
   ." RSR_SP     " h#   28 m.8  ." RET_TM   " h#   2c m.8  ." GPCP       " h#   30 m.8  cr
   ." PLL2CR     " h#   34 m.8  ." SCCR     " h#   38 m.8  ." ISCCR1     " h#   40 m.8  cr
   ." ISCCR2     " h#   44 m.8  ." WUCRS_SP " h#   48 m.8  ." WUCRM_SP   " h#   4c m.8  cr
   ." WDTPCR     " h#  200 m.8  cr
   ." PLL2_CTRL  " h#  414 m.8  ." PLL1_CTRL" h#  418 m.8  ." SRAM_PD    " h#  420 m.8  cr
   ." PCR_PJ     " h# 1000 m.8  ." PSR_PJ   " h# 1004 m.8  ." PRR_PJ     " h# 1020 m.8  cr
   ." CGR_PJ     " h# 1024 m.8  ." RSR_PJ   " h# 1028 m.8  ." WUCRS_PJ   " h# 1048 m.8  cr
   ." WUCRM_PJ   " h# 104c m.8  cr
;
: .pmua  ( -- )
   ." ==PMUA Misc==" cr
   ." CC_SP      "       0 p.8  ." CC_PJ    "       4 p.8  ." DM_CC_SP   "       8 p.8  cr
   ." DM_CC_PJ   " h#    c p.8  ." FC_TIMER " h#   10 p.8  ." SP_IDLE_CFG" h#   14 p.8  cr
   ." PJ_IDLE_CFG" h#   18 p.8  ." WAKE_CLR " h#   7c p.8  ." PWR_STAB_TM" h#   84 p.8  cr
   ." DEBUG      " h#   88 p.8  ." SRAM_PWR " h#   8c p.8  ." CORE_STATUS" h#   90 p.8  cr
   ." RES_SLP_CLR" h#   94 p.8  ." PJ_IMR   " h#   98 p.8  ." PJ_IRWC    " h#   9c p.8  cr
   ." PJ_ISR     " h#   a0 p.8  ." MC_HW_SLP" h#   b0 p.8  ." MC_SLP_REQ " h#   b4 p.8  cr
   ." MC_SW_SLP  " h#   c0 p.8  ." PLL_SEL  " h#   c4 p.8  ." PWR_ONOFF  " h#   e0 p.8  cr
   ." PWR_TIMER  " h#   e4 p.8  ." MC_PAR   " h#  11c p.8  cr
[ifdef] mmp3
   \ some of these might exist on mmp2 as well
   ." CC2_PJ     " h#  150 p.8  ." CC3_PJ   " h#  188 p.8  ." DEBUG2     " h#  190 p.8 cr
[then]
   ." ==PMUA Clock Controls==" cr
   ." CCIC_GATE  " h#   28 p.8  ." IRE_RES  " h#   48 p.8  ." DISP1_RES  " h#   4c p.8  cr
   ." CCIC_RES   " h#   50 p.8  ." SDH0_RES " h#   54 p.8  ." SDH1_RES   " h#   58 p.8  cr
   ." USB_RES    " h#   5c p.8  ." NF_RES   " h#   60 p.8  ." DMA_RES    " h#   64 p.8  cr
   ." WTM_RES    " h#   68 p.8  ." BUS_RES  " h#   6c p.8  ." VMETA_RES  " h#   a4 p.8  cr
   ." GC_RES     " h#   cc p.8  ." SMC_RES  " h#   d4 p.8  ." MSPRO_RES  " h#   d8 p.8  cr
   ." GLB_CTRL   " h#   dc p.8  ." SDH2_RES " h#   e8 p.8  ." SDH3_RES   " h#   ec p.8  cr
   ." CCIC2_RES  " h#   f4 p.8  ." HSI_RES  " h#  108 p.8  ." AUDIO_RES  " h#  10c p.8  cr
   ." DISP2_RES  " h#  110 p.8  ." CCIC2_RES" h#  118 p.8  ." ISP_RES    " h#  120 p.8  cr
   ." EPD_RES    " h#  124 p.8  ." APB2_RES " h#  134 p.8  cr
[ifdef] mmp3
   \ some of these might exist on mmp2 as well
   ." IDLE_CFG2  " h#  200 p.8  ." IDLE_CFG3" h#  204 p.8  ." ISL_POWER  " h#  220 p.8  cr
   ." ==Other Controls==" cr
   ." GENRC_CTL  " h#  244 p.8  cr
   ." PJ_C0_CC4  " h#  248 p.8  ." PJ_C1_CC4" h#  24C p.8  ." C2_CC4     " h#  250 p.8 cr
   ." CIU_PJ4MP1_PDWN_CFG_CTL " h# 47C p.8 cr
   ." CIU_PJ4MP2_PDWN_CFG_CTL " h# 480 p.8 cr
   ." CIU_PJ4MM_PDWN_CFG_CTL  " h# 484 p.8 cr
[then]
;
: .apbclks  ( -- )
   ." ==APB Clock/Reset==" cr
   ." RTC   " h# 00 a.4  ." TWSI1 " h# 04 a.4  ." TWSI2 " h# 08 a.4  ." TWSI3 " h# 0c a.4  ." TWSI4 " h# 10 a.4 cr
   ." 1WIRE " h# 14 a.4  ." KPC   " h# 18 a.4  ." TB    " h# 1c a.4  ." SWJTAG" h# 20 a.4  ." TMRS1 " h# 24 a.4 cr
   ." UART1 " h# 2c a.4  ." UART2 " h# 30 a.4  ." UART3 " h# 34 a.4  ." GPIO  " h# 38 a.4  ." PWM1  " h# 3c a.4 cr
   ." PWM2  " h# 40 a.4  ." PWM3  " h# 44 a.4  ." PWM4  " h# 48 a.4  ." SSP1  " h# 50 a.4  ." SSP2  " h# 54 a.4 cr
   ." SSP3  " h# 58 a.4  ." SSP4  " h# 5c a.4  ." AIB   " h# 64 a.4  ." USIM  " h# 70 a.4  ." MPMU  " h# 74 a.4 cr
   ." IPC   " h# 78 a.4  ." TWSI5 " h# 7c a.4  ." TWSI6 " h# 80 a.4  ." UART4 " h# 88 a.4  ." RIPC  " h# 8c a.4 cr
   ." THSENS" h# 90 a.4  ." COREST" h# 94 a.4  cr
   ." ==APB Clock Misc==" cr
   ." TWSI_INT" h# 84 a.4  ." THSENS_INT" h# a4 a.4  cr
;
: .pmu  .scu .mpmu .pmua .apbclks ;
