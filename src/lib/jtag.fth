: zero ( -- )  tms low   pulse  ;
: one  ( -- )  tms high  pulse  ;

: disconnect-remote  ( -- )
   normal-serial send-serial-break  \ TxD low
   rem-off ptt-off                  \ Turn off mainboard signals
   jtag-mode jtag-reset-on          \ All JTAG signals low
;

nuser current-scan-chain  -1 current-scan-chain !
nuser last-jtag-instruction  -1 last-jtag-instruction !

: reset-to-idle  ( -- )
   one pulse pulse pulse pulse
   -1 current-scan-chain !
   -1 last-jtag-instruction !
   zero
;
alias run-test/idle zero

[ifndef] shift-lsbs
\ shift-lsbs and shift-33msbs can be defined externally for extra speed.
: bit  ( flag -- flag' )
   if  tdi high  else  tdi low  then  tck high  tdo tst  tck low
;
: lsbit  ( n -- n' )  dup 1 and  bit h# 80000000 and  swap u2/ or  ;
: msbit  ( n -- n' )  dup 0<  bit  1 and  swap 2*  or  ;

: shift-lsbs  ( in #bits last first -- out )
   if  one zero zero  then   >r          ( in #bits r: last )  \ in shift-dr
   0  do  lsbit  loop                    ( out )   \ in shift-dr
   r>  if  tms high  lsbit  pulse  then  ( out' )  \ in shift-dr or update-dr
;

: shift-33msbs  ( in-data32 breakpoint? -- )
   \ Shift in the breakpoint bit, ignoring its previous state
   one zero zero                ( in breakpoint? )  \ now in shift-dr
   bit drop                     ( in )   \ shift breakpt bit

   \ Shift in/out 32 bits, MSB first, setting TMS prior to the last one
   d# 31 0  do  msbit  loop     ( n' )   \ still in shift-dr
   tms high   msbit             ( n' )   \ now in exit1-dr
   pulse                        ( out )  \ now in update-dr
;
[then]

: shift-32lsbs  ( n -- n' )  d# 31 1 true shift-lsbs  ;

: jtag-instruction  ( n -- )

   \ go to select-dr-scan state so the "one zero zero" sequence inside
   \ shift-lsbs will take us to shift-ir state instead of shift-dr state.
   one

   dup 3 1 true shift-lsbs  h# 10000000 <>  if
      ." jtag-instruction failed" cr
      abort
   then
   last-jtag-instruction !

;

\ Switch back to system state from debug state
\ The RESTART takes effect upon entry to run-test/idle state
: jtag-restart  ( -- )  4 jtag-instruction  run-test/idle  ;

: select-scan-chain  ( n -- )
   dup current-scan-chain @ <>  if
      2 jtag-instruction           ( n )  \ SCAN_N instruction
      dup 3 1 true shift-lsbs h# 80000000 <>  if
         ." SCAN_N failed" cr
         " TDI ?" .bad+lcd
         abort
      then
      current-scan-chain !
   else
      drop
   then
   last-jtag-instruction @ h# c <>  if
      h# c jtag-instruction               \ INTEST instruction
   then
;
: idcode  ( -- id )
   h# e jtag-instruction
   -1 shift-32lsbs               \ finish in update-dr-state, as always
;

: ice@  ( reg# -- data )
   2 select-scan-chain        ( reg# )
   5 1 true shift-lsbs drop   ( )      \ The h# 20 bit is 0 for write
   run-test/idle              ( )      \ The data transfer happens here
   0 shift-32lsbs             ( data )

   \ shift-32lsbs shifts in zeros while shifting out the 32 data bits.
   \ The zeros end up in the adr and R/W fields (and some in the data field),
   \ which means the core will execute a " read debug-control register"
   \ instruction at update-dr state.  That is probably innocuous.
;

: ice!  ( data reg# -- )
   2 select-scan-chain                  ( data reg# )
   swap  d# 32 0 true  shift-lsbs drop  ( reg# )  \ Shift in the data value
   h# 20 or  5 1 false shift-lsbs drop  ( )       \ h# 20 is the Write bit
;

decimal
\ adr #bits  (all are RW except as noted)
\  0 (  3 ) constant debug-ctl         \ RO
   1 (  5 ) constant debug-status      \ RO
\  4 (  6 ) constant debug-comms-ctl   \ RO
\  5 ( 32 ) constant debug-comms-data
   8 ( 32 ) constant watchpoint0-adr
   9 ( 32 ) constant watchpoint0-adr-mask
  10 ( 32 ) constant watchpoint0-data
  11 ( 32 ) constant watchpoint0-data-mask
  12 (  9 ) constant watchpoint0-ctl
  13 (  8 ) constant watchpoint0-ctl-mask
\ 16 ( 32 ) constant watchpoint1-adr
\ 17 ( 32 ) constant watchpoint1-adr-mask
\ 18 ( 32 ) constant watchpoint1-data
\ 19 ( 32 ) constant watchpoint1-data-mask
\ 20 (  9 ) constant watchpoint1-ctl
\ 21 (  8 ) constant watchpoint1-ctl-mask

: debug-status@  ( -- )  debug-status ice@  ;
: memory-access-done?  ( -- flag )  debug-status@  9 and  9 =  ;
: wait-memory-access  ( -- )
   d# 10 0  do
      memory-access-done?  if  unloop exit  then
   loop
   1 throw
;
variable #arm-instructions
: setup-stop  ( -- )
    0 watchpoint0-adr ice!
   -1 watchpoint0-adr-mask ice!
    0 watchpoint0-data ice!
   -1 watchpoint0-data-mask ice!
   h# 100 watchpoint0-ctl ice!
   h# fffffff7 watchpoint0-ctl-mask ice!
;
d# 100 value jtag-delay
: stop-core  ( -- )  \ page 12
   setup-stop
   d# 10 0  do 
      debug-status@  1 and  if
         0 watchpoint0-ctl ice!
         reset-to-idle
         #arm-instructions off
         jtag-delay ms
         unloop exit
      then
      d# 10 ms
   loop
   1 throw
;

\ The usual case - clock in a "slow mode" instruction and ignore
\ what was previously on the data bus.
: slow-instruction  ( opcode -- )
   1 select-scan-chain
   false shift-33msbs drop  1 #arm-instructions +!
;

h# e1a0.0000 constant arm-nop
\ h# ffff.ffff constant arm-nop

: nop  ( -- )  arm-nop slow-instruction  ;

: fast-nop  ( -- )
   1 select-scan-chain
   arm-nop true shift-33msbs drop
   1 #arm-instructions +!
;

: arm-register@  ( reg# -- data )  \ Page 13
   \ STR Rn,[R14]
   d# 12 lshift  h# e58e.0000 or slow-instruction  nop  nop
   \ Shift out the data while shifting in data=-1 and breakpt=0
   -1 0 shift-33msbs  ( data )
;
: ?pc-updated  ( flag  -- )  if  #arm-instructions off  nop nop  then  ;
: arm-register!  ( data reg# -- )  \ Page 13
   dup >r
   d# 12 lshift  h# e59e.0000 or slow-instruction  nop  nop  ( data )
   slow-instruction  nop  ( )
   r> d# 15 = ?pc-updated
;

: l@+  ( adr -- adr' l )  dup la1+ swap l@  ;
: l!+  ( value adr -- adr' )  tuck l! la1+  ;
: set-registers  ( adr mask -- )
   dup  h# e89e.0000 or slow-instruction  \ LDMIA R14,{mask}  ( adr mask )
   nop nop       ( adr mask )
   2*            ( adr mask' )
   d# 16 0  do                                    ( adr mask )
      u2/ dup 1 and  if                           ( adr mask' )
         swap l@+ false shift-33msbs drop  swap   ( adr' mask )
      then                                        ( adr mask )
   loop                                           ( adr mask )
   nop  1 and ?pc-updated   ( adr )
   drop
;
: get-registers  ( adr mask -- )
   \ STMIA R14,{mask}
   dup  h# e88e.0000 or  slow-instruction nop nop  ( adr mask )
   d# 16 0  do                             ( adr mask )
      dup h# 8000 and  if                  ( adr mask )
         -1 0 shift-33msbs rot l!+  swap   ( adr' mask' )
      then  2*                             ( adr' mask' )
   loop                                    ( adr mask )
   2drop
;

: set-all-registers  ( adr -- )  h# ffff set-registers  ;
: get-all-registers  ( adr -- )  h# ffff get-registers  ;

: cpsr@  ( -- value )
   0 arm-register@ >r
   h# e10f.0000 slow-instruction  nop nop
   0 arm-register@
   r> 0 arm-register!   
;
: cpsr!  ( value -- )
   0 arm-register@ >r
   0 arm-register!
   h# e12f.f000 slow-instruction  nop nop
   r> 0 arm-register!   
;

: memory-instruction  ( opcode -- )
   nop  fast-nop  ( opcode )  slow-instruction nop
   jtag-restart  wait-memory-access
;
: jtag-mem@  ( adr -- data )
   0 arm-register@  1 arm-register@  2>r  \ Save registers
   0 arm-register!                   ( )       \ Address to R0
   h# e490.1004 memory-instruction   ( )       \ LD R1,[R0],4
   1 arm-register@                   ( data )  \ Get value from register
   2r>  1 arm-register!  0 arm-register!  \ Restore registers
;
: jtag-mem!  ( data adr -- )
   0 arm-register@  1 arm-register@  2>r  \ Save registers
   0 arm-register!  1 arm-register!  ( )       \ Address to R0, data to R1
   h# e480.1004 memory-instruction   ( )       \ ST R1,[R0],4
   2r>  1 arm-register!  0 arm-register!  \ Restore registers
;

d# 14 4 * constant /jtag-chunk
: jtag-out  ( host-adr target-adr len -- )
   swap  d# 14 arm-register!         ( host-adr len )

   begin  /jtag-chunk - dup 0>=  while  ( host-adr len' )
      swap dup h# 3fff set-registers  d# 14 la+  ( len host-adr' )
      h# e8ae.3fff memory-instruction    \ STMIA R14!,{R0..R13}
      swap                              ( host-adr' len )
   repeat                               ( host-adr len )

   /jtag-chunk +  dup  if               ( host-adr len )
      d# 14 arm-register@  swap         ( host-adr target-adr len )
      4 round-up                        ( host-adr target-adr len' )
      0  ?do  over i + @  over i + jtag-mem!  4 +loop  ( hadr tadr )
      2drop                             ( )
   else
      2drop
   then
;

: jtag-in  ( target-adr host-adr len -- )
   rot  d# 14 arm-register!          ( host-adr len )

   begin  /jtag-chunk - dup 0>=  while  ( host-adr len' )
      swap 
      h# e8be.3fff memory-instruction        \ LDMIA R14!,{R0..R13}
      dup h# 3fff get-registers  d# 14 la+
      swap                              ( host-adr' len )
   repeat                               ( host-adr )

   /jtag-chunk +  dup  if               ( host-adr len )
      d# 14 arm-register@  -rot         ( target-adr host-adr len )
      4 round-up                        ( target-adr host-adr len' )
      0  ?do  over i + jtag-mem@  over i + !  4 +loop  ( tadr hadr )
      2drop                             ( )
   else
      2drop
   then
;

: jtag-goto  ( pc -- )
   d# 15 arm-register!
   \ Running these three instructions bumps the PC three
   \ instructions past the address we just loaded, and
   \ arm-register! bumps the PC a few times too.
   nop
   fast-nop
   h# eafffffa slow-instruction   \ BR .-6
   nop nop  \ I'm not entirely sure why these nops are needed,
            \ but empirically they help
   jtag-restart

   run-test/idle  \ Seems to be necessary; don't know why
;

\ Sets PMC_MCKR to CSS_SLOW, PRES(0), thus switching the processor to
\ the slow clock.
: force-slow-clock  ( -- )  0  h# fffffc30 jtag-mem!   ;

h# 200000 constant code-base

: ?idcode  ( code -- )
   h# 3f0f0f0f <>  if
       ." IDCODE mismatch" cr
       " TDO,TCK,TMS?" .bad+lcd
       abort
   then
;

: jtag-init  ( -- )
   jtag-mode
   jtag-reset-on
   rem-power-cycle
   jtag-reset        \ We are now in test-logic-reset state
   d# 100 ms
   \ The IDCODE register is already loaded in the scan chain
   run-test/idle
   -1 shift-32lsbs  ?idcode
   reset-to-idle  \ Get into a well known state and clear all the variables
   jtag-delay ms
;
: jtag-to-mem  ( adr len -- )
   jtag-init
   stop-core
   code-base  swap  jtag-out
   code-base jtag-goto
;

\ d# 16 constant MCLK_MHZ
1 constant frdy
1 constant moscen
1 constant css_main
h# 100 constant pck0
h# 200 constant pck1
h# ffff.fc00 constant pmc_scer
h# ffff.fc20 constant ckgr_mor
h# ffff.fc30 constant pmc_mckr
h# ffff.fc40 constant pmc_pck0

h# ffff.f400 constant pio_per
h# ffff.f404 constant pio_pdr
h# ffff.f408 constant pio_psr
h# ffff.f410 constant pio_oer
h# ffff.f414 constant pio_odr
h# ffff.f418 constant pio_osr
h# ffff.f450 constant pio_mder
h# ffff.f454 constant pio_mddr
h# ffff.f470 constant pio_asr
h# ffff.f474 constant pio_bsr

7 value flash-page-bits
: /flash-page  1 flash-page-bits lshift  ;


h# ffff.ff60 constant mc_fmr  \ Flash mode register
h# ffff.ff64 constant mc_fcr  \ Flash command register
h# ffff.ff68 constant mc_fsr  \ Flash status register
h# ffff.f240 constant dbgu_cidr

d# 45 constant flash_mhz   \ Number of clocks in 1.5 usec

h# 10.0000 constant at91sam7-flash-base

: configure-flash-page  ( -- )
   dbgu_cidr jtag-mem@ 8 rshift h# f and  ( nvsize-field )
   7 >=  if  8  else  7  then  to flash-page-bits
;

: wait-flash-ready  ( -- )  begin  mc_fsr jtag-mem@ frdy and  until  ;
: jtag-flash-page  ( mem-adr flash-adr -- mem-adr' flash-adr' )
   wait-flash-ready             ( mem-adr flash-adr )
   2dup /flash-page  jtag-out   ( mem-adr flash-adr )
   flash_mhz d# 16 <<  0 or  mc_fmr jtag-mem!    ( mem-adr flash-adr )
   dup flash-page-bits rshift                   ( mem-adr flash-adr pagenum )
   8 lshift  h# 5a00.0001 or  mc_fcr jtag-mem!  ( madr fadr )
   swap /flash-page +  swap /flash-page +
;

: .lcd  ( n -- )   push-hex  <# u# u#s u#> line  pop-base  ;

: mem-to-flash  ( mem-adr flash-adr len -- )
   configure-flash-page
   /flash-page round-up  0  ?do   ( mem-adr flash-adr )
      (cr dup .x  jtag-flash-page
   /flash-page +loop
   wait-flash-ready       \ Wait for the last batch to complete
   2drop
;

: start-mclk  ( -- )
   pck0 pck1 or   pmc_scer jtag-mem!
   css_main pmc_pck0 jtag-mem!  \ Feed MCLK to test point for debugging
   h# 40 pio_pdr  jtag-mem!   \ Enable PA6 for the special function PCK0
   h# 40 pio_bsr  jtag-mem!   \ Assign it to the B function
   moscen h# ff00 or  ckgr_mor jtag-mem!  \ Start main oscillator
   \ Probably no need to poll for ready
   d# 10 ms
   css_main pmc_mckr jtag-mem!
;

: (jtag-init-cpu)  ( -- )  jtag-init stop-core  start-mclk  ;
: jtag-init-cpu  ( -- )
   4 0  do
      ['] (jtag-init-cpu) catch  0=  if
         false to bad?  red-off
         unloop exit
      then
      ." Retry" cr
   loop
   disconnect-remote
   true abort" Can't start JTAG"
;

: jtag-to-flash  ( adr len -- )
   " JT JTAG Flashing" .test
   jtag-init-cpu
   at91sam7-flash-base  swap mem-to-flash
   disconnect-remote
;

: jtag-flash-bootloader  ( -- )
   bootloader drop c@  6 <>  if
      " Tester software" .bad+lcd
      ." Bad bootloader image" cr  abort
   then
   bootloader jtag-to-flash
;

h# 1000 constant app-offset
h# 1000 constant /chunk
: jtag-verify  ( adr len flash-offset -- )
   at91sam7-flash-base +  >r    ( adr len r: flash-adr )
   jtag-init-cpu                ( adr len )
   begin  dup 0>  while         ( adr len )
      dup /chunk min            ( adr len this-len )
      r@  load-base  2 pick     ( adr len this-len flash-adr mem-adr this-len )
      jtag-in                   ( adr len this-len )
      2 pick  load-base  2 pick ( adr len this-len mem-adr load-adr this-len )
      comp  if                  ( adr len this-len )
         ." Mismatch" cr  3drop r> drop exit  ( )
      then                      ( adr len this-len )
      rot over + -rot           ( adr' len this-len )
      r> over + >r              ( adr len this-len r: flash-adr' )
      -                         ( adr len' )
   repeat                       ( adr len )
   r> 3drop                     ( )
   ." Match" cr
;
: bv  ( -- )  bootloader 0 jtag-verify  ;
: mv  ( -- )  mfgdiags  app-offset  jtag-verify  ;
: rv  ( -- )  remote    app-offset  jtag-verify  ;
