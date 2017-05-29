: http-get?  ( req$ -- false | url$ true )
   over " GET " comp 0=  if        ( req$ )
      4 /string                    ( req$' )  \ Lose "GET "
      bl split-string  2drop true  ( url$ true )
   else                            ( adr len )
      false                        ( req$ false )
   then
;

: collapse$  ( adr len n -- adr len-n )
   >r  r@ -            ( adr len-n  r: n )
   over dup r> +       ( adr len-n  adr adr+n )
   swap 2 pick  move   ( adr len-n )
;
: url%  ( $ -- $' )
   dup 3 <  if  exit  then          ( adr len )
   over 1+ 2                        ( adr len  number$ )
   push-hex $number pop-base  if    ( adr len n )
      1 /string                     ( adr' len' )
   else                             ( adr len n )
      2 pick c!                     ( adr len )
      1 /string                     ( adr' len' )
      2 collapse$                   ( adr' len' )
   then                             ( adr len )
;

: urldecode$  ( $ -- $' )
   over swap             ( adr adr len )
   begin  ?dup  while    ( adr rem-adr  len )
      over c@ '%' =  if  ( adr rem-adr  len )
	 url%            ( adr rem-adr' len' )
      else               ( adr rem-adr  len )
	 1 /string       ( adr rem-adr' len' )
      then               ( adr rem-adr' len' )
   repeat                ( adr rem-adr )
   over -                ( adr len )
;
