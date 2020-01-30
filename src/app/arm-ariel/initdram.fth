\ Ariel (Dell Wyse 3020) DRAM initialization
\
\ Based on src/app/arm-mmp3-thunderstone/initdram.fth

: set-frequency  ( -- )   \  Static Frequency Change
   \ pjdiv 0, atdiv 2, reserved 3, peripheral 1, ddrdiv 0, axidiv 0, mb1 f, mb1 1
   h# 00BC02D0  h# 004 pmua!	  	\ PMUA_CC_PJ  (octal 57001320)
   h# 01fffe07  h# 150 pmua-clr		\ PMUA_CC2_PJ  - clear divisor fields

   \  axi clk2 div = 1 (ratio = 2), mmcore pclk 1 (ratio = 2), aclk div 1 (ratio = 2)
   h# 00220001  h# 150 pmua-set
   h# 01f00000  h# 188 pmua-clr	\ PMUA_CC3_PJ  clear divisor field
   h#   100000  h# 188 pmua-set	\  set low bit of ATCLK/PCLKDBG ratio field

   \  PMUM_FCCR - PJCLKSEL 1 (use PLL1), SPCLKSEL 0 (PLL1/2),
   \ DDRCLKSEL 0 (PLL1/2),  PLL1REFD = 0, PLL1FBD = 8
   h# 20800000  h# 08 mpmu!

   \ PMUA_BUS_CLK_RES_CTRL - DCLK2_PLL_SEL = 1 (PLL1),
   \ SOC_AXI_CLK_PLL_SEL = 0 (PLL1/2), unreset both DDR channels
   h# 00000203  h# 6c pmua!

   \ h# 000FFFFF h# 088 pmua!
   \ h# 000FFFFF h# 190 pmua!
   d#   500 us
   h# F0000000  h# 04 pmua-set	\  force frequency change
   d#   500 us
;

: setup-platform  ( -- )
   h# 0000E000 h# 1024 mpmu-set \ PMUM_CGR_PJ - enable APMU_PLL1, APMU_PLL2, APMU_PLL1_2
   \  h# 88b99001 h# 00 pmua!    \ PMUA_CC_SP - frequency change for SP

   \ PM programming upon SOD
   \ PMUA_GENERIC_CTRL - bits 22,20,18,16,6,5,4  - tristate some pads in APIDLE state, enable SRAM retention
   h# 00550070  h# 244 pmua-set

   \  h# 00000000   h# 8c pmua!   \  Turn off coresight ram

   h# 00005400 h# 0000fc00 h# 282c7c +io bitfld  \ CIU_PJ4MP1_PDWN_CFG_CTL - SRAM access delay
   h# 00005400 h# 0000fc00 h# 282c80 +io bitfld  \ CIU_PJ4MP2_PDWN_CFG_CTL - SRAM access delay
   h# 00005400 h# 0000fc00 h# 282c84 +io bitfld  \ CIU_PJ4MM_PDWN_CFG_CTL - SRAM access delay

   h# f0000200 h# 248 pmua-clr	\ PMUA_PJ_C0_CC4 - clear L1_LOW_LEAK_DIS - UNDOCUMENTED!
   h# f0000200 h# 24C pmua-clr	\ PMUA_PJ_C1_CC4 - clear L1_LOW_LEAK_DIS - UNDOCUMENTED!
   h# f0000200 h# 250 pmua-clr	\ PMUA_PJ_C2_CC4 - clear L1_LOW_LEAK_DIS - UNDOCUMENTED!

   set-frequency
;

hex
create dram-tablex lalign
   000E0001 , 010 ,		\ MMAP0
   00046530 , 020 ,		\ SDRAM_CONFIG_TYPE1-CS0
   00000000 , 030 ,		\ SDRAM_CONFIG_TYPE2-CS0

   \ Timing
   51250066 , 080 ,       	\ SDRAM_TIMING1
   85880DF5 , 084 ,		\ SDRAM_TIMING2
   248C2AC2 , 088 ,       	\ SDRAM_TIMING3
   236350D1 , 08C ,       	\ SDRAM_TIMING4
   001721B0 , 090 ,       	\ SDRAM_TIMING5
   44040200 , 094 ,       	\ SDRAM_TIMING6
   00005555 , 098 ,       	\ SDRAM_TIMING7

   \ Control
   00000000 , 050 ,		\ SDRAM_CTRL1
   00000000 , 054 ,        	\ SDRAM_CTRL2
   20C08009 , 058 ,       	\ SDRAM_CTRL4
   00000201 , 05C ,		\ SDRAM_CTRL6_SDRAM_ODT_CTRL
   0200000A , 060 ,		\ SDRAM_CTRL7_SDRAM_ODT_CTRL2
   00000000 , 064 ,		\ SDRAM_CTRL13
   00000000 , 068 ,		\ SDRAM_CTRL14

   \ PHY Deskew PLL config and PHY initialization
   00300008 , 240 ,		\ PHY_CTRL11
   00005A01 , 24C ,		\ PHY_CTRL14
   000031d8 , 23C ,		\ PHY_CTRL0
   00004055 , 220 ,		\ PHY_CTRL3
   1FF84A79 , 230 ,        	\ PHY_CTRL7
   0FF00A70 , 234 ,        	\ PHY_CTRL8
   000000A7 , 238 ,        	\ PHY_CTRL9
   F0210000 , 248 ,      	\ PHY_CTRL13

   \ PHY DLL Tuning
   00000000 , 300 ,   00001080 , 304 ,
   00000001 , 300 ,   00001080 , 304 ,
   00000002 , 300 ,   00001080 , 304 ,
   00000003 , 300 ,   00001080 , 304 ,

   \ Read Leveling CS0
   00000100 , 380 ,   00000200 , 390 ,
   00000101 , 380 ,   00000200 , 390 ,
   00000102 , 380 ,   00000200 , 390 ,
   00000103 , 380 ,   00000200 , 390 ,

here dram-tablex laligned - constant /dram-table


: dram-table  dram-tablex laligned  ;
: .table  ( -- )
   dram-table /dram-table bounds  ?do
      i . ." : "  i @ 8 u.r  space  i na1+ @ 8 u.r  cr
   8 +loop
;

false value dram-on?
: +mc  ( offset channel -- adr )
   if  h# d000.0000  else  h# d001.0000  then  +
;
: mc!  ( value offset channel -- )  +mc l!  ;
: mc@  ( offset channel -- value )  +mc l@  ;

: reset-dll  ( mc# -- )
   >r
   h# 20000000 24c r@ mc!	\ DLL reset
   d# 68 us
   h# 00030001 160 r@ mc!	\ USER_INITIATED_COMMAND0 - reserved, SDRAM INIT
   d# 68 us
   h# 40000000 24c r> mc!	\ DLL update via pulse mode
   h# 68 us
;

: init-dram
   dram-on?  if  exit  then
   true to dram-on?

   setup-platform

   2 0  do
      dram-table /dram-table bounds  ?do
         i @  i na1+ @  j  mc!
      8 +loop
      i reset-dll
      begin  h# 8 i mc@ 1 and  until  \ Wait init done
   loop

   h# 20  h# 282ca0 io!   \ Interleave on 512 MB boundary
;
