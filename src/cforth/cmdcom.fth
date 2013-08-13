\ Command parsing tools

decimal
128 buffer: cmdbuf 

variable exit-status

\ Append startstr to the end of endstr
: $cat  ( $ buf -- )
   over >r  dup >r    ( $ buf  r: $-len buf )
   count + swap move  ( )
   r> dup c@          ( buf buf-len r: $-len )
   r> + swap c!       ( )
;

: sh  \ command-line  ( -- )
   0 parse  dup 0=  if  2drop " sh"  then  $command
;
: command:  \ name   ( command-head$ -- )
   create ",
   does>  ( command-head$ )
   cmdbuf place    "  " cmdbuf $cat   0 parse cmdbuf $cat
   cmdbuf $command          ( status )
   exit-status !
;

