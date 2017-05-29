\ Redirects Forth output to a buffer that is transmitted as it fills

#512 constant /chunk
/chunk buffer: chunk

defer reply-send  ( adr len -- )

0 value reply-len
: flush-reply  ( -- )
   reply-len  if
      chunk reply-len reply-send
      0 to reply-len
   then
;
: reply-emit  ( c -- )
   reply-len /chunk =  if  flush-reply  then  ( c )
   chunk reply-len + c!                       ( )
   reply-len 1+ to reply-len                  ( )
;
: reply-cr  ( -- )  #13 reply-emit  #10 reply-emit  ;
: reply+emit  ( c -- )  dup sys-emit  reply-emit  ;
: reply+cr  ( -- )  #13 reply-emit  #10 reply+emit  ;

: reply+emit-on  ( -- )
   ['] reply+emit to (emit
   ['] reply+cr   to cr
;
: reply-emit-on  ( -- )
   ['] reply-emit to (emit
   ['] reply-cr   to cr
;
: reply-off  ( -- )
   ['] sys-emit to (emit
   ['] sys-cr   to cr
;
: reply+emit{  ( -- )  0 to reply-len  reply+emit-on  ;
: reply{  ( -- )  0 to reply-len  reply-emit-on  ;
: }reply  ( -- )  flush-reply   reply-off  ;
