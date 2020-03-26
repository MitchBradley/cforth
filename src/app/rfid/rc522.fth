\ Driver for RC522 RFID reader

\ Uses HSPI pins:
\ 5 SCK
\ 6 MISO
\ 7 MOSI
\ 8 CS
\ plus
\ 0 nRST

0 constant rc522-nrst-pin
: rc522-hard-reset  ( -- )
  0 rc522-nrst-pin gpio-pin!
  #100 ms
  1 rc522-nrst-pin gpio-pin!
  #100 ms
;
: rc522-gpio-init  ( -- )
  0 true #2000000 -1 spi-open
  0 gpio-output rc522-nrst-pin gpio-mode
  rc522-hard-reset
;

$c constant rc522-transceive

#18 buffer: rc522-buf
: +buf  ( offset -- adr )  rc522-buf +  ;
: buf!  ( b offset -- )  +buf c!  ;
: buf@  ( offset -- b )  +buf c@  ;
#10 buffer: inbuf
#10 buffer: outbuf
: rc522-reg@  ( reg@ -- data )
   2* $80 or outbuf c!
   0 outbuf 1+ c!
   outbuf inbuf 2 spi-transfer
   inbuf 1+ c@
;
: rc522-reg!  ( data reg@ -- )
   2* outbuf c!  ( data )
   outbuf 1+ c!  ( )
   outbuf inbuf 2 spi-transfer
;
: rc522-clear  ( mask reg -- )  >r invert  r@ rc522-reg@ and  r> rc522-reg!  ;
: rc522-set    ( mask reg -- )  >r r@ rc522-reg@ or  r> rc522-reg!  ;

: cnt@  ( -- n )
   $2f 2* $80 or outbuf c!
   $2e 2* $80 or outbuf 1+ c!
   outbuf inbuf 3 spi-transfer
   inbuf 1+ c@  inbuf 2+ c@ 4 lshift or
;
: rc522-command!  ( b -- )  $1 rc522-reg!  ;
: rc522-ien@  ( -- b )  $2 rc522-reg@  ;
: rc522-ien!  ( b -- )  $2 rc522-reg!  ;
: rc522-irq@  ( -- b )  $4 rc522-reg@  ;
: rc522-error@  ( -- b )  $6 rc522-reg@  ;
: rc522-control@  ( -- b )  $c rc522-reg@  ;
: rc522-fifo@  ( -- b )  9 rc522-reg@  ;
: rc522-fifo!  ( b -- )  9 rc522-reg!  ;
: rc522-fifo-level@  ( -- b )  $a rc522-reg@  ;
: rc522-fifo-level!  ( b -- )  $a rc522-reg!  ;
: rc522-fifo-flush   ( -- )  $80 $a rc522-set  ;
: rc522-antenna-off  ( -- )  3 $14 rc522-clear  ;
: rc522-antenna-on  ( -- )  3 $14 rc522-set  ;
0 value cmd
0 value waitfor

: rc522-command  ( #in cmd -- #bits )  \ #bits is negative on error
   to cmd
   cmd case
      $e of  $11 $12  endof  \ Authent
      rc522-transceive of  $31 $77  endof  \ Transceive
      ( default )  0 1  rot
   endcase  ( waitfor irqen )
   $80 or rc522-ien!  ( waitfor )
   to waitfor
   $80 4 rc522-clear  \ Clear interrupt bits
   rc522-fifo-flush
   0 rc522-command!   \ IDLE
   ( #in )
   rc522-buf swap bounds ?do  i c@ rc522-fifo!  loop  ( )
   cmd rc522-command!   \ Execute the command
   cmd rc522-transceive =  if  $80 $d rc522-set  then  \ StartSend in BitFramingReg
   
   true  #30 0  do   ( timeout? )
      1 ms
      rc522-irq@ waitfor and  if  0= leave  then  \ Condition satisfied
   loop   ( timeout? )
   $80 $d rc522-clear  \ StartSend in BitFramingReg  ( timeout? )
   if  -1 exit  then   ( )
   rc522-error@ dup $11 and  if  drop -2 exit  then  ( status )
   8 and  if  -3 exit  then  ( )  \ COLLISION

   rc522-irq@ rc522-ien@ and 1 and  if  -4 exit  then  \ Notag  ( )
   cmd rc522-transceive =  if   ( )  \ Transceive
      rc522-fifo-level@      ( fifo-bytes )
      rc522-control@ 7 and   ( fifo-bytes lastbits )
      rc522-buf  2 pick  bounds ?do   ( fifo-bytes lastbits )
         rc522-fifo@ i c!    ( fifo-bytes lastbits )
      loop                   ( fifo-bytes lastbits )
      swap 8 * swap          ( fifo-bits lastbits )
      ?dup  if  + 8 -  then  ( #bits )
   else                      ( )
      0                      ( #bits )
   then                      ( #bits )
;

: rc522-reset  ( -- )
   $f 2 rc522-reg!  \ RESETPHASE
   #10 ms
   rc522-antenna-off
   #10 ms
   $8d $2a rc522-reg!  \ TMode: Tauto=1, f(Timer) = 6.78MHz/TPreScaler
   $3e $2b rc522-reg!  \ TPrescalerReg: Prescaler low bits
   $e8 $2d rc522-reg!  \ TReloadRegLo: Timer reload
   #03 $2c rc522-reg!  \ TReloadRegHi: Timer reload
   $40 $15 rc522-reg!  \ TxASKReg: Force ASK Modulation
   $3d $11 rc522-reg!  \ ModeReg: WaitRF, CRCPreset=$6363
\   $84 $18 rc522-reg!  \ RxThresholdReg: min 8 collision 4
\   $68 $26 rc522-reg!  \ RFCfgReg: Gain 43 dB
\   $ff $27 rc522-reg!  \ GsNreg: high power
\   $2f $28 rc522-reg!  \ CWGsCfgReg: fairly high power
   rc522-antenna-on

;
: rc522-soft-reset  ( -- )  $f rc522-command!  ;
: rc522-crc  ( 'out len -- )
   4 5 rc522-clear    \ Clear CRCIrq   
   0 rc522-command!   \ IDLE
   rc522-fifo-flush   ( 'out len )
   rc522-buf swap bounds ?do  i c@ rc522-fifo!  loop  ( 'out )
   3 rc522-command!   ( 'out )    \ CALC_CRC  
   $ff 0  do          ( 'out )
      5 rc522-reg@  4  and  ?leave  ( 'out )
   loop                      ( 'out )
   $22 rc522-reg@ over c!    ( 'out )  \ CRC low
   $21 rc522-reg@ swap 1+ c! ( )       \ CRC high
;
: append-crc  ( adr len -- #bits )
   tuck rc522-buf swap move           ( len )
   dup +buf over  rc522-crc    ( )
;
: rc522-halt  ( -- error | #bits 0 )
   " "(50 00)" append-crc
   4 rc522-transceive rc522-command  ( #bits ) 
;
\needs le-w@ : le-w@  ( adr -- w )  dup c@  swap 1+ c@  4 shift or  ;
: rc522-framing!  ( n -- )   $d rc522-reg!  ;
: rc522-request  ( req-code -- tag-type | error )
   7 rc522-framing!      ( req-code )  \ Framing: 7 bits in last byte
   0 buf! ( )
   1 rc522-transceive rc522-command  ( #bits | error )
   dup $10 = if              ( #bits )
      drop rc522-buf le-w@   ( tag-type )
   then                      ( tag-type | error )
;
4 buffer: snr-buf
: snr-check  ( -- b )  0  snr-buf 4 bounds  do  i c@ xor  loop  ;
: rc522-anti-collision  ( cascade -- snr | error )
   0 rc522-framing!  ( cascade )   
   0 0               ( cascade #collbits index )
   #32 0  do         ( cascade #collbits index )
      2 pick 0 buf!  swap $20 or 1 buf!  ( cascade index )
      2 + rc522-transceive  rc522-command  ( cascade #bits )
      -3 =  if    ( cascade )
         $e rc522-reg@                 ( cascade #collbits )
         ?dup  0=  if  #32  then       ( cascade #collbits )
         dup 1- 8 /  1 +               ( cascade #collbits index )
         over 1- 7 and  1 swap lshift  ( cascade #collbits index mask )
         over buf@  or  over buf!      ( cascade #collbits index )
         0 +buf  2 +buf  4 move      ( cascade #collbits index )
         over 7 and rc522-framing!     ( cascade #collbits index )
      else                             ( cascade )
         drop                          ( )
         0 +buf  snr-buf  4  move      ( )
         snr-check  4 buf@ <>  unloop  exit  ( -- error? )
      then
   loop         ( cascade #collbits index )
   3drop -3     ( error )
;
: rc522-select  ( cascade -- )
   0 buf!  $70 1 buf!          ( )
   snr-buf  2 +buf  4  move    ( )
   snr-check  6 buf!           ( )
   7 +buf  7 rc522-crc
   $8 $8 rc522-clear  \ Crypto off
   9 rc522-transceive rc522-command   ( #bits | error )
;
: rc522-auth-state  ( 'key addr auth-mode -- )
   0 buf!  1 buf!          ( 'key )
   2 +buf 6 move           ( )
   snr-buf  8 +buf 4 move  ( ) 
   #12 $a rc522-command    ( #bits | error )
   8 rc522-reg@ 8 and  if  drop -1  exit  then  ( #bits | error )
;
2 buffer: crc-buf
: rc522-rwsetup  ( addr -- error? )
   $30 0 buf!   ( addr )  \ PICC_READ
   1 buf!       ( )
   2 +buf  2 rc522-crc
   4 rc522-transceive rc522-command  ( #bits | error )
;
: rc522-read  ( addr -- 'data | -1 )
   $30 rc522-rwsetup  ( #bits | -error )
   dup 0<  if  exit  then            ( #bits )
   drop                              ( )
   crc-buf #16 rc522-crc
   crc-buf c@  #16 buf@  =  crc-buf 1+ c@  #17 buf@ =  and  if
      rc522-buf
   else
      -1
   then
;
: rc522-write  ( adr addr -- error? )
   $a0 rc522-rwsetup  ( adr #bits | -error )
   dup 0<  if  nip exit  then   ( adr #bits )
   4 <>  if  drop -1 exit  then  ( adr )
   0 buf@ $f and $a <>  if  drop -6 exit  then  ( adr )
   #16 append-crc  ( )
   #18 rc522-transceive rc522-command  ( #bits | error )      
   dup 0<  if  exit  then   ( #bits )
   4 <>  if  -7 exit  then  ( )
   0 buf@ $f and $a <>  if  drop -8 exit  then  ( )
   0
;
: r rc522-reg@ . ;
alias w rc522-reg!

: find-tag  ( -- card-type )  $26 rc522-request  ;
: select-step  ( phase -- error? )
   dup rc522-anti-collision  ( phase error )
   dup 0<  if  nip exit  then  drop  ( phase )
   rc522-select              ( error )
;
: select-tag-sn  ( 'sn -- 'sn len )
   $93 select-step   ( 'sn error? )  \ PICC_ANTICOLL1
   dup 0<  if  exit  then  drop        ( 'sn )
   snr-buf c@ $88 <>  if               ( 'sn )
      snr-buf over 4 move              ( 'sn )
      4                                ( 'sn 4 )
   else                                ( 'sn )
      snr-buf 1+  over 3 move          ( 'sn )      
      $95 select-step  \ ANTICOLL2     ( 'sn error )
      dup 0<  if  exit  then  drop     ( 'sn )
      snr-buf c@ $88 <>  if            ( 'sn )
         snr-buf over 3 +  4 move      ( 'sn )
         7                             ( 'sn 7 )
      else                             ( 'sn )
         snr-buf 1+  over 3 +  3 move  ( 'sn )      
         $97 select-step \ ANTICOLL3   ( 'sn error )
         dup 0<  if  exit  then  drop  ( 'sn )
         snr-buf over 6 +  4 move      ( 'sn )
         #10                           ( 'sn 10 )
      then                             ( sn #bytes )
   then                                ( sn #bytes )
;

: init-rc522  ( -- )  rc522-gpio-init  rc522-reset  ;

#10 buffer: tag-sn
\ The result is an array of 4, 7 or 10 binary bytes
: get-rfid-tag  ( -- false | adr len true )
   find-tag 0<  if  false exit  then
   tag-sn select-tag-sn    ( adr len )
   dup 0<  if  2drop false exit  then
   true
;
0 [if]
: .tag  ( -- adr len )
   begin  get-rfid-tag  0=  while  key? abort" Aborted"  #20 ms  repeat
   cdump
;
[then]
