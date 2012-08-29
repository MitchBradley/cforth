: enable-aib  ( -- )
   h# 00000003 h# 15064 io!		\  enable AIB
   d# 500 us
;
: twsi1!  ( n offset -- )  h# 11000 + io!  ;
: twsi1-clk-on  ( -- )
   h# 000000004 h# 15004 io!
   d# 500 us
   h# 000000007 h# 15004 io!
   d# 500 us
   h# 000000003 h# 15004 io!
   d# 500 us
;
: init-twsi1  ( -- )
   h# 4060 h# 10 twsi1!  d# 500 us
   h#   60 h# 10 twsi1!  d# 500 us
   h#    0 h# 10 twsi1!
;
: setup-twsi1  ( -- )
   enable-aib

   \ TWSI1 pins
   h# 00000400 h# 01E140 +io bitset	\  Set MFPR to AF0 for TWSI1_SCL
   h# 00000400 h# 01E144 +io bitset	\  Set MFPR to AF0 for TWSI1_SDA
   d# 500 us

   twsi1-clk-on
   init-twsi1
;
: twsi1-put  ( n reg10-val -- )  swap 8 twsi1!  h# 10 twsi1!  d# 500 us  ;
: twsi1-reg!  ( value reg# slave-adr -- )
   h# 69 twsi1-put  h# 68 twsi1-put  h# 6a twsi1-put  d# 20000 us
;

: set-voltages  ( -- )
   setup-twsi1

   h# 08 h# 01 h# c0 twsi1-reg!	\ Fairchild (c0), VSEL1 (01), core voltage change, 1257 mv, 600 mv ref, 12.826 mv step

   \ XXX - According to the schematic, the PM800 voltage is controlled by GPIO8 and GPIO9
   \  DDR3L Voltage Change and Termination Enable
   \  Turn on reduce DDR Voltage (SD2) to 1.35V
   h# 3c h# 40 h# 62 twsi1-reg!	\ PM800 (62), VBUCK2_SET (40), enable, 1.35 V, 12.5 mV step, 600 mV base
   
   \  Turn on SD2 to power up termination regulator
   h# 0f h# 50 h# 62 twsi1-reg!	\ PM800 (62), BUCK_ENABLE (50), enable, 1.35 V, 12.5 mV step, 600 mV base
;

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

0 [if]
: xxx-setup-dram  ( -- )

   \ DDR3L-400 CH1
   h# 000D0001 h# D0000010 l!		\ MMAP0
   h# 00042430 h# D0000020 l!		\ SDRAM_CONFIG_TYPE1-CS0
   h# 00000000 h# D0000030 l!		\ SDRAM_CONFIG_TYPE2-CS0
   \ Timing
   h# 911403CF h# D0000080 l!       	\ SDRAM_TIMING1
   h# 64660404 h# D0000084 l!		\ SDRAM_TIMING2
   h# C2004453 h# D0000088 l!       	\ SDRAM_TIMING3
   h# 34F4A187 h# D000008C l!       	\ SDRAM_TIMING4
   h# 000F20C1 h# D0000090 l!       	\ SDRAM_TIMING5
   h# 04040200 h# D0000094 l!       	\ SDRAM_TIMING6
   h# 00005501 h# D0000098 l!       	\ SDRAM_TIMING7
   \ Control
   h# 00000000 h# D0000050 l!		\ SDRAM_CTRL1
   h# 00000000 h# D0000054 l!        	\ SDRAM_CTRL2
   h# 20C08009 h# D0000058 l!       	\ SDRAM_CTRL4
   h# 00000201 h# D000005C l!		\ SDRAM_CTRL6_SDRAM_ODT_CTRL
   h# 0200000A h# D0000060 l!		\ SDRAM_CTRL7_SDRAM_ODT_CTRL2
   h# 00000000 h# D0000064 l!		\ SDRAM_CTRL13
   h# 00000000 h# D0000068 l!		\ SDRAM_CTRL14
   \ !#__PHY Deskew PLL config and PHY initialization
   h# 00300008 h# D0000240 l!		\ PHY_CTRL11
   h# 80000000 h# D000024C l!		\ PHY_CTRL14
   h# 000031d8 h# D000023C l!		\ PHY_CTRL0
   h# 20004055 h# D0000220 l!		\ PHY_CTRL3
   h# 1FF84A79 h# D0000230 l!        	\ PHY_CTRL7
   h# 0FF00A70 h# D0000234 l!        	\ PHY_CTRL8
   h# 000000A7 h# D0000238 l!        	\ PHY_CTRL9
   h# F0210000 h# D0000248 l!      	\ PHY_CTRL13
   \ PHY DLL Tuning 
   h# 00000000 h# D0000300 l!        	\ PHY DATA BYTE SEL
   h# 00001080 h# D0000304 l!        	\ PHY DLL CTRL
   h# 00000001 h# D0000300 l!        	\ PHY DATA BYTE SEL
   h# 00001080 h# D0000304 l!        	\ PHY DLL CTRL
   h# 00000002 h# D0000300 l!        	\ PHY DATA BYTE SEL
   h# 00001080 h# D0000304 l!        	\ PHY DLL CTRL
   h# 00000003 h# D0000300 l!        	\ PHY DATA BYTE SEL
   h# 00001080 h# D0000304 l!        	\ PHY DLL CTRL
   \ Read Leveling CS0
   h# 00000100 h# D0000380 l!
   h# 00000200 h# D0000390 l!
   h# 00000101 h# D0000380 l!
   h# 00000200 h# D0000390 l!
   h# 00000102 h# D0000380 l!
   h# 00000200 h# D0000390 l!
   h# 00000103 h# D0000380 l!
   h# 00000200 h# D0000390 l!
   \ DLL reset
   h# 20000000 h# D000024C bitset	\ # DLL reset
   d# 68 us
   h# 00030001 h# D0000160 l!		\ USER_INITIATED_COMMAND0
   d# 68 us
   h# 40000000 h# D000024C bitset	\ # DLL update via pulse mode
   h# 68 us

   \ DDR3L-400 CH0
   h# 000D0001 h# D0010010 l!		\ MMAP0
   h# 00042430 h# D0010020 l!		\ SDRAM_CONFIG_TYPE1-CS0
   h# 00000000 h# D0010030 l!		\ SDRAM_CONFIG_TYPE2-CS0
   \ Timing
   h# 911403CF h# D0010080 l!       	\ SDRAM_TIMING1
   h# 64660404 h# D0010084 l!		\ SDRAM_TIMING2
   h# C2004453 h# D0010088 l!       	\ SDRAM_TIMING3
   h# 34F4A187 h# D001008C l!       	\ SDRAM_TIMING4
   h# 000F20C1 h# D0010090 l!       	\ SDRAM_TIMING5
   h# 04040200 h# D0010094 l!       	\ SDRAM_TIMING6
   h# 00005501 h# D0010098 l!       	\ SDRAM_TIMING7
   \ Control
   h# 00000000 h# D0010050 l!		\ SDRAM_CTRL1
   h# 00000000 h# D0010054 l!        	\ SDRAM_CTRL2
   h# 20C08009 h# D0010058 l!       	\ SDRAM_CTRL4
   h# 00000201 h# D001005C l!		\ SDRAM_CTRL6_SDRAM_ODT_CTRL
   h# 0200000A h# D0010060 l!		\ SDRAM_CTRL7_SDRAM_ODT_CTRL2
   h# 00000000 h# D0010064 l!		\ SDRAM_CTRL13
   h# 00000000 h# D0010068 l!		\ SDRAM_CTRL14
   \ !#__PHY Deskew PLL config and PHY initialization
   h# 00300008 h# D0010240 l!		\ PHY_CTRL11
   h# 80000000 h# D001024C l!		\ PHY_CTRL14
   h# 000031d8 h# D001023C l!		\ PHY_CTRL0
   h# 20004055 h# D0010220 l!		\ PHY_CTRL3
   h# 1FF84A79 h# D0010230 l!        	\ PHY_CTRL7
   h# 0FF00A70 h# D0010234 l!        	\ PHY_CTRL8
   h# 000000A7 h# D0010238 l!        	\ PHY_CTRL9
   h# F0210000 h# D0010248 l!      	\ PHY_CTRL13
   \ PHY DLL Tuning 
   h# 00000000 h# D0010300 l!        	\ PHY DATA BYTE SEL - byte 0
   h# 00001080 h# D0010304 l!        	\ PHY DLL CTRL phase is funny because it affects 2 fields
   h# 00000001 h# D0010300 l!        	\ PHY DATA BYTE SEL - byte 1
   h# 00001080 h# D0010304 l!        	\ PHY DLL CTRL
   h# 00000002 h# D0010300 l!        	\ PHY DATA BYTE SEL - byte 2
   h# 00001080 h# D0010304 l!        	\ PHY DLL CTRL
   h# 00000003 h# D0010300 l!        	\ PHY DATA BYTE SEL - byte 3
   h# 00001080 h# D0010304 l!        	\ PHY DLL CTRL
   \ Read Leveling CS0
   h# 00000100 h# D0010380 l!		\ select CS1 byte 0
   h# 00000200 h# D0010390 l!		\ RL pos edge, cycle delay 2, tap delay 0
   h# 00000101 h# D0010380 l!		\ select CS1 byte 1
   h# 00000200 h# D0010390 l!		\ RL pos edge, cycle delay 2, tap delay 0
   h# 00000102 h# D0010380 l!		\ select CS1 byte 2
   h# 00000200 h# D0010390 l!		\ RL pos edge, cycle delay 2, tap delay 0
   h# 00000103 h# D0010380 l!		\ select CS1 byte 3
   h# 00000200 h# D0010390 l!		\ RL pos edge, cycle delay 2, tap delay 0
   \ !# DLL reset
   h# 20000000 h# D001024C bitset	\ DLL reset
   d# 68 us
   h# 00030001 h# D0010160 l!        	\ USER_INITIATED_COMMAND0
   d# 68 us
   h# 40000000 h# D001024C bitset	\ # DLL update via pulse mode
   h# 68 us

   \  disable interleave
\   h# 00000000 h# 282ca0 io!
   d# 5000 us
;
[then]

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

\ This makes Thunderstone hang
\   set-voltages

  \  CORE RTC/WTC
  \  using default for high mips

  \  PLL1:797, PLL2:OFF, PLL1OUTP:OFF, PLL2OUTP: OFF
  \  MP1:797, MP2:797, MM:399, ACLK:399, DDRCH1:399, DDRCH2:399, AXI1:399, AXI2:200
  \  CONFIG PLL2
  \      h# 00000100  h# 034 mpmu-clr
  \      h# 00000001  h# 418 mpmu-set
  \   h# 01090099   h# 414 mpmu!
  \   h# 001A6A00   h# 034 mpmu!
  \      h# 00000100  h# 034 mpmu-set
  \     d#   500 us
  \      h# 20000000  h# 414 mpmu-set
  \     d#   500 us

   set-frequency
;

hex
create dram-tablex lalign
   \ DDR3L-400
   000D0001 , 010 ,		\ MMAP0
   00042430 , 020 ,		\ SDRAM_CONFIG_TYPE1-CS0
   00000000 , 030 ,		\ SDRAM_CONFIG_TYPE2-CS0

   \ Timing
   911403CF , 080 ,       	\ SDRAM_TIMING1
   64660404 , 084 ,		\ SDRAM_TIMING2
   C2004453 , 088 ,       	\ SDRAM_TIMING3
   34F4A187 , 08C ,       	\ SDRAM_TIMING4
   000F20C1 , 090 ,       	\ SDRAM_TIMING5
   04040200 , 094 ,       	\ SDRAM_TIMING6
   00005501 , 098 ,       	\ SDRAM_TIMING7

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
   80000000 , 24C ,		\ PHY_CTRL14
   000031d8 , 23C ,		\ PHY_CTRL0
   20004055 , 220 ,		\ PHY_CTRL3
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
