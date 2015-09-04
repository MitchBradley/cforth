\ Tethering tools - lets you run CForth on a host system (Linux or Windows)
\ and talk over a serial port to a small communications stub running on a
\ target system.  Via that channel, the host CForth can access target memory
\ and call target C subroutines by address, passing arguments and returning
\ the result.  The target subroutine addresses can be found in the target
\ application's symbol table.
\ The C code for the target-resident communications stub is in commstub.c

hex

h# 10 buffer: tbuf

\ Receive a byte from the target serial line, timing out after
\ a configurable number of milliseconds
d# 1000 value trcv-timeout-ms
: trcv  ( -- b )
   tbuf 1 trcv-timeout-ms timed-serial-read  1 <> abort" Read timed out"
   tbuf c@
;

\ Send a byte over the target serial line
: tsend  ( b -- )  tbuf c!  tbuf 1 serial-write  ;

\ Receive a 32-bit number from the target serial line.
\ Reception ends when an ACK (c0) is received.
\ If there is no number, just an ACK, tread returns 0.
: tread  ( -- n )
   0 begin                      ( n )
      trcv                      ( n byte )
      dup h# c0 and  h# c0 <>   ( n byte flag )
   while                        ( n )
      dup h# 80 and  if         ( n byte )
         nip  h# 7f and         ( n' )
      else                      ( n byte )
	 swap 7 lshift  or      ( n' )
      then                      ( n )
   repeat                       ( n byte )
   dup h# 3f and  if            ( n byte )
      ." Bogus command "        ( n byte )
      dup .x cr                 ( n byte )
   then                         ( n byte )
   drop                         ( n )
;

\ 32-bit numbers are sent over the serial line piecewise.
\ A byte of the form 10nn.nnnn pushes the stack and sets
\ the top of stack to the 6-bit value nnnnnn.
\ A byte of the form 0mmm.mmmm left-shifts the top of stack
\ by 7 and merges the 7-bit value mmmmmmm into the low bits.
\ You start with the 10nn.nnnn form then send however many
\ 0mmm.mmmmm's as necessary to construct the number.
\ At the end you can either send a command or start another
\ number.

\ Send the first byte of a number - 10nn.nnnn form
: send0  ( u -- )  h# 3f and h# 80 or tsend  ;

\ Send a subsequent byte with 7 bits - 0mmm.mmmm form
: send1  ( u -- )  h# 7f and tsend  ;

\ Send two subsequent bytes encompassing 14 bits
: send2  ( u -- )  dup 7 rshift send1  send1  ;

\ Send three subsequent bytes encompassing 21 bits
: send3  ( u -- )  dup d# 14 rshift send1  send2  ;

\ Push a 32-bit number onto the target stack, using as few serial
\ bytes as possible.
: tpush  ( n -- )
   dup h#       40 u<  if  send0 exit  then
   dup h#     2000 u<  if  dup     7 rshift send0 send1  exit  then
   dup h#   100000 u<  if  dup d# 14 rshift send0 send2  exit  then
   dup h#  8000000 u<  if  dup d# 21 rshift send0 send3  exit  then
   dup d# 28 rshift send0  dup d# 21 rshift send1 send3
;

: tcmd  ( cmd -- result )  tsend tread  ;

\ Basic target operations

\ Pops and returns the top of the target stack
: tpop  ( -- tval )  h# c7 tcmd  ;

\ Read a 32-bit number from target address tadr
: t@  ( tadr -- tval )  tpush  h# c1 tcmd  ;

\ Read a 16-bit number from target address tadr
: tw@ ( tadr -- tval )  tpush  h# c2 tcmd  ;

\ Read an 8-bit number from target address tadr
: tc@ ( tadr -- tval )  tpush  h# c3 tcmd  ;

\ Write a 32-bit number to target address tadr
: t!  ( tval tadr -- )  swap tpush  tpush  h# c4 tsend  ;

\ Write a 16-bit number to target address tadr
: tw! ( tval tadr -- )  swap tpush  tpush  h# c5 tsend  ;

\ Write an 8-bit number to target address tadr
: tc! ( tval tadr -- )  swap tpush  tpush  h# c6 tsend  ;

\ Tell the target communications stub to exit
: texit  ( -- )
   h# c8 tsend
   tbuf 1 d# 1000 timed-serial-read  1 =  if
      tbuf c@ dup  h# c0  if
	 drop  ." Tether loop reconnected" cr
      else
[ifdef] display
	 ." Displaying" cr
	 emit
	 display
[else]
         drop
[then]
      then
   then
;


\ Execute the target subroutine at tadr and wait for ACK, but
\ do not return a result value.  Subroutine arguments must
\ already have been pushed onto the target stack.
: texec0  ( tadr -- )  tpush  h# e0 tcmd drop  ;

\ Execute the target subroutine at tadr and wait for ACK,
\ returning the subroutines result value.  Subroutine arguments
\ must already have been pushed onto the target stack.
: texec1  ( tadr -- tval )  tpush  h# e1 tcmd  ;

\ Push the address of the first target scratch buffer onto the
\ target stack.
: tscratch0  ( -- )  h# c9 tsend  ;

\ Push the address of the second target scratch buffer onto the
\ target stack.
: tscratch1  ( -- )  h# ca tsend  ;

\ Send len bytes from host address adr to the target.
\ Before calling this you must first push onto the target stack
\ the target destination address where the bytes will go, i.e.
\ with tscratch0, tscratch1, or by pushing an explicit address.
: tout  ( adr len -- )
   dup tpush h# cb tsend  ( adr len )
   bounds ?do  i c@ tsend  loop
;

\ Tell the target to send len bytes and receive them into host
\ memory at adr.  Before calling this you must first push onto
\ the target stack the target source address for the bytes, i.e.
\ with tscratch0, tscratch1, or by pushing an explicit address.
: tin  ( adr len -- )
   dup tpush h# cc tsend  ( adr len )   
   bounds ?do  trcv i c!  loop  ( )  
;

: tmove-in  ( tadr hadr len -- )  rot tpush tin  ;
: tmove-out  ( hadr tadr len -- )  swap tpush tout  ;
: tin-s0  ( hadr len -- )  tscratch0  tin  ;
: tin-s1  ( hadr len -- )  tscratch1  tin  ;
: tout-s0  ( hadr len -- )  tscratch0  tout  ;
: tout-s1  ( hadr len -- )  tscratch1  tout  ;

: sync  ( -- )
   \ Discard any queued characters
   begin  tbuf 1 1 timed-serial-read  0<= until
   h# cd tcmd drop
;

: /scratch  ( -- n )  h# ce tcmd  ;

alias tp tpush   \ For interactive convenience

\ Local memory buffer used by various commands below
h# 80 buffer: local-buf

\ Target memory dumpers - tdump, twdump, and tldump
also hidden
\ : td.2  ( adr len -- )  bounds  ?do  i c@ .2 loop  ;
: tread16  ( adr -- )  tpush  local-buf d# 16 tin  ;  \ Helper
: tdln  ( adr -- )  \ Helper
   ??cr dup 8 u.r 2 spaces  tread16    ( )
   local-buf     8 d.2 space           ( )
   local-buf 8 + 8 d.2 space           ( )
   local-buf d# 16 bounds  do   i c@ emit.  loop
;

\ Dump target memory as bytes
: tdump  ( tadr len -- )
   base @ -rot hex .head  dup 0= if  1+  then
   bounds  ?do  i tdln exit? ?leave  d# 16 +loop
   base !
;

: tl-dln  ( tadr -- )  \ Helper
   ??cr dup 8 u.r 2 spaces  tread16   ( )
   local-buf d# 16 bounds  do  i @ .8 4 +loop  space
   local-buf d# 16 bounds  do  i c@ emit.  loop
;

\ Dump target memory as 32-bit longwords
: tldump  ( tadr len -- )
   push-hex l.head
   bounds  ?do   i tl-dln exit? ?leave  d# 16 +loop
   pop-base
;

: .4  ( n -- )  <# u# u# u# u# u#> type space  ;  \ Helper
: tw-dln  ( tadr -- )  \ Helper
   ??cr dup 8 u.r 2 spaces  tread16   ( )
   local-buf d# 16 bounds  do  i w@ .4  2 +loop  space
   local-buf d# 16 bounds  do  i c@ emit.  loop
;
: w.head  ( tadr len -- tadr len )  \ Helper
   swap dup h# fffffff0 and
   swap h# f and d# 10 spaces
   d# 16 0  do  2 spaces  i ?.n  2 +loop space
   d# 16 0  do    i ?.a  loop  rot +
;

\ Dump target memory as 16-bit halfwords
: twdump  ( tadr len -- )
   push-hex w.head   ( tadr len )
   bounds  ?do   i tw-dln exit? ?leave  d# 16 +loop
   pop-base
;
previous
