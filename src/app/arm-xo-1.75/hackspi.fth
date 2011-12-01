: ssp1-clk-on  7 h# d4015050 l!   3 h# d4015050 l!  ;
: select-ssp1-pins  ( -- )
   h# 5003 h# d401e100 l!
   h# 5003 h# d401e104 l!
   h# 5003 h# d401e108 l!
   d# 46 gpio-set
   d# 46 gpio-dir-out
   h# c0 h# d401e10c l!
;

: init-spi  ( -- )
   select-ssp1-pins
   ssp1-clk-on
   0 h# d4035004 l!      \ Master mode
   h# 87 h# d4035000 l!  \ SPI mode, 8 bits, enabled
;

h# 10 buffer: spi-cmdbuf

: [[ d# 46 gpio-clr  ;
: ]] d# 46 gpio-set  ;

0 value bufp
: spi-out  ( n -- )  bufp c!  bufp 1+ to bufp  ;
: spi-cmd  ( n -- )  spi-cmdbuf to bufp  spi-out  ;
: spi-cs-off  ( -- )  spi-cmdbuf bufp over - [[ spi-send-only ]]  ;

: spi-adr  ( offset -- )  lbsplit drop  spi-out spi-out spi-out  ;

\ Programmed I/O versions
: cs0  d# 46 gpio-clr ;
: cs1  d# 46 gpio-set ;
: pio-mode  d# 46 gpio-set  d# 46 gpio-dir-out  h# c0 d# 46 af!  ;
: ssp-mode  h# 5003 d# 46 af!  ;
: g  begin d4035008 l@ 8 and until  d4035010 l@  ;
: p  d4035010 l! ;
: p0 0 d4035010 l! ;
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
   begin d4035008 l@ 8 and  while  d4035010 l@ drop  repeat 
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

\ "0 spi-write-status" turns off write protect bits
: clear-spi-flash-write-protect  ( -- )  0 spi-write-status  ;

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
   swap                                ( offset len )
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
      abort
   else                                            ( -1 )
      drop
   then
;
[ifndef] 3dup  : 3dup  2 pick  2 pick  2 pick  ;  [then]
\ Assumes offset is block-aligned
: write-setup-dance  ( -- )
\  init-spi
   wakeup-spi-flash
   .spi-id
   d# 40 us
   clear-spi-flash-write-protect   ( adr len offset )
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
: reflash0  ( -- )  0 h# 100000 0 reflash  ;

