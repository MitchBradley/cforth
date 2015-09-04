\ Smart-comments for size configuration.

: <> = 0= ;
1 cells constant cell 
: ?\match  ( n1 n1 -- )  <>  if  postpone \  then   ;
: 16\  cell 2 ?\match  ; immediate
: 32\  cell 4 ?\match  ; immediate
: 64\  cell 8 ?\match  ; immediate
: \t16 /token 2 ?\match  ; immediate
: \t32 /token 4 ?\match  ; immediate
: \t64 /token 8 ?\match  ; immediate

1 constant /c
2 constant /w
4 constant /l

: ca1+ ( adr -- adr' ) 1+  ;
: wa1+ ( adr -- adr' ) 2+  ;
: la1+ ( adr1 -- adr2 )  /l +  ;

: /c*  ( n1 -- n2 )  ;
: /w*  ( n1 -- n2 )  dup +  ;
: /l*  ( n1 -- n2 )  /l *  ;
