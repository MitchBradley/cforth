\ From Perry/Laxen, largely verbatim

\ The dump utility gives you a formatted hex dump with the ascii
\ text corresponding to the bytes on the right hand side of the
\ screen.  In addition you can use the SM word to set a range of
\ memory locations to desired values.  SM displays an address and
\ its contents.  You can go forwards or backwards depending upon
\ which character you type. Entering a hex number changes the
\ contents of the location.  DL can be used to dump a line of
\ text from a screen.

only forth also hidden also definitions
decimal
: .8   (s n -- )   <#   u# u# u# u# u# u# u# u#  u#>   type   space   ;

: ?emit  (s char -- ) dup printable? 0=  if  drop  else  emit  then  ;

: dln   (s addr --- )
   ??cr   dup 8 u.r   2 spaces
   dup 4 bounds do  i @ .8  loop  2 spaces
   4 bounds do  i @ ?emit  loop
   cr
;

forth definitions
: dump   (s addr len -- )
   push-hex
   1 max  bounds do   i dln  exit? ?leave  4  +loop
   pop-base
;

: ldump  ( addr len -- )  dump  ;

: du   (s addr -- addr+64 )  dup d# 64 dump   d# 64 +   ;

\ : dl   (s line# -- )
\    c/l * scr @ block +   c/l dump   ;
only forth also definitions
