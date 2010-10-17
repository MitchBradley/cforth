\ Send data in Intel Hex format with XON/XOFF flow control

\ To support >64K, we'd need to use these record formats:
\ : bb AAAA 02 SSSS dd dd dd dd ... cc          Address is (SSSS <  4) + AAAA
\ : bb AAAA 04 HHHH dd dd dd dd ... cc          Address is (HHHH < 16) + AAAA
\ The SSSS and HHHH portions of the address are "sticky", applying to
\ subsequent (type 00) records.


d# 17 constant xon
d# 19 constant xoff

: ?stall ( -- )
   rem-avail?  if      ( char )
      xoff = if        ( )
         begin         ( )
            d# 1000 (timed-rem-key) abort" oki timeout" ( char )
dup xon <> over xoff <> and  if  dup emit  then
         xon =  until  ( )
      then             ( )
   then                ( )
;

: rem-type&echoflowx  ( adr len -- )
   bounds ?do                         ( )
     ?stall
     i c@ rem-emit
   loop
;

\ You can change hex-type to redirect the output.
\ For example,   ' type to hex-type   would send to the console

defer hex-type  ( adr len -- )
' rem-type&echoflowx to hex-type  \ Default to the remote with flow control

\ Some utility routines

[ifndef] upper
[ifndef] upc
: upc  ( char -- char' )  \ Convert a character to upper case
   dup  [char] a [char] z between  if  h# 20 invert and  then
;
[then]
\ Convert a character array to upper case
: upper  ( adr len -- )  bounds  ?do  i c@  upc  i c!  loop  ;
[then]

variable out-addr  \ Current value for output record address field
variable hexsum    \ Running checksum

create crlf  carret c,  linefeed c,

\ Output a byte in hex and update the checksum

: hex-byte  ( u -- )  h# ff and  dup hexsum +!  <# u# u# u#> 2dup upper hex-type  ;

\ Output a single hex record

: put-line  ( adr len rectype -- )
   0 hexsum !                               ( adr len rectype )
   " :" hex-type   over hex-byte            ( adr len rectype )  \ Record length
   out-addr @ wbsplit  hex-byte  hex-byte   ( adr len rectype )  \ Address
   over out-addr +!                         ( adr len rectype )
   hex-byte                                 ( adr len )  \ Record type
   bounds  ?do  i c@ hex-byte  loop         ( )          \ Data bytes
   hexsum @ negate  hex-byte                ( )          \ Checksum
   crlf 2 hex-type                          ( )
;

\ Output the binary data from the buffer adr,len in Intel Hex format,
\ starting at address baseaddr

: hex-out  ( adr len baseaddr -- )
   out-addr !           ( adr len )
   begin  dup  while    ( adr len )
      2dup h# 10  min   ( adr len adr actual )
      tuck  0 put-line  ( adr len actual )
      /string           ( adr' len' )       \ Remove sent bytes from start of string
   repeat               ( adr len )
   2drop                ( )
   out-addr off  0 0 1  put-line            \ End record
;
