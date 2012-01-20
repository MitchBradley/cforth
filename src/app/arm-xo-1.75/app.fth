\ Load file for application-specific Forth extensions

alias purpose: \

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth

fl hwaddrs.fth
fl addrs.fth

: +io  ( offset -- adr )  h# d4000000 +  ;
: io!  ( l offset -- )  +io l!  ;
: io@  ( offset l -- )  +io l@  ;
: +io!@     ( l offset base -- )  + tuck io! io@ drop  ;

defer ms  defer get-msecs
fl timer.fth
fl watchdog.fth
fl timer2.fth
fl gpio.fth
fl mfpr.fth
fl boardgpio.fth

: alloc-mem  drop 0  ;  : free-mem 2drop  ;
\ fl flashif.fth
\ fl spiif.fth
\ fl spiflash.fth
\ fl sspspi.fth
fl clockset.fth
fl initdram.fth
fl fuse.fth
fl smbus.fth

: wljoin  ( w w -- l )  d# 16 lshift or  ;
: third  ( a b c -- a b c a )  2 pick  ;
fl lcdcfg.fth
fl lcd.fth
[ifndef] cl3
fl mmp2dcon.fth
[then]

: short-delay ;

0 ccall: spi-send        { a.adr i.len -- }
1 ccall: spi-send-only   { a.adr i.len -- }
2 ccall: spi-read-slow   { a.adr i.len i.offset -- }
3 ccall: spi-read-status { -- i.status }
4 ccall: spi-send-page   { a.adr i.len i.offset -- }
5 ccall: spi-read        { a.adr i.len i.offset -- }
6 ccall: lfill           { a.adr i.len i.value -- }
7 ccall: lcheck          { a.adr i.len i.value -- i.erraddr }
8 ccall: inc-fill          { a.adr i.len -- }
9 ccall: inc-check         { a.adr i.len -- i.erraddr }
d# 10 ccall: random-fill   { a.adr i.len -- }
d# 11 ccall: random-check  { a.adr i.len -- i.erraddr }
d# 12 ccall: (inflate)     { a.compadr a.expadr i.nohdr a.workadr -- i.expsize }
d# 13 ccall: control@      { -- i.value }
d# 14 ccall: control!      { i.value -- }
d# 15 ccall: tcm-size@     { -- i.value }
d# 16 ccall: inflate-adr   { -- a.value }
d# 17 ccall: byte-checksum { a.adr i.len -- i.checksum }
d# 18 ccall: wfi           { -- }
d# 19 ccall: psr@          { -- i.value }
d# 20 ccall: psr!          { i.value -- }
d# 21 ccall: kbd-bit-in    { -- i.value }
d# 22 ccall: kbd-bit-out   { i.value -- }
d# 23 ccall: ps2-devices   { -- a.value }
d# 24 ccall: init-ps2      { -- }
d# 25 ccall: ps2-out       { i.byte i.device# -- i.ack? }
d# 26 ccall: 'one-uart     { -- a.value }
d# 27 ccall: reset-reason  { -- i.value }
d# 28 ccall: 'version      { -- a.value }
d# 29 ccall: 'build-date   { -- a.value }
d# 30 ccall: wfi-loop      { -- }
d# 31 ccall: ukey1?        { -- i.value }
d# 32 ccall: ukey3?        { -- i.value }
d# 33 ccall: ukey4?        { -- i.value }

: .commit  ( -- )
   'version cscount 
   dup d# 8 >  if
      drop 8 type  ." ..."
   else 
      type
   then
;
: .built  ( -- )  
;
: banner  ( -- )
   cr ." CForth built " 'build-date cscount type
   ."  from commit " .commit
   cr
;

: enable-interrupts  ( -- )  psr@ h# 80 invert and psr!  ;
: disable-interrupts  ( -- )  psr@ h# 80 or psr!  ;

fl keypad.fth

[ifdef] cl3
: early-activate-cforth?  ( -- flag )
   d# 200 ms  ukey3?      ( flag )
   dup  if
      begin  key?  while  key drop  repeat
   then
;
false constant activate-cforth?
false constant show-fb?
[else]
: rotate-button?  ( -- flag )
   [ifdef] cl2-a1  d# 20  [else]  d# 15  [then]
   gpio-pin@  0=
;
: check-button?  ( -- flag )
[ifdef] use_mmp2_keypad_control
   scan-keypad 2 and   0=
[else]
   d# 17 gpio-pin@  0=
[then]
;
: early-activate-cforth?  ( -- flag )  rotate-button?  ;
: activate-cforth?  ( -- flag )  rotate-button?  ;
: show-fb?  ( -- flag )  check-button?  ;
[then]

false value fb-shown?
h# 8009.1100 constant fb-on-value
: show-fb  ( -- )  fb-on-value h# 190 lcd!  ;
: ?visible  ( -- )
   \ Stop polling after the check button is seen for the first time,
   \ thus avoiding conflicts with OFW's use of the check button
   fb-shown?  if  exit  then
   show-fb?  if  show-fb  true to fb-shown?  then
;

[ifdef] notdef
d# 4 constant hdisp-lowres
d# 3 constant vdisp-lowres
[then]

fl fbnums.fth
: blank-display-lowres  ( -- )
   \ Setup the panel path with the normal resolution
   init-lcd

[ifdef] notdef
   \ This trick uses the hardware scaler so we can display a blank
   \ white screen very quickly, without spending a lot of time
   \ filling the frame buffer with a constant value.

   \ Set the source resolution to 4x3
    hdisp-lowres vdisp-lowres wljoin h# 104 lcd!

   \ Set the pitch to 0 so we only have to fill one line
   0 h# fc lcd!

   \ Fill one line of the screen
   \ Since hdisp-lowres is 4, one line is a single longword!
   display-pa  hdisp-lowres  h# ffffffff lfill

   \ Set the depth to 8 bpp
   h# 800a1100 h# 190 lcd!
[else]
   \ Start with all display data sources off
   0 h# 190 lcd!

   \ Set the source resolution to 12x9
   h# 9000c h# 104 lcd!

   \ Set the pitch to 6 (12 pixels * 4 bits/pixel / 8 bits/byte )
   6 h# fc lcd!

   \ Set the no-display-source background color to white
   h# ffffffff h# 124 lcd!

   \ Fill the rudimentary frame buffer with white
   diagfb-pa 6 9 *  h# ff fill

   \ Turn on the display if the user presses the check key
   ?visible
[then]

   \ Enable the display
   init-xo-display
;

fl hackspi.fth
fl dropin.fth

[ifdef] cl3
: enable-ps2 ;
[else]
fl ps2.fth
[then]
fl spicmd.fth
fl thermal.fth

0 value memtest-start
h# 1000.0000 value memtest-length
: memtest  ( adr len -- )
   ." Random pattern test from " memtest-start u.
   ." to " memtest-start memtest-length + 1- u. cr
   ." Filling ..." cr
   memtest-start memtest-length random-fill
   ." Checking ..." cr
   memtest-start memtest-length random-check
   dup -1 =  if
      drop
      ." Good" cr
   else
      ." ERROR at address " u. cr
   then
;

\ Drop the voltage to the lower level for testing
: board-config
[ifdef] notdef
   d# 11 gpio-pin@  if
      cr ." APPARENT CRASH RESET - INTERACTING - reset reason = "
      reset-reason . cr cr
      hex protect-fw quit
   then
[then]
   open-ec  board-id@  close-ec  ( id )

   dup h# 1b1 >=  if             ( id )
      ." Using lower core voltage" cr
      d# 11 gpio-set
      0 sleep1 +edge-clr  d# 11  af!  \ This is VID2 - we want it to stay high during suspend
   then                          ( id )

   dup h# 1c1 >=  if             ( id )
       \ Rev C has pullups/downs for the memory config inputs, so we turn off
       \ the pulldowns to avoid unnecessary current.  The MPFRs are initially
       \ configured for pulldowns so A and B boards will report 512 MiB memory.
       0 sleepi 0 af!
       0 sleepi 1 af!
   then                          ( id )

   drop                          ( )
;

: init
   banner
   basic-setup
   init-timers
   enable-wdt-clock
   set-gpio-directions
   init-mfprs
[ifdef] use_mmp2_keypad_control
   keypad-on
   8 keypad-direct-mode
[then]
   board-config
;
: fix-v7  ( -- )
   h# 282c08 io@  2 and  0=  if
      ." Processor is fused in V6 mode - switching to V7" cr
      h# 282c08 io@  2 or  h# 282c08 io!
   then
;

: init1
   clk-fast
   init-dram
[ifdef] cl3
   fix-fuses
[then]
   fix-v7
   init-spi
[ifdef] SP_controls_kbd_power
   keyboard-power-on  \ Early to give the keyboard time to wake up
[then]
;

: cforth-wait  ( -- )
   begin  wfi  activate-cforth?  until
   ." Resuming CForth on Security Processor, second UART" cr
   1 'one-uart !
;

\ The SP and PJ4's address maps for memory differ, apparently for the purpose
\ of accomodating the "Tightly Coupled Memory" (TCM).
\ DDR/PJ-addr   SP-addr
\ 0x0xxx.xxxx   0x1xxx.xxxx
\ 0x1xxx.xxxx   0x2xxx.xxxx
\ ...
\ 0x6xxx.xxxx   0x7xxx.xxxx
\ 0x7xxx.xxxx   inaccessible?
\
\ When TCM is on,  SP-addr 0x0xxx.xxxx goes to TCM
\ When TCM is off, SP-addr 0x0xxx.xxxx goes to main memory 0x0xxx.xxxx (alias of 0x1xxx.xxxx)

: pj4>sp-adr  ( pj4-adr -- sp-adr )  h# 1000.0000 +  ;
: pj4-l!  ( l pj4-adr -- )  pj4>sp-adr l!  ;

0 value reset-offset
: ofw-go  ( -- )
   h# ea000000 h# 0 pj4-l!  \ b 8
   'compressed reset-offset +  h# 4 pj4-l!  \ reset vector address
   h# e51f000c h# 8 pj4-l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c pj4-l!  \ mov pc,r0

   ." releasing" cr
   0 h# 050020 io!  \ Release reset for PJ4
;

: load-ofw  ( -- )
   ( init-spi ) .spi-id
   " reset" drop-in-location abort" Can't find reset dropin"  ( adr len )
   swap h# 20000 - dup to reset-offset      ( len offset )
   +                                        ( size-to-read )
   'compressed swap h# 2.0000 spi-read      ( )
;
: dbg  ( -- )  
   ." CForth stays active on second serial port" cr
   'one-uart on
;
: ofw-up?  ( -- flag )  h# 190 lcd@  0<>  ;
: ?ofw-up  ( -- )
   d# 80 0 do
      ofw-up?  if  leave  then
      ?visible
      d# 100 ms
   loop

   \ Check to see if OFW took over the display
   ofw-up?  0=  if
      show-fb
      ." CForth says: OFW seems not to have booted all the way" cr
   then
;
: ofw  ( -- )
   init1
   blank-display-lowres
   h# 00 puthex  ?visible
   load-ofw
   h# 01 puthex  ?visible
   enable-ps2
   ofw-go

   ?ofw-up

   'one-uart @  0=  if
      wfi-loop
\     d# 4000 ms  cforth-wait
   then
;
: dmesg-dump ( -- )
   h# 10014 io@         ( magic )                       \ RTC_BR0
   h# 4f165bad = if     ( )
      cr cr
      h# 10018 io@      ( dmesg )                       \ RTC_BR1
      h# 1001c io@      ( dmesg size )                  \ RTC_BR2
      type              ( )
      cr cr
   then
;
: maybe-ofw  ( -- )
   early-activate-cforth?  if  ." Skipping OFW" cr  exit  then
   thermal?  if  ." thermal power-off" cr  power-off  then
   watchdog?  if  ." watchdog restart" cr  dmesg-dump  bye  then
   setup-thermal
   ofw
;

\ Start of alternative boot code.  This is used only for recovery/debugging purposes.
\ It is slower than the normal boot code.  This code performs the decompression
\ of the OFW image on the SP, whereas the normal boot code lets the PJ4 processor
\ do the decompression.

h# 1fa0.0000 constant ofw-pa

: ofw-go-slow  ( -- )
   h# ea000000 h# 0 pj4-l!  \ b 8
   ofw-pa      h# 4 pj4-l!  \ OFW load address
   h# e51f000c h# 8 pj4-l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c pj4-l!  \ mov pc,r0

   ." releasing" cr
   0 h# 050020 io!  \ Release reset for PJ4
;

: load-ofw-slow  ( -- )
   init-spi
   .spi-id

   ofw-pa pj4>sp-adr " firmware" load-drop-in
;
: ofw-slow  ( -- )
\   0 h# e0000 h# 20000 spi-read
\   spi-go
   activate-cforth?  if  ." Skipping OFW" cr  exit  then

   blank-display-lowres
   load-ofw-slow
   ofw-go-slow
   enable-ps2
   cforth-wait
\   begin wfi again
;

\ Run OFW on the security processor
\ This won't work on OFW builds that use virtual != physical addressing,
\ because the SP has no MMU.
: sp-ofw  ( -- )  load-ofw-slow  " " drop  ofw-pa pj4>sp-adr acall  ;

\ End of alternative boot code.

0 [if]
: t
   0 h# 0 l!
\  h# 2000.0000 dup l!
   h# 1000.0000 dup l!
   h#  800.0000 dup l!
   h#  400.0000 dup l!
   h#  200.0000 dup l!
   0 l@ .
;

: what  init-dram  t  ;
[then]

\ Run this at startup
: app  init  ( d# 400 ms )  maybe-ofw  hex protect-fw quit  ;
\ " ../objs/tester" $chdir drop

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
   ." ==SCU=="
   ." PJ4_CPU_CONF     " h# 08 s.8  ." CORESIGHT_CONFIG " h# 4c s.8 ." SP_CONFIG    " h# 50 s.8 cr
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
0 [if]
: fillit
   'compressed h# 48000 h# ff fill
;
: testit
   'compressed h# 48000 bounds do i @ dup -1 <> if i . . cr leave else drop then 4 +loop
;
: app  init0 clk-fast ." To init DRAM, type 'init1'.  To boot, type 'ofw'" cr  hex protect-fw quit ;
[then]

" app.dic" save
