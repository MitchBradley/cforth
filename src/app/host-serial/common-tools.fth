\needs wljoin : wljoin  ( wlo whi -- l )  d# 16 lshift or  ;
\needs be-w@  : be-w@  ( adr -- w )  dup 1+ c@ swap c@ bwjoin  ;
\needs be-l@  : be-l@  ( adr -- w )  dup 2+ be-w@ swap be-w@ wljoin  ;
\needs le-w@  : le-w@  ( adr -- w )  dup c@ swap 1+ c@ bwjoin  ;
\needs le-l@  : le-l@  ( adr -- l )  dup le-w@ swap 2+ le-w@ wljoin  ;
\needs le-w!  : le-w!  ( w adr -- )  >r wbsplit r@ 1+ c!  r> c!  ;
\needs le-l!  : le-l!  ( l adr -- )  >r lwsplit r@ 2+ le-w!  r> le-w!  ;
\needs $=     : $=  ( adr1 len1 adr2 len2 -- flag )  compare 0=  ;

: -leading  ( adr len -- adr' len' )
   begin  dup  while                   ( adr len )
      over c@  bl  <>  if  exit  then  ( adr len )
      1 /string                        ( adr' len' )
   repeat                              ( adr' len' )
;

: arg-or-default  ( def-name$ -- name$ )
   0 parse -leading -trailing        ( def-name$ name$ )
   dup  if  2swap  then  2drop       ( name$ )
;
