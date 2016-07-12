\ STMicro ROM bootloader FLASH programming code

: drain-rx  ( -- )
   begin  serbuf 1 #10 timed-serial-read  1 <> until
;

#2000 value rx-timeout
alias tx serial-put
: rx  ( -- b )
   \ Erase all command can take upto 10s on STM32F4 to get ACK'ed
   serbuf 1  rx-timeout timed-serial-read
   1 <> abort" Serial timeout"
   serbuf c@
;
: stm-wait-ack  ( -- )
   rx dup  $79 =  if  drop exit  then
   dup $1f = abort" Got NACK from serial bootloader"
   ." Bad ACK: " .x  cr  abort
;

: reboot-stm  ( run? -- )  \ Run if run? is true, else download
   \ Run with no parity, but downloading requires even parity
   dup  if  'n'  else  'e'  then  serial-ih set-parity  ( run? )
   dup 0 set-rts-dtr  \ With NRST high (DTR=0), set BOOT0 according to run?
   dup 1 set-rts-dtr  \ Drive NRST low (DTR=1), with BOOT0 according to run?
   0 tx               \ While reset, send NUL to prime the transmitter
   drain-rx           \ While chip is in reset, clear old Rx bytes
   #10 ms             \ Probably unnecessary but harmless
   ( run? ) 0 set-rts-dtr  \ Release NRST with BOOT0 according to run?
;

: stm-run-from-flash  ( -- )  true reboot-stm  ;
: strun  ( -- )  stm-run-from-flash  display  ;

\ Put the chip in serial bootload mode
: stm-setup0  ( -- )  false reboot-stm  ;
\ After stm-setup0, give STM32 time to get into bootloader and be ready to
\ accept commands.  10ms was enough for STM32L152, need atleast 100ms for
\ STM32F4
: stm-start-bootloader  ( -- )  stm-setup0  #100 ms  $7f tx  stm-wait-ack  ;
alias sb stm-start-bootloader

0 value cksum
: sum-tx  ( n -- )  dup cksum xor to cksum  tx  ;
: init-cksum  ( -- )  0 to cksum  ;
: send-cksum  ( -- )  cksum tx  ;

\ Tools for collecting data into a buffer and sending it later.
\ This improves performance when using FTDI libraries that send
\ immediately and thus incur USB frame synchronization delays for
\ every send.
$200 buffer: sum-buf
0 value sum-ptr
: buf{  ( -- )  sum-buf to sum-ptr  ;
: }buf   ( -- )  sum-buf  sum-ptr over -  serial-write stm-wait-ack  ;
: +ptr  ( n -- adr )  sum-ptr tuck  +  to sum-ptr  ;
: +b  ( b -- )  1 +ptr c!  ;
: +$  ( adr len -- )  dup +ptr  swap move  ;

: cksum{  ( -- )  buf{ init-cksum  ;
: }cksum  ( -- )  cksum +b  }buf  ;
: sum+b  ( b -- )  dup cksum xor  to cksum  ( b ) +b  ;

: (stm-send1)  ( b -- )  dup +b  $ff xor +b  ;
: stm-send1  ( b -- )  buf{ (stm-send1) }buf  ;

: (stm-send2)  ( w -- )  wbsplit sum+b sum+b  ;
: (stm-send4)  ( n -- )
   init-cksum lbsplit       ( b.low b.2 b.3 b.high )
   sum+b sum+b sum+b sum+b  ( )
   cksum +b                 ( )
;
: stm-send4  (stm-send4) stm-wait-ack  ;

: stm-version  ( -- version )
   0 stm-send1  rx  rx         ( numbytes version )
   swap  0 ?do  rx drop  loop  ( version )
   stm-wait-ack                ( version )
;
: stm-read-protect-status  ( -- version #disable #enables )
   1 stm-send1  rx rx rx  stm-wait-ack
;
: stm-get-id  ( -- id )
   2 stm-send1  rx rx                 ( n id )
   swap 0  ?do  8 lshift rx or  loop  ( id' )
   stm-wait-ack                       ( )
;
: stm-read-memory  ( adr len offset -- )
   $11 stm-send1                ( adr len offset )
   stm-send4  dup 1- stm-send1  ( adr len )
   serial-read-exact            ( )
;

: stm-go  ( offset -- )  $11 stm-send1  stm-send4  stm-wait-ack  ;
: slow-send-summed  ( adr len n -- )
   init-cksum  sum-tx              ( )
   bounds ?do  i c@ sum-tx  loop   ( )
   send-cksum stm-wait-ack         ( )
;
: stm-slow-write-memory  ( adr len offset -- )
  $31 stm-send1  stm-send4  dup 1- slow-send-summed
;
\needs 3dup : 3dup   2 pick  2 pick  2 pick  ;
: (send-summed)  ( adr len n -- )
   \ n is either len or len-1 depending on the command
   init-cksum  sum+b              ( adr len )  \ Length code goes first
   bounds  ?do  i c@ sum+b  loop  ( )
   cksum +b                       ( )
;
: send-summed  ( adr len n -- )  buf{ (send-summed) }buf  ;
: stm-write-memory  ( adr len offset -- )
   \ We do a tricky thing here for performance sake.  Instead of waiting for
   \ each of the three ACKs individually (after send1, after send4, and after
   \ the data), we group the three writes into one buffer, send it all, then
   \ wait for the three ACKs.  That works because the STM chip has enough buffering
   \ to accept everything at full speed (the send1 and send4 are quite short),
   \ and the three ACKs fit easily in the receive FIFO.  It's a big performance
   \ win because waiting for an individual ACK can take up to 6 ms because of
   \ library, syscall, and USB overhead.  Doing it this way collapses several
   \ 3-to-6 ms delays into one delay, nearly doubling download speed in some cases.

   buf{ $31 (stm-send1)  (stm-send4)  dup 1- (send-summed) }buf
   stm-wait-ack stm-wait-ack 
;

\ The commented-out ones are not supported on the part we use
\ : stm-erase-chip  ( -- )  $43 stm-send1  $ff stm-send1  ;
\ : stm-erase-pages  ( adr len -- )  $43 stm-send1  dup send-summed   ;
\ : stm-erase-bank1  ( -- ) $fffe (stm-extended-erase)  ;
\ : stm-erase-bank2  ( -- ) $fffd (stm-extended-erase)  ;

: (stm-extended-erase)  ( code -- )  $44 stm-send1 cksum{ (stm-send2) }cksum  ;
: stm-erase-all    ( -- ) $ffff (stm-extended-erase)  ;

: stm-erase-page-list  ( adr len -- )
   $44 stm-send1            ( adr len )
   cksum{                   ( adr len )
   dup 2/ 1- (stm-send2)  ( adr len )
   bounds ?do  i w@ (stm-send2) /w +loop   ( )
   }cksum
;
: stm-erase-page  ( page# -- )
   $44 stm-send1  cksum{  0 (stm-send2)  ( page# )  (stm-send2)  }cksum
;
: stm-erase-pages  ( page# #pages -- )
   $44 stm-send1
   cksum{                 ( page# #pages )
   dup 1- (stm-send2)     ( page# #pages )
   bounds ?do  i (stm-send2) loop   ( )
   }cksum
;
$40 constant /erase-chunk
: stm-erase-pages-chunked    ( page# #pages -- )
   dup 0  ?do                ( page# #pages )
      over .x (cr            ( page# #pages )
      2dup /erase-chunk min  ( page# #pages page# this#pages )
      stm-erase-pages        ( page# #pages )
      /erase-chunk /string   ( page#' #pages' )
   /erase-chunk +loop        ( page#' #pages' )
   2drop                     ( )
;

: stm-wp-pages  ( adr len -- )  $63 stm-send1  dup send-summed  ;
: stm-write-unprotect    ( -- )  $73 stm-send1  stm-wait-ack  ;
: stm-readout-protect    ( -- )  $82 stm-send1  stm-wait-ack  ;
\ This will clear the FLASH if it is current protected
: stm-readout-unprotect  ( -- )  $92 stm-send1  stm-wait-ack  ;

defer show-phase  ( adr len -- )
: text-show-phase  ( adr len -- )  type cr  ;
' text-show-phase to show-phase

defer set-progress-range  ( high low -- )
: text-set-range  ( high low -- )  2drop  ;
' text-set-range to set-progress-range

defer show-progress
: text-show-progress  ( n -- )  .x (cr  ;
' text-show-progress to show-progress

: stm-write  ( adr len offset -- )
   begin  over  while     ( adr len offset )
      dup show-progress   ( adr len offset )
      3dup  swap $100 min ( adr len offset  adr offset this )
      tuck >r             ( adr len offset  adr offset this  r: this )
      stm-write-memory    ( adr len offset  r: this )
      r@ +  -rot          ( offset' adr len  r: this )
      r> /string rot      ( adr' len' offset' )
   repeat	          ( adr len offset )
   3drop                  ( )
   cr
;
: stm-read  ( adr len offset -- )
   begin  over  while     ( adr len offset )
      3dup  dup .x (cr    ( adr len offset  adr len offset )
      swap $100 min       ( adr len offset  adr offset this )
      tuck >r             ( adr len offset  adr offset this  r: this )
      stm-read-memory     ( adr len offset  r: this )
      r@ +  -rot          ( offset' adr len  r: this )
      r> /string rot      ( adr' len' offset' )
   repeat	          ( adr len offset )
   3drop                  ( )
   cr
;
\ offset is typically $08000000 for the start of FLASH

$100 constant /flash-page
$08000000 constant flash-base

$08080000 constant data-eeprom-base

$49534843 constant chooser-magic \ CHSI
data-eeprom-base $000 + constant chooser-spec
flash-base     $00000 + constant chooser-base
$02000 constant /chooser

$4952444c constant loader-magic  \ LDRI
data-eeprom-base $0c0 + constant loader-spec
flash-base     $02000 + constant loader-base
$06000 constant /loader

$494d5453 constant stmapp-magic  \ STMI
data-eeprom-base $180 + constant stmapp-spec
flash-base     $08000 + constant stmapp-base
$30000 constant /stmapp

$494d4342 constant bcmapp-magic  \ BCMI
data-eeprom-base $240 + constant bcmapp-spec
flash-base     $38000 + constant bcmapp-base
$08000 constant /bcmapp

create one 1 ,
: flash-spec-file  ( name$ spec-adr -- )
   >r  open-bin-file                     ( r: spec-adr )
   bin-file-buf /bin-file r@  stm-write  ( r: spec-adr )
   one /l  r> #24 +  stm-write           ( )
;

: (chooser-spec)  ( -- )  " chooser.spec" chooser-spec flash-spec-file  ;
: (loader-spec)   ( -- )  " loader.spec"  loader-spec  flash-spec-file  ;
: (stmapp-spec)   ( -- )  " stmapp.spec"  stmapp-spec  flash-spec-file  ;
: (bcmapp-spec)   ( -- )  " bcmapp.spec"  bcmapp-spec  flash-spec-file  ;

$c0 constant /spec
/spec buffer: spec
: +spec  ( offset -- adr )  spec +  ;
: spec-l!  ( offset -- )  +spec le-l!  ;
$40000 buffer: sha-buf
: make-spec  ( version developer name$ magic baseaddr len -- )
   >r                         ( version developer name$ magic baseaddr r: len )
   spec /spec erase           ( version developer name$ magic baseaddr )
   4 spec-l!                  ( version developer name$ magic )
   0 spec-l!                  ( version developer name$ )
   2swap #14 +spec le-w!      ( name$ version )
   #12 +spec le-w!            ( name$ )
   2dup file-date #16 spec-l! ( name$ )
   open-bin-file              ( )
   /bin-file 8 spec-l!        ( )   \ size
   1 #24 spec-l!              ( )   \ state = IMAGE_DOWNLOADED
   sha-buf r@ erase           ( )
   bin-file-buf sha-buf /bin-file move   ( )
   #32 +spec  sha-buf r> sha256          ( )
;
: write-spec  ( version developer name$ magic baseaddr len spec-adr -- )
   >r  make-spec  ( r: spec-adr )
   spec /spec r>  stm-write
;

: flash-section  ( flash-adr size name$ -- )
   open-bin-file                          ( flash-adr size )

   " Erasing ... "  show-phase            ( flash-adr size )
   over /flash-page /                     ( flash-adr size page# )
   swap /flash-page 1- +  /flash-page /   ( flash-adr page# #pages )
   stm-erase-pages-chunked                ( flash-adr )

   bin-file-buf                           ( flash-adr adr )
   /bin-file  /flash-page round-up        ( flash-adr adr len )
   rot  stm-write                         ( )
;

: spec-common  ( -- version developer name$ -- )
   \ XXX need some way to set the developer initials, preferably automatic
   0 'mb' bin-filename$
;
: (chooser)  ( -- )
   chooser-base /chooser  " chooser.bin" flash-section
\  spec-common chooser-magic chooser-base /chooser chooser-spec write-spec
;
: chooser  ( -- )  stm-start-bootloader  (chooser) (chooser-spec) ;

: (loader)  ( -- )
   loader-base /loader  " loader.bin" flash-section
\  spec-common loader-magic loader-base /loader loader-spec write-spec
;
: loader  ( -- )  stm-start-bootloader  (loader) (loader-spec)  ;

: (stmapp)  ( -- )
   stmapp-base /stmapp  " stmapp.bin" flash-section
\   spec-common stmapp-magic stmapp-base /stmapp stmapp-spec write-spec
;
: stmapp  ( -- )  stm-start-bootloader  (stmapp) (stmapp-spec)  ;

: (bcmapp)  ( -- )
   bcmapp-base /bcmapp  " bcmapp.bin" flash-section
\   spec-common bcmapp-magic bcmapp-base /bcmapp bcmapp-spec write-spec
;
: bcmapp  ( -- )  stm-start-bootloader  (bcmapp) (bcmapp-spec)  ;

alias (bcmfw) (bcmapp)
alias bcmfw bcmapp

create bspin-page-sizes
  $4000 , $4000 , $4000 , $4000 , $10000 , $20000 , $20000 , $20000 ,
8 constant bspin-#pages

: bspin-erased  ( i -- n )
   0  swap 1+  0  ?do  bspin-page-sizes i na+ @  +  loop 
;
: bspin-erase  ( size -- )
   0 set-progress-range
   bspin-#pages 0  do
      i stm-erase-page
      i bspin-erased show-progress
   loop
;

: bspin-flash-section  ( flash-adr size -- )
   " Erasing ... "  show-phase            ( flash-adr )
   bspin-erase                            ( flash-adr )

   " Programming ... " show-phase         ( flash-adr )
   bin-file-buf                           ( flash-adr adr )
   /bin-file  /flash-page round-up        ( flash-adr adr len )
   2 pick over bounds  set-progress-range ( flash-adr adr len )
   rot  stm-write                         ( )

   " Complete" show-phase                 ( )
;

: connect-to-backspin  ( -- )
   #10000 to rx-timeout
   " Connecting ... " show-phase
   stm-start-bootloader
;

: flash-backspin  ( -- )
   connect-to-backspin
   flash-base $80000 bspin-flash-section
;

: bspin ( -- )
   " backspin.bin" open-bin-file
   flash-backspin
   stm-run-from-flash
   display
;

: (allapps)  ( -- )
   stm-start-bootloader
   (chooser)  (loader)  (stmapp) (bcmapp)
   \ If we don't want to inject the specs from files comment this out and
   \ and enable write-spec for each app
   (chooser-spec) (loader-spec)  (stmapp-spec)  (bcmapp-spec)
;
: allapps  ( -- )
   (allapps)
   stm-run-from-flash
   display
;

: (stapp)
   " stapp.bin" arg-or-default open-bin-file
   /bin-file /flash-page 1- +  /flash-page /  ( #pages )
   ." Erasing ... "  cr
   0 swap stm-erase-pages-chunked  ." done" cr        ( )
   bin-file-buf /bin-file  /flash-page round-up  flash-base  stm-write
;
: stmapp-only  ( -- )
   stm-start-bootloader
   (stmapp)
   stm-run-from-flash
   display
;
: bcmapp-only  ( -- )
   stm-start-bootloader
   (bcmapp)
   stm-run-from-flash
   display
;

: old-stapp  ( -- )
   stm-start-bootloader
   (stapp) (bcmfw)
   stm-run-from-flash
   display
;
: stapp  ( -- )
   ." Running allapps instead; for old behavior use old-stapp" cr
   allapps
;

$20000 constant /this-flash
: stread  ( "filename" -- )
   safe-parse-word  w/o create-file abort" Can't create file" to bin-file
   ?alloc-flash-buf
   stm-start-bootloader
   bin-file-buf /this-flash flash-base stm-read
   bin-file-buf /this-flash bin-file write-file  ( ior )
   bin-file close-file drop  abort" Write failed"
;

0 value target-revision#

: ?get-hardware-version  ( adr len -- )
   -crlf                                                   ( adr len )
   " Hardware version = "  2over  initial-substring?  if   ( adr len )
      #19 /string  push-decimal  $number?  pop-base   if   ( d )
         drop to target-revision#                          ( )
         exit                                              ( -- )
      then                                                 ( adr len )
   else                                                    ( adr len )
      2drop                                                ( )
   then                                                    ( )
;
