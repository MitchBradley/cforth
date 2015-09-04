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
cell 2* value adr-width
: .2   (s n -- )   u>d <#   # #   #>   type   space   ;
: .8   (s n -- )   <#   u# u# u# u# u# u# u# u#  u#>   type   space   ;
: d.2   (s addr len -- )   bounds ?do   i c@ .2   loop   ;
: emit.   (s char -- )
   127 and dup printable? 0=  if  drop [char] .  then  emit  ;
: dln   (s addr --- )
   ??cr   dup adr-width u.r   2 spaces   8 2dup d.2 space
   over + 8 d.2 space
   16   bounds ?do   i c@ emit.   loop   ;
: ?.n    (s n1 n2 -- n1 )
   2dup = if  ." \/"  drop   else   2 .r   then   space   ;
: ?.a    (s n1 n2 -- n1 )
   2dup = if  ." v"  drop   else   1 .r   then  ;

: l.head  (s addr len -- addr' len' )
   swap   dup -16 and  swap  15 and   ( cr )  adr-width 2+ spaces
   16 0 do  6 spaces  i ?.n  4 +loop
   space   16 0 do  i ?.a  loop   rot +  ;

: l-dln   (s addr --- )
   ??cr   dup adr-width u.r   2 spaces
   dup 16 bounds do  i @ .8  4 +loop  space
   16   bounds ?do   i c@ emit.   loop   ;

\ dump and fill memory utility                        06oct83map
: .head   (s addr len -- addr' len' )
   swap   dup -16 and  swap  15 and   ( cr ) adr-width 2+ spaces
   8 0 do   i ?.n   loop   space   16 8 do   i ?.n   loop
   space   16 0 do  i ?.a  loop   rot +  ;
forth definitions
: dump   (s addr len -- )
   base @ -rot  hex   .head  ( addr len )
   dup 0= if 1+ then
   bounds do   i dln  exit? ?leave  16 +loop   base !   ;
: ldump  ( addr len -- )
   push-hex
   l.head  ( addr len )
   bounds ?do   i l-dln  exit? ?leave  16 +loop
   pop-base
;

: du   (s addr -- addr+64 )
   dup 64 dump   64 +   ;
\ : dl   (s line# -- )
\    c/l * scr @ block +   c/l dump   ;
only forth also definitions
