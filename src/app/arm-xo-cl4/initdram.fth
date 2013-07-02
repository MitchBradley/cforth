: enable-aib  ( -- )
   h# 00000003 h# 15064 io!		\  enable AIB
   d# 500 us
;

: setup-platform  ( -- )
   \ PMUA_GENERIC_CTRL - bits 22,20,18,16,6,5,4  - tristate some pads in APIDLE state, enable SRAM retention
   h# 00550070  h# 244 pmua-set

   \ h# 00040000 h# 8c pmua-clr   \  Turn on coresight ram (default is off - bit set)

   h# 00005400 h# 0000fc00 h# 282c7c +io bitfld  \ CIU_PJ4MP1_PDWN_CFG_CTL - SRAM access delay
   h# 00005400 h# 0000fc00 h# 282c80 +io bitfld  \ CIU_PJ4MP2_PDWN_CFG_CTL - SRAM access delay
   h# 00005400 h# 0000fc00 h# 282c84 +io bitfld  \ CIU_PJ4MM_PDWN_CFG_CTL - SRAM access delay

   h# 00002000 h# 248 pmua-clr	\ PMUA_PJ_C0_CC4 - clear L1_LOW_LEAK_DIS
   h# 00002000 h# 24C pmua-clr	\ PMUA_PJ_C1_CC4 - clear L1_LOW_LEAK_DIS
   h# 00002000 h# 250 pmua-clr	\ PMUA_PJ_C2_CC4 - clear L1_LOW_LEAK_DIS
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
   \ MMAP0, SDRAM_CONFIG_TYPE1-CS0, SDRAM_CONFIG_TYPE2-CS0,
   \ SDRAM_TIMING1-3 are set from size-dependent tables

   \ Timing
   44F4A187 , 08C ,       	\ SDRAM_TIMING4
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

\                 mmap-cs0(10) cfg-type1-cs0(20) cfg-type2-cs0(30) sdram-timing1(80)  sdram-timing2(84) sdram-timing3(88)
create dram-2g    h# 000e0001 ,    h# 00042530 ,              0 ,   h# 911403cf ,    h# 64660784 ,  h# c2004453 ,
create dram-1g    h# 000d0001 ,    h# 00042430 ,              0 ,   h# 911403cf ,    h# 64660404 ,  h# c2003053 ,

create dram-x     h# 000e0001 ,    h# 00042530 ,              0 ,   h# 911403cf ,    h# 64660784 ,  h# c2004453 ,

false value dram-on?

0 value the-mc
: +mc  ( offset -- adr )
   the-mc  if  h# d001.0000  else  h# d000.0000  then  +
;
: mc!  ( value offset -- )  +mc l!  ;
: mc@  ( offset -- value )  +mc l@  ;

: @+  ( adr -- adr' value )  dup na1+ swap @  ;

: set-mem-size  ( adr -- )
   @+ h# 10 mc!   \ mmap0
   @+ h# 20 mc!   \ sdram-config-type1-cs0
   @+ h# 30 mc!   \ sdram-config-type2-cs0
   @+ h# 80 mc!   \ sdram-timing1
   @+ h# 84 mc!   \ sdram-timing2
   @+ h# 88 mc!   \ sdram-timing3
   drop
;

: reset-dll  ( -- )
   h# 20000000 24c mc!	\ DLL reset
   d# 68 us
   h# 00030001 160 mc!	\ USER_INITIATED_COMMAND0 - reserved, SDRAM INIT
   d# 68 us
   h# 40000000 24c mc!	\ DLL update via pulse mode
   h# 68 us
;

: memory-size-code  ( -- n )
   0 gpio-pin@ 1 and
   1 gpio-pin@ 2 and  or
;
: .bad-size  ( -- )
   ." Unsupported memory size!" cr
;
: memory-size-table  ( -- adr )
   memory-size-code  case
      0 of  dram-1g   endof
      1 of  dram-2g   endof
      2 of  dram-2g  .bad-size  endof  \ Placeholder - not yet defined
      3 of  dram-2g  .bad-size  endof  \ Placeholder - not yet defined
   endcase
;
: interleave-boundary  ( -- n )
   memory-size-code  case
      0 of  h# 20  endof  \ 1 GiB interleave boundary
      1 of  h# 40  endof  \ 512 MiB interleave boundary
      2 of  h# 20  endof  \ Placeholder - not yet defined
      3 of  h# 20  endof  \ Placeholder - not yet defined
   endcase
;

2 value #mcs
: init-dram
   dram-on?  if  exit  then
   true to dram-on? 

   setup-platform

   #mcs 0  do
      i to the-mc
      memory-size-table  set-mem-size
      dram-table /dram-table bounds  ?do
         i @  i na1+ @  mc!
      8 +loop
      reset-dll
      begin  h# 8 mc@ 1 and  until  \ Wait init done
   loop

   #mcs 1 =  if  2 h# 6c pmua-clr  then

   \ Set interleaving (none for only 1 memory controller)
   #mcs 2 =  if  interleave-boundary  else  0  then   h# 282ca0  io!
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
