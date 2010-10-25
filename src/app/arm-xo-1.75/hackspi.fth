: ssp1-clk-on  7 h# d4015050 l!   3 h# d4015050 l!  ;
: select-ssp1-pins  ( -- )
   h# 5003 h# d401e100 l!
   h# 5003 h# d401e104 l!
   h# 5003 h# d401e108 l!
   h# 5003 h# d401e10c l!
;

: init-spi  ( -- )
   select-ssp1-pins
   ssp1-clk-on
   0 h# d4035004 l!      \ Master mode
   h# 87 h# d4035000 l!  \ SPI mode, 8 bits, enabled
;

h# 10 buffer: cmdbuf

0 value bufp
: spi-out  ( n -- )  bufp c!  bufp 1+ to bufp  ;
: spi-cmd  ( n -- )  cmdbuf to bufp  spi-out  ;
: spi-cs-off  ( -- )  cmdbuf bufp over - spi-send-only  ;

: spi-adr  ( offset -- )  lbsplit drop  spi-out spi-out spi-out  ;

: identify-spi-flash  ( -- )
   h# 9f spi-cmd  0 spi-cmd  0 spi-cmd  0 spi-cmd  spi-cs-off
;

: wakeup-spi-flash  ( -- )  h# ab spi-cmd spi-cs-off  ;

: wait-write-done  ( -- )
   \ The Spansion part's datasheet claims that the only operation
   \ that takes longer than 500mS is bulk erase and we don't ever
   \ want to use that command

   d# 100000 0  do  \ 1 second at 10 us/loop
      d# 10 us
      spi-read-status 1 and 0=  if  unloop exit  then  \ Test WIP bit
   loop
   true abort" SPI FLASH write timed out"
;
: wait-write-enable  ( -- )
   \ The Spansion part's datasheet claims that the only operation
   \ that takes longer than 500mS is bulk erase and we don't ever
   \ want to use that command

   d# 500 0  do  \ 1 millisecond at 2 us/loop
      d# 2 us
      spi-read-status 2 and  if  unloop exit  then  \ Test WE bit
   loop
   true abort" SPI FLASH write enable timed out"
;

: spi-write-enable  ( -- )  6 spi-cmd  spi-cs-off  wait-write-enable  d# 20 us  ;
\ : spi-write-disable  ( -- ) 4 spi-cmd  spi-cs-off  short-delay  ;

: stop-writing  ( -- )  spi-cs-off  wait-write-done  ;

: erase-spi-block  ( offset -- )
   spi-write-enable  h# d8 spi-cmd spi-adr  stop-writing
;
: erase-spi-chip  ( -- )  spi-write-enable  h# 60 spi-cmd  stop-writing  ;
: spi-write-status  ( b -- )
   spi-write-enable  1 spi-cmd  ( b ) spi-out  stop-writing
;

\ "0 spi-write-status" turns off write protect bits
: clear-spi-flash-write-protect  ( -- )  wakeup-spi-flash  0 spi-write-status  ;

: write-spi-page  ( adr len offset -- )
   spi-write-enable   ( adr len offset )
   spi-send-page      ( )   
   wait-write-done
;

h#   100 constant /spi-page
h# 10000 constant /spi-block
/spi-page buffer: ff-buf
: dirty?  ( adr -- flag )  ff-buf /spi-page comp  ;
: erase-range  ( offset len -- )
   over 0=  over h# 100000 =  and  if  ( offset len )
      2drop  erase-spi-chip       ( )
   else                           ( offset len )
      begin  dup 0>  while        ( offset len )
         over erase-spi-block     ( offset len )
         /spi-block /string       ( offset' len' )
      repeat                      ( offset len )
      2drop                       ( )
   then
;
: program-range  ( adr len offset -- )
   -rot                                    ( offset adr len )
   bounds ?do                              ( offset )
      i dirty?  if                         ( offset )
         i /spi-page 2 pick write-spi-page ( offset )
      then                                 ( offset )
      /spi-page +                          ( offset' )
   /spi-page +loop                         ( offset )
   drop                                    ( )
;

: check-spi-programmed  ( adr len offset -- )
   h# 100000  2 pick  rot  spi-read   ( adr len )
   h# 100000 swap comp  if  ." Verify failed!!"  cr  then
;
: check-spi-erased  ( len offset -- )
   over >r          ( len offset  r: len )
   h# 100000 -rot   ( adr len offset  r: len )
   spi-read         ( r: len )
   h# 100000 r>  h# ffffffff lcheck dup -1 <>  if  ( adr )
      ." Not erased at address " h# 100000 - . cr
   else                                            ( -1 )
      drop
   then
;
[ifndef] 3dup  : 3dup  2 pick  2 pick  2 pick  ;  [then]
\ Assumes offset is block-aligned
: write-setup-dance  ( -- )
   init-spi
   wakeup-spi-flash
   identify-spi-flash
   d# 40 us
   clear-spi-flash-write-protect   ( adr len offset )
;   
: erase-dance  ( adr len offset -- )
   ff-buf /spi-page h# ff fill
   write-setup-dance
   ." Erasing" cr
   2dup swap erase-range           ( adr len offset )
   2dup check-spi-erased           ( adr len offset )
;
: reflash  ( adr len offset -- )
   erase-dance
   ." Programming" cr
   write-setup-dance
   3dup program-range              ( adr len offset )
   ." Verifying" cr
   check-spi-programmed
;
: reflash0  ( -- )  0 h# 100000 0 reflash  ;
