\ Smart-comments for size configuration.

: <> = 0= ;
1 cells constant cell 
: ?\match  ( n1 n1 -- )  <>  if  postpone \  then   ;
: 32\  ; immediate
: 16\  postpone \  ; immediate
: \t16 postpone \  ; immediate
: \t32  ; immediate

1 constant /c
1 constant /w
1 constant /l

: ca1+ 1+ ; ( adr -- adr' )
: wa1+ 1+ ; ( adr -- adr' )
: la1+ 1+ ; ( adr1 -- adr2 )

: /c*  ( n1 -- n2 )  ;
: /w*  ( n1 -- n2 )  ;
: /l*  ( n1 -- n2 )  ;
