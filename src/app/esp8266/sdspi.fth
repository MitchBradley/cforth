\ Driver for SD card connected via SPI

defer spi-bits-in   ( #bits -- n )
defer spi-out-in    ( outbuf inbuf #bytes -- )

0 value high-capacity?

\ XXX needs a timeout
\ We must poll the first bit a bit at a time because
\ some microSD cards - notable SanDisk 4G - do not
\ align the R1 start bit to a byte boundary.
: r1  ( -- b )
   #32 0  do  \ Typically takes no more than 11 tries
      1 spi-bits-in 0=  if
         7 spi-bits-in
	 unloop exit
      then
   loop
;

\ Used after cmd has already read the R1 byte
variable rbuf
: read1  ( -- b )  0 rbuf 1 spi-out-in  rbuf c@  ;
: read2  ( -- w )  0 rbuf 2 spi-out-in  rbuf be-w@  ;
: read4  ( -- l )  0 rbuf 4 spi-out-in  rbuf be-l@  ;
: send1  ( b -- )  rbuf c!  rbuf 0 1 spi-out-in  ;

: poly7-xor  ( b -- b' )  dup $80 and  if $89 xor  then  ;
: init-crc7  ( -- )
   #256 0  do
      i poly7-xor                  ( value )
      8 1  do  2* poly7-xor  loop  ( value )
      c,
   loop
;
create crc7table  init-crc7

: crc7  ( adr len -- crc7 )
   0 -rot  bounds  ?do                       ( crc7 )
      2*  i c@ xor  $ff and  crc7table + c@  ( crc7' )
   loop                                      ( crc7 )
;

: +crc1021  ( crc b -- crc' )
   swap wbsplit         ( b crcl crch )
   rot xor $ff and      ( crcl x )
   dup 4 rshift xor >r  ( crcl r: x )
   8 lshift  r@ xor  r@ 5 lshift xor  r> #12 lshift xor
   $ffff and            ( crc' )
;
: crc1021  ( adr len -- crc )
   0 -rot  bounds  ?do  i c@ +crc1021  loop
;


: .sd-error  ( r1 -- )
   dup $40 and  if  ." ParameterError  "  then
   dup $20 and  if  ." AddressError  "  then
   dup $10 and  if  ." EraseSequenceError  "  then
   dup $08 and  if  ." CommandCRCError  "  then
   dup $04 and  if  ." IllegalCommand  "  then
       $02 and  if  ." EraseReset"  then
;
: ?sd-error  ( r1 -- )
   $7e and  ?dup  if  .sd-error  then
;

\ XXX needs a timeout
: wait-not-busy  ( -- )  begin  read1 0<>  until  ;

8 buffer: cmdbuf
4 value #flush
: sd-flush  ( -- )
   cmdbuf 8 $ff fill
   cmdbuf 0 #flush spi-out-in
;
\ The command is 6 bytes but we use an 8-byte buffer
\ All commands have a 0 in the high bit as a "start bit"
\ for the transfer.  We send an initial ff byte, containing
\ no start bit, to ensure that the card sees the start bit
\ in the right place - some cards otherwise get out of sync
\ with the bit stream.
: cmd  ( arg cmd# -- r1 )
   $ff cmdbuf c!
   $40 or cmdbuf 1+  c!  ( arg )
   cmdbuf 2+ be-l!   ( )
   cmdbuf 1+ 5 crc7  2*  1 or  cmdbuf 6 + c!
   cmdbuf 0 7 spi-out-in  r1
;
: cmde  ( arg cmd# -- )  cmd ?sd-error  ;
   
: .data-error  ( n -- )
   dup 8 and  if  ." Out of Range  "  then
   dup 4 and  if  ." ECC Failed  "  then
   dup 2 and  if  ." CC Error  "  then
       1 and  if  ." Unknown Data Error"  then
   cr
;
: wait-data  ( -- error-code )
   begin  read1 dup  $ff =  while  drop  repeat  ( token )
   case
      $fe of  0 exit  endof  ( -- 0 )
        1 of  1 exit  endof  ( -- 1 )
      ( default )  dup .data-error  dup
   endcase                   ( error-code )
; 
false value check-crc?
: get-block  ( adr len -- )
   wait-data  ?dup  if        ( adr len error )
      1 =  if                 ( adr len )
         \ For Unknown Data Error, we fill the buffer with ff's
         \ Some cards seem to return that value for unwritten blocks
         $ff fill
      else                    ( adr len )
         2drop                ( )
      then                    ( )
      exit                    ( -- )
   then                       ( adr len )

   2dup  0 -rot  spi-out-in   ( adr len )
   read2 -rot                 ( crc adr len )
   check-crc?  if             ( crc adr len )
      crc1021 <>  if          ( )
         ." CRC error in get-block" cr
      then
   else                       ( crc adr len )
      3drop                   ( )
   then                       ( )
;

: ?put-data  ( -- )
   read1  dup 5 =  if  drop exit  then  ( token )
   dup $11 and 1 <>  if  ." Bad data response token " .x cr  exit  then  ( token )
   case
      $0b of  ." CRC Error" cr  endof
      $0d of  ." Write Error" cr  endof
      dup  ." Funny error " .x cr
   endcase
;
: put-block  ( adr len token -- )
   send1              ( adr len )
   0 swap spi-out-in  ( adr len )
   ?put-data          ( )
   wait-not-busy      ( )
;

4 buffer: '#wr
#16 buffer: 'cid
#16 buffer: 'csd
#512 value /sd-block
: (sd-reset)  ( -- r1 )  0 0 cmd  ;
: sd-reset  ( -- )
   5 0  do
      (sd-reset) 1 =  if  unloop exit  then
   loop
   true abort" SD Reset failed"
;
: send-op-cond  ( hcs? -- )  0<> $40000000 and  1 cmde  ;  \ CMD1
: send-if-cond  ( arg -- response )  8 cmde  read4  ;  \ CMD8
: send-csd  ( -- )  0 9 cmde  'csd #16 get-block  ;  \ CMD9
: send-cid  ( -- )  0 #10 cmde  'cid #16 get-block  ;  \ CMD10
: stop-transmission  ( -- )  0 #12 cmde  wait-not-busy  ;  \ CMD12
: set-blocklen  ( length -- )  #16 cmde  ;  \ CMD16
: fix-block#  ( block# -- block#|byte# )  high-capacity?  0=  if  /sd-block *  then  ;
: read-single  ( adr len block# -- )
   fix-block#  #17 cmde  get-block  relax
;
: read-multiple  ( adr len block# -- )
   fix-block#  #18 cmde          ( adr len )
   begin  dup 0>  while          ( adr len )
      over /sd-block get-block   ( adr len )
      relax                      ( adr len )
      /sd-block /string          ( adr len )
   repeat                        ( adr len )
   2drop  stop-transmission      ( )
;
: write-single  ( adr len block# -- )  fix-block#  #24 cmde  $fe put-block  relax  ;
: write-multiple  ( adr len block# -- )
   fix-block#  #25 cmde             ( adr len )
   begin  dup 0>  while             ( adr len )
      over /sd-block $fc put-block  ( adr len )
      relax                         ( adr len )
      /sd-block /string             ( adr len )
   repeat                           ( adr len )
   2drop  $fd send1                 ( )
   wait-not-busy
;
: program-csd  ( -- )  0 #27 cmde  ;
: set-write-prot  ( addr -- )  #28 cmde  wait-not-busy  ;
: clr-write-prot  ( addr -- )  #29 cmde  wait-not-busy  ;
: send-write-prot  ( addr -- )   #30 cmde  ;
: erase-wr-blk-start-addr  ( addr )  #32 cmde  ;
: erase-wr-blk-end-addr  ( addr )    ;
: sd-erase  ( block# #blocks -- )
   dup  0=  if  2drop exit  then  ( block# #blocks )
   bounds 1- #33 cmde  #32 cmde   ( )
   0 #38 cmde  wait-not-busy
;
: lock-unlock  ( adr len -- )  0 #42 cmde  put-block  ;
: app-cmd  ( -- )  0 #55 cmde ;
: gen-cmd  ( adr len r/w_ -- )
   dup #56 cmde  if  get-block else  put-block  then
;
: read-ocr  ( -- ocr )  0 #58 cmde  read4  ;  \ CMD58
: crc-on-off  ( 0/1 -- )  #59 cmde  ;
: app-send-status  ( -- )  app-cmd  0 6 cmde read1  ;
: send-status  ( -- extra-status )  app-cmd 0 #13 cmde  read4  ;  \ ACMD13
: send-num-wr-blocks  ( -- #blocks )  app-cmd  0 #22 cmde '#wr 4 get-block  '#wr be-l@  ;
: set-wr-blk-erase-count  ( #blocks -- )  app-cmd  #23 cmde  ;
: sd-send-op-cond  ( hcs? -- r1 )  app-cmd  0<> $40000000 and  #41 cmd  ;
: set-clr-card-detect  ( set? -- )  app-cmd  0<> 1 and  #42 cmde  ;
: send-scr  ( -- )  app-cmd  0 #51 cmde  ;

: sd-consume  ( -- )
   #16 0  do
      read1 $ff =  if  unloop exit  then
   loop
;

: sd-card-init  ( -- )
   sd-consume
   sd-reset
   $1aa send-if-cond $1aa <>  abort" send-if-cond failed"
   begin  true sd-send-op-cond  1 and  0= until
   \ Wait for power-up to complete then check the high-capacity bit
   begin  read-ocr dup $80000000 and 0= while  drop  repeat  ( ocr )
   $40000000 and 0<> to high-capacity?
   high-capacity?  if
      #512
   else
      send-csd
      1  'csd 5 + c@ $f and  lshift
   then
   to /sd-block
;
