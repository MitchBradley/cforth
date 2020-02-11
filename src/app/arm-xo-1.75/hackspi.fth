: ssp1-clk-on  7 h# 015050 io!   3 h# 015050 io!  ;
: select-ssp1-pins  ( -- )
   h# 5003 h# 01e100 io!
   h# 5003 h# 01e104 io!
   h# 5003 h# 01e108 io!
   spi-flash-cs-gpio# gpio-set
   spi-flash-cs-gpio# gpio-dir-out
   h# c0 h# 01e10c io!
;

: init-spi  ( -- )
   select-ssp1-pins
   ssp1-clk-on
   0 h# 035004 io!      \ Master mode
   h# 87 h# 035000 io!  \ SPI mode, 8 bits, enabled
;

h# 10 buffer: spi-cmdbuf

: [[ spi-flash-cs-gpio# gpio-clr  ;
: ]] spi-flash-cs-gpio# gpio-set  ;

0 value bufp
: spi-out  ( n -- )  bufp c!  bufp 1+ to bufp  ;
: spi-cmd  ( n -- )  spi-cmdbuf to bufp  spi-out  ;
: spi-cs-off  ( -- )  spi-cmdbuf bufp over - [[ spi-send-only ]]  ;

: spi-adr  ( offset -- )  lbsplit drop  spi-out spi-out spi-out  ;

\ Programmed I/O versions
: cs0  spi-flash-cs-gpio# gpio-clr ;
: cs1  spi-flash-cs-gpio# gpio-set ;
: pio-mode  spi-flash-cs-gpio# gpio-set  spi-flash-cs-gpio# gpio-dir-out  h# c0 spi-flash-cs-gpio# af!  ;
: ssp-mode  h# 5003 spi-flash-cs-gpio# af!  ;
: g  begin 035008 io@ 8 and until  035010 io@  ;
: p  035010 io! ;
: p0 0 035010 io! ;
: slow-spi-read  ( adr len offset -- )
   pio-mode
   cs0
      3 p
      dup d# 16 rshift h# ff and p
      dup 8 rshift ff and p
      ff and p
      g drop g drop g drop g drop
      bounds ?do  p0 g i c!  loop
   cs1
;
: flush-ssp  ( -- )
   begin 035008 io@ 8 and  while  035010 io@ drop  repeat 
;
: .spi-id  ( -- )
   flush-ssp
   cs0
   h# 9f p  g drop
\   ." ID: " p0 g .  p0 g .  p0 g .  cr
   p0 g drop  p0 g drop  p0 g drop
   cs1
;

: identify-spi-flash  ( -- )
   h# 9f spi-cmd  0 spi-cmd  0 spi-cmd  0 spi-cmd  spi-cs-off
;

: wakeup-spi-flash  ( -- )
   h# ab spi-cmd 0 spi-out 0 spi-out 0 spi-out  0 spi-out  spi-cs-off
;

: wait-write-done  ( -- )
   \ The Spansion part's datasheet claims that the only operation
   \ that takes longer than 500mS is bulk erase and we don't ever
   \ want to use that command

   d# 100000 0  do  \ 1 second at 10 us/loop
      [[ spi-read-status ]]  1 and 0=  if  unloop exit  then  \ Test WIP bit
      d# 10 us
   loop
   true abort" SPI FLASH write timed out"
;
: wait-write-enable  ( -- )
   \ The Spansion part's datasheet claims that the only operation
   \ that takes longer than 500mS is bulk erase and we don't ever
   \ want to use that command

   d# 500 0  do  \ 1 millisecond at 2 us/loop
      d# 2 us
      [[ spi-read-status ]]  2 and  if  unloop exit  then  \ Test WE bit
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
: spi-protect  ( -- )  h# 9c spi-write-status  ;
: spi-unprotect  ( -- )  h# 0 spi-write-status  ;
: spi-protected?  ( -- flag )
   [[ spi-read-status ]] h# 80 and if
      [[ spi-read-status ]]                     ( status )
      spi-unprotect                             ( status )
      [[ spi-read-status ]] h# 80 and if        ( status )
         drop true exit                         ( status )
      then                                      ( status )
      spi-write-status
   then
   false
;

: write-spi-page  ( adr len offset -- )
   spi-write-enable     ( adr len offset )
   [[ spi-send-page ]]  ( )   
   wait-write-done
;

h#   100 constant /spi-page
h# 10000 constant /spi-block
/spi-page buffer: ff-buf
: dirty?  ( adr -- flag )  ff-buf /spi-page comp  ;
: erase-range  ( len offset -- )
   swap                           ( offset len )
   over 0=  over /rom =  and  if  ( offset len )
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
   ff-buf /spi-page h# ff fill             ( offset adr len )

   -rot                                    ( offset adr len )
   bounds ?do                              ( offset )
      i dirty?  if                         ( offset )
         i /spi-page 2 pick write-spi-page ( offset )
      then                                 ( offset )
      /spi-page +                          ( offset' )
   /spi-page +loop                         ( offset )
   drop                                    ( )
;

h# 1010.0000 constant spi-mem-base
: check-spi-programmed  ( adr len offset -- )
   spi-mem-base  2 pick  rot  spi-read   ( adr len )
   spi-mem-base swap comp  if  ." Verify failed!!"  cr  then
;
: check-spi-erased  ( len offset -- )
   over >r             ( len offset  r: len )
   spi-mem-base -rot   ( adr len offset  r: len )
   spi-read            ( r: len )
   spi-mem-base r>  h# ffffffff lcheck dup -1 <>  if  ( adr )
      ." Not erased at address " spi-mem-base - . cr
      abort
   else                                            ( -1 )
      drop
   then
;
[ifndef] 3dup  : 3dup  2 pick  2 pick  2 pick  ;  [then]
2 buffer: wp-buf
: secure?  ( -- flag )
   init-spi
   .spi-id
   wp-buf 2 h# e.fffe spi-read
   wp-buf c@ [char] w = if
      wp-buf 1+ c@ [char] p = if
	 true exit
      then
   then
   false
;

[ifdef] sec-trg-gpio#
: sec-trg  ( -- )  sec-trg-gpio# gpio-set  ;

: protect-fw  ( -- )  secure?  if  spi-protect sec-trg  then  ;
[then]

\ Assumes offset is block-aligned
: write-setup-dance  ( -- )
   \ This check could be patched out, but the write protect latch would then
   \ prevent writing.  The message is for user-friendliness.
   secure?  abort" Security is enabled; can't reprogram FLASH from CForth"
\  init-spi
   wakeup-spi-flash
   .spi-id
   d# 40 us
   spi-unprotect           ( adr len offset )
;
: erase-dance  ( len offset -- )
   ." Erasing" cr
   write-setup-dance
   2dup erase-range        ( adr len offset )
   check-spi-erased        ( adr len offset )
;
: program-dance  ( adr len offset -- )
   ." Programming" cr
   write-setup-dance
   3dup program-range              ( adr len offset )
   ." Verifying" cr
   check-spi-programmed
;
: reflash  ( adr len offset -- )
   2dup erase-dance
   program-dance
;
: reflash0  ( -- )  dlofw-base /rom 0 reflash  ;
