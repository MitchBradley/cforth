\ Interrupt controller debugging support

: icu@  h# 282000 + io@ ;

: d2/  ( d -- d' )
   dup 1 and >r                    ( low high r: carry )
   swap u2/                        ( high low' r: carry )
   r> if  h# 8000.0000 or  then    ( high low' )
   swap 2/                         ( d' )
;

: .masked  ( irq# -- )
   dup /l* h# 10c + icu@  ( irq# masked )
   1 and  if              ( irq# )
      ." IRQ" .d ." is masked off" cr
   else                   ( irq# )
      drop                ( )
   then                   ( )
;
: .selected  ( irq# -- )
   dup /l* h# 100 + icu@  ( irq# n )
   dup h# 40 and  if      ( irq# n )
      ." IRQ" swap .d     ( n )
      ." selected INT" h# 3f and .d  cr  ( )
   else                   ( irq# n )
      2drop               ( )
   then                   ( )
;
: (.pending)  ( d -- )
   ." pending INTs: "                      ( d )
   d# 64 0  do                             ( d )
      over 1 and  if  i .d  then           ( d )
      d2/                                  ( d' )
   loop                                    ( d )
   2drop                                   ( )
;
: .pending  ( irq# -- )
   dup 2* /l* h# 130 +  dup icu@  swap la1+ icu@   ( irq# d )
   2dup d0=  if                                    ( irq# d )
      3drop                                        ( )
   else                                            ( irq# d )
      ." IRQ " rot .d   (.pending)  cr             ( )
   then                                            ( )
;

: bit?  ( n bit# -- n flag )  1 swap lshift over and  0<>  ;
: .ifbit  ( n bit# msg$ -- n )
   2>r  bit?  if       ( n r: msg$ )
      2r> type  space  ( n )
   else                ( n r: msg$ )
      2r> 2drop        ( n )
   then                ( n )
;
: .enabled-ints  ( -- )
   d# 64 0  do                           ( )
      i /l* icu@  dup h# 70 and  if      ( n )
         ." INT" i .d ." -> IRQ "        ( n )
         4 " 0" .ifbit                   ( n )
         5 " 1" .ifbit                   ( n )
         6 " 2" .ifbit                   ( n )
         ."  Pri " h# f and .d  cr       ( )
      else                               ( n )
         drop                            ( )
      then                               ( )
   loop                                  ( )
;

: .int4  ( -- )
   ." INT4 - mask "  h# 168 icu@ .x
   ." status " h# 150 icu@ dup .x
   0   " USB " .ifbit
   1   " PMIC" .ifbit
   2   " SPMI" .ifbit  \ MMP3
   3   " CHRG_DTC_OUT" .ifbit  \ MMP3
   drop  cr
;
: .int5  ( -- )
   ." INT5 - mask "  h# 16c icu@ .x
   ." status " h# 154 icu@  dup .x
   0   " RTC " .ifbit
   1   " RTC_Alarm" .ifbit
   drop cr
;

: .int17  ( -- )
   ." INT17 - mask " h# 170 icu@ .x
   ." status " h# 158 icu@  dup .x  ( n )
   7 2 do              ( n )
      dup 1 and  if    ( n )
	." TWSI" i .d  ( n )
      then             ( n )
      u2/              ( n' )
   loop                ( n )
   drop  cr            ( )
;
: .int6  ( -- )  \ MMP3
   ." INT6 - mask "  h# 1a4 icu@ .x
   ." status " h# 1bc icu@  dup .x
   0   " ETHERNET" .ifbit
   2   " HSI_INT_3" .ifbit
   drop cr
;
: .int8  ( -- )  \ MMP3
   ." INT8 - mask "  h# 1a8 icu@ .x
   ." status " h# 1c0 icu@  dup .x
   0   " GC2000" .ifbit
   2   " GC300" .ifbit
   3   " MOLTRES_NGIC_2" .ifbit
   drop cr
;
: .int18  ( -- )
   ." INT18 - mask "  h# 1ac icu@ .x
   ." status " h# 1c4 icu@  dup .x
   1   " HSI_INT_2" .ifbit
   2   " MOLTRES_NGIC_1" .ifbit
   drop cr
;
: .int30  ( -- )
   ." INT30 - mask "  h# 1b0 icu@ .x
   ." status " h# 1c8 icu@  dup .x
   0   " ISP_DMA" .ifbit
   1   " DXO_ISP" .ifbit
   drop cr
;
: .int35  ( -- )
   ." INT35 - mask "  h# 174 icu@ .x
   ." status " h# 15c icu@  dup  .x
   drop cr
;
: .int42  ( -- )
   ." INT42 - mask " h# 1b4 icu@ .x
   ." status " h# 1cc icu@  dup  .x
   0 " CCIC2"  .ifbit
   1 " CCIC1"     .ifbit
   drop cr
;
: .int51  ( -- )
   ." INT51 - mask " h# 178 icu@ .x
   ." status " h# 160 icu@  dup  .x
   0 " SSP1_SRDY"  .ifbit
   1 " SSP3_SRDY"  .ifbit
   drop cr
;
: .int55  ( -- )
   ." INT55 - mask " h# 17c icu@ .x
   ." status " h# 184 icu@  dup  .x
   0 " MMC5"  .ifbit
   3 " HSI_INT_1" .ifbit
   drop cr
;
: .int57  ( -- )
   ." INT57 - mask " h# 180 icu@ .x
   ." status " h# 188 icu@  dup  .x
   d# 10 0 do                 ( n )
      dup 1 i lshift and  if  ( n )
	." DSP_AUDIO" i .d    ( n )
      then                    ( n )
   loop                       ( n )

   d# 10 " FABRIC_TIMEOUT"  .ifbit
   d# 11 " THERMAL_SENSOR"  .ifbit
   d# 12 " MPMU"            .ifbit
   d# 13 " WDT2"            .ifbit
   d# 14 " CORESIGHT"       .ifbit
   d# 15 " DDR"             .ifbit
   d# 16 " DDR2"            .ifbit
   d# 17 " NHWAFIRQ"        .ifbit
   d# 18 " SF_PARITY"       .ifbit
   d# 19 " MMU_PARITY"      .ifbit
   drop cr
;
: .int58  ( -- )
   ." INT55 - mask " h# 1b8 icu@ .x
   ." status " h# 1d0 icu@  dup  .x
   0 " MSP_CARD"      .ifbit
   1 " KERMIT_INT_0"  .ifbit
   2 " KERMIT_INT_1"  .ifbit
   4 " HSI_INT_0"     .ifbit
   drop cr
;

: .fiq  ( -- )
   h# 304 icu@  if  ." FIQ is masked off"  cr  then
   h# 300 icu@  dup  h# 40 and  if
      ." FIQ selected INT: " h# 3f and .d cr
   else
      drop
   then
   h# 310 icu@  h# 314 icu@  2dup d0=  if  ( d )
      2drop                                ( )
   else                                    ( d )
      ." FIQ " (.pending) cr               ( )
   then                                    ( )
;
  
: .dma-int
   ." DMA - mask " h# 11c icu@ .x
   ." status " h# 128 icu@  dup  .x
   d# 16 0 do                 ( n )
      dup 1 i lshift and  if  ( n )
	." PDMA" i .d         ( n )
      then                    ( n )
   loop                       ( n )
   d# 16 " ADMA0"  .ifbit
   d# 17 " ADMA1"  .ifbit
   d# 18 " ADMA2"  .ifbit
   d# 19 " ADMA3"  .ifbit
   d# 20 " VDMA0"  .ifbit
   d# 21 " VDMA1"  .ifbit
   drop cr
;
: .icu  ( -- )
   .enabled-ints
   3 0 do  i .masked  i .selected  i .pending  loop
   \ XXX should handle DMA interrupts too
   .fiq
   .int4  .int5  .int6  .int8  .int17 .int18
   .int30 .int35 .int42 .int51 .int55 .int57 .int58
   .dma-int
;
: .irqstat  ( -- )  h# 148 h# 130 do  i icu@ .  4 +loop   ;

