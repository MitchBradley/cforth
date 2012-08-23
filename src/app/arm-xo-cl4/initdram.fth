: enable-aib  ( -- )
   h# 00000003 h# D4015064 l!		\  enable AIB
   d# 500 us
;

: set-voltages  ( -- )
;

: set-frequency  ( -- )   \  Static Frequency Change
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

: setup-platform  ( -- )
   h# 0000E000 h# D4051024 bitset \ PMUM_CGR_PJ - enable APMU_PLL1, APMU_PLL2, APMU_PLL1_2
   \  h# 88b99001 h# d4282800 l!    \ PMUA_CC_SP - frequency change for SP

   \ PM programming upon SOD
   \ PMUA_GENERIC_CTRL - bits 22,20,18,16,6,5,4  - tristate some pads in APIDLE state, enable SRAM retention
   h# 00550070  h# d4282a44 bitset

   \  h# 00000000   h# d428288c l!   \  Turn off coresight ram

   h# 00005400 h# 0000fc00 h# d4282c7c bitfld  \ CIU_PJ4MP1_PDWN_CFG_CTL - SRAM access delay
   h# 00005400 h# 0000fc00 h# d4282c80 bitfld  \ CIU_PJ4MP2_PDWN_CFG_CTL - SRAM access delay
   h# 00005400 h# 0000fc00 h# d4282c84 bitfld  \ CIU_PJ4MM_PDWN_CFG_CTL - SRAM access delay

   h# f0000200 h# d4282A48 bitclr	\ PMUA_PJ_C0_CC4 - clear L1_LOW_LEAK_DIS - UNDOCUMENTED!
   h# f0000200 h# d4282A4C bitclr	\ PMUA_PJ_C1_CC4 - clear L1_LOW_LEAK_DIS - UNDOCUMENTED!
   h# f0000200 h# d4282A50 bitclr	\ PMUA_PJ_C2_CC4 - clear L1_LOW_LEAK_DIS - UNDOCUMENTED!

   set-voltages

   \ CORE RTC/WTC
   \ using default for high mips

   \ PLL1:797, PLL2:OFF, PLL1OUTP:OFF, PLL2OUTP: OFF
   \ MP1:797, MP2:797, MM:399, ACLK:399, DDRCH1:399, DDRCH2:399, AXI1:399, AXI2:200
   \ CONFIG PLL2
   \     h# 00000100  h# d4050034 bitclr
   \     h# 00000001  h# d4050418 bitset
   \  h# 01090099   h# d4050414 l!
   \  h# 001A6A00   h# d4050034 l!
   \     h# 00000100  h# d4050034 bitset
   \    d#   500 us
   \     h# 20000000  h# d4050414 bitset
   \    d#   500 us

   set-frequency
;

\ Thunderstone - 2 chips per channel MT41K128M16HA-15E A0-A14 - 16 meg x 16 x 8 banks - 128 MiB / chip x 4 chips = 512 MiB
\   -15E is 1333 data rate  tRCD 13.5  tRP 13.5  CL 13.5b  tRCD 9  tRP 9  tCL 9   1.5 nS @CL9 

\ CL4 - same physical array.  H5TQ2G63BFR-H9C  63 is x16
\ -H9C is 1333 data rate  tCL 9  tRCD 9  tRP 9
\ row address is A0-A13   Col is A0-A9  BL switch A12/BC  AP is A10/AP  page size is 2 KB
\ tCK is 1.5 nS  nRCD 9 nRC 33  nRAS 24  nRP 9  nFAS 20  nRRD 5  nRFC 107
\ tAA 13.5..20   tRCD 13.5  tRP 13.5  tRC 49.5  tRAS 36 .. 9*tREFI

hex
create dram-tablex lalign
   \ DDR3L-400
   000e0001 , 010 ,		\ MMAP0
   00042530 , 020 ,		\ SDRAM_CONFIG_TYPE1-CS0
   00000000 , 030 ,		\ SDRAM_CONFIG_TYPE2-CS0

   \ Timing
   911403CF , 080 ,       	\ SDRAM_TIMING1
   64660784 , 084 ,		\ SDRAM_TIMING2
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
   if  h# d001.0000  else  h# d000.0000  then  +
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

2 value #mcs
: init-dram
   dram-on?  if  exit  then
   true to dram-on? 

   setup-platform

   #mcs 0  do
      dram-table /dram-table bounds  ?do
         i @  i na1+ @  j  mc!
      8 +loop
      i reset-dll
      begin  h# 8 i mc@ 1 and  until  \ Wait init done
   loop

   #mcs 2 =  if  h# 40  else  0  then   h# d4282ca0  l!   \ Interleave on 1 GiB boundary, or not at all
;

\ Simple address-independence test to find aliasing
\ Works well for 1 GiB, shows false aliasing at 60000000 for 2 GiB
\ because the SP can only access 0x70000000 bytes of DRAM due to the
\ 0x10000000 offset.
: p>s  h# 1000.0000 +  ;
: fi
   h# 4000.0000 #mcs *  0  do
      i  i p>s  l!
   h# 10.0000 +loop
;
: di
   h# 4000.0000 #mcs *  0  do
      i p>s l@  i <>  if  i . i l@ . leave  then
   h# 10.0000 +loop
;
: t  fi di  ;
