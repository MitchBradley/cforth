: .log-buf  ( addr len -- )
   bounds do
      i c@                              ( char )
      dup  if  dup emit  then           ( char )        \ skip NULs
      h# 0a =  if  5 ms  then           ( )
   loop
;
0 value log-buf-offset  \ offset kernel virtual address to physical address
0 value log-buf-len
0 value log-buf
0 value log-buf-end
: .epitaph  ( addr -- )
   >r
   r@ h# 08 + @  r@ -   to log-buf-offset
   r@ h# 0c + @         to log-buf-len
   r@ h# 10 + @  log-buf-offset -                        to log-buf
   r@ h# 14 + @  log-buf-offset - @  log-buf-len 1- and  to log-buf-end
   r> drop              ( )
   log-buf log-buf-end +  log-buf-len log-buf-end -  .log-buf
   log-buf                log-buf-end 1-             .log-buf
;
: epitaph  ( -- )
   ." epitaph "
   h# 3000.0000 0 do
      i @ h# 2163.666f =  if
         i h# 04 + @ h# 7274.6821 =  if
	    ." found" cr  i .epitaph  cr cr
            unloop exit
         then
      then
      h# 1000
   +loop
   ." missing" cr
;
