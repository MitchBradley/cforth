: xwhere  ( -- )  ;  \ Will be patched later
: postpone  \ name  ( -- )
\   ?comp
   parse-word $find  ( adr len 0 | acf +-1 )
   dup  0=  if             ( adr len 0 )
      drop xwhere  2drop  compile lose
   else                                                   ( xt +-1 )
      0<  if  compile compile  then  compile,
   then
; immediate
