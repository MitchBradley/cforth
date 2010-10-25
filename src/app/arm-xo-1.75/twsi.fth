purpose: Driver for Two Wire Serial Interface on Marvell Armada 610

\ 0 0  " d4011000"  " /" begin-package

0 value chip
0 value clock-reg
0 value slave-address

: dbr@  ( -- n )  chip h# 08 + l@   ;
: cr@   ( -- n )  chip h# 10 + l@   ;
: sr@   ( -- n )  chip h# 18 + l@   ;
: sar@  ( -- n )  chip h# 20 + l@   ;
: lcr@  ( -- n )  chip h# 28 + l@   ;
: dbr!  ( n -- )  chip h# 08 + l!   ;
: cr!   ( n -- )  chip h# 10 + l!   ;
: sr!   ( n -- )  chip h# 18 + l!   ;
: sar!  ( n -- )  chip h# 20 + l!   ;
: lcr!  ( n -- )  chip h# 28 + l!   ;

create channel-bases
h# D4011000 ,  h# D4031000 ,  h# D4032000 ,  h# D4033000 ,  h# D4033800 ,  h# D4034000 ,

create clock-offsets
h# 04 c,  h# 08 c,  h# 0c c,  h# 10 c,  h# 7c c,  h# 80 c,

: set-twsi-channel  ( channel -- )
   1-
   channel-bases over na+ @  to chip  ( channel )
   clock-offsets + c@  clock-unit-pa +  to clock-reg  ( )
;
: set-twsi-target  ( slave channel -- )  \ Channel numbers range from 1 to 6
   set-twsi-channel
   to slave-address
;

\       Bit defines

h# 4000 constant bbu_ICR_UR                \ Unit Reset bit
h# 0040 constant bbu_ICR_IUE               \ ICR TWSI Unit enable bit
h# 0020 constant bbu_ICR_SCLE              \ ICR TWSI SCL Enable bit
h# 0010 constant bbu_ICR_MA                \ ICR Master Abort bit
h# 0008 constant bbu_ICR_TB                \ ICR Transfer Byte bit
h# 0004 constant bbu_ICR_ACKNAK            \ ICR ACK bit
h# 0002 constant bbu_ICR_STOP              \ ICR STOP bit
h# 0001 constant bbu_ICR_START             \ ICR START bit
h# 0040 constant bbu_ISR_ITE               \ ISR Transmit empty bit
h# 0400 constant bbu_ISR_BED               \ Bus Error Detect bit

h# 1000 constant BBU_TWSI_TimeOut          \ TWSI bus timeout loop counter value

bbu_ICR_IUE bbu_ICR_SCLE or constant iue+scle
: init-twsi-channel  ( channel# -- )
   set-twsi-channel
   7 clock-reg l!  3 clock-reg l!  \ Set then clear reset bit
   1 us
   iue+scle  bbu_ICR_UR or  cr!  \ Reset the unit
   iue+scle cr!                  \ Release the reset
   0 sar!                        \ Set host slave address
   0 cr!                         \ Disable interrupts
;
: init-twsi  ( -- )
   7 1  do  i init-twsi-channel  loop
;

: twsi-run  ( extra-flags -- )
   iue+scle or  bbu_ICR_TB or  cr!    ( )

   h# 1000  0  do
      cr@ bbu_ICR_TB and 0=  if   unloop exit  then
   loop
   true abort" TWSI timeout"
;
: twsi-putbyte  ( byte extra-flags -- )
   swap dbr!      ( extra-flags )
   twsi-run
;
: twsi-getbyte  ( extra-flags -- byte )
   twsi-run  ( )
   dbr@      ( byte )
   sr@ sr!   ( byte )
;

: twsi-start  ( slave-address -- )
   bbu_ICR_START  twsi-putbyte        ( )
   sr@  bbu_ISR_BED and  if           ( )
      bbu_ISR_BED sr!                 ( )
      iue+scle bbu_ICR_MA or  cr!     ( )
      true abort" TWSI bus error"
   then                               ( )
;

: twsi-get  ( register-address .. #reg-bytes #data-bytes -- data-byte ... )
   >r                    ( reg-adr .. #regs  r: #data-bytes )
   \ Handle the case where the device does not require that a write register address be sent
   slave-address         ( reg-adr .. #regs slave-address  r: #data-bytes )
   over 0=  if           ( reg-adr .. #regs slave-address  r: #data-bytes )
      r@  if             ( reg-adr .. #regs slave-address  r: #data-bytes )
         1 or            ( reg-adr .. #regs slave-address' r: #data-bytes )
      then               ( reg-adr .. #regs slave-address' r: #data-bytes )
   then                  ( reg-adr .. #regs slave-address' r: #data-bytes )

   twsi-start            ( reg-adr .. #regs  r: #data-bytes )

   \ Abort the transaction if both #reg-bytes and #data-bytes are 0
   dup r@ or  0=  if                  ( #regs  r: #data-bytes )
      iue+scle bbu_ICR_MA or  cr!     ( #regs  r: #data-bytes )  \ Master abort
      r> 2drop exit                   ( -- )
   then                               ( reg-adr .. #regs  r: #data-bytes )

   \ Send register addresses, if any
   0  ?do  0 twsi-putbyte  loop       ( r: #data-bytes )

   \ If no result data requested, quit now
   r>  dup 0=  if                     ( #data-bytes )
      drop                            ( )
      iue+scle bbu_ICR_STOP or  cr!   ( )
      exit
   then                               ( #data-bytes )

   \ Otherwise send the read address with another start bit
   slave-address 1 or  bbu_ICR_START twsi-putbyte     ( #data-bytes )   
   sr@ sr!    \ clear ITE and IRF status bits         ( #data-bytes )
   \ Bug on line 367 of bbu_TWSI.s - writes SR without first reading it

   1-  0  ?do  0 twsi-getbyte   loop  ( bytes )

   \ Set the stop bit on the final byte
   bbu_ICR_STOP  bbu_ICR_ACKNAK or twsi-getbyte   ( bytes )
;

: twsi-write  ( byte .. #bytes -- )
   slave-address twsi-start           ( byte .. #bytes )

   1-  0  ?do  0 twsi-putbyte  loop   ( byte )
   bbu_ICR_STOP twsi-putbyte          ( )
;

: twsi-b@  ( reg -- byte )  1 1 twsi-get  ;
: twsi-b!  ( byte reg -- )  2 twsi-write  ;
