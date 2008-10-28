: 2constant  ( "name" d -- )
   create  , ,  does>  dup cell+ @  swap @
;
: 2literal  ( d -- )  swap  postpone literal  postpone literal  ; immediate
: 2variable  ( "name" d -- )
   create  0 , 0 ,
;
: d0<  nip 0<  ;
: d<  ( d1 d2 -- )  rot  swap  2dup <>  if  2swap  then  2drop <  ;
: dabs  ( d -- +d )  2dup  d0<  if  dnegate  then  ;
: d>s  ( d -- n )  drop  ;
: (d.)  ( d -- adr len )  tuck dabs <# #s rot sign #>  ;
: d.  ( d -- )  (d.) type space  ;
: (ud.)  ( ud -- adr len )  <# #s rot #>  ;
: ud.   ( ud -- )  (ud.) type space  ;
: ud.r  ( ud n -- )  >r (ud.) r> over - spaces type  ;
: d=  ( d1 d2 -- )  d- d0=  ;
: d2*  ( xd1 -- xd2 )  2*  over 0<  if  1+  then  swap  2*  swap  ;
: d2/  ( xd1 -- xd2 )
   dup 2/  swap 1 and  rot 1 rshift  swap
32\ d# 31
16\ d# 15
   <<  or  swap  
;
: dmax  ( xd1 xd2 -- )  2over 2over d<  if  2swap  then  2drop  ;
: dmin  ( xd1 xd2 -- )  2over 2over d<  0=  if  2swap  then  2drop  ;
: m+    ( d1|ud1 n -- )  s>d  d+  ;
: 2rot  ( d1 d2 d3 -- d2 d3 d1 )  2>r 2swap 2r> 2swap  ;
: du<  ( ud1 ud2 -- )  rot  swap  2dup <>  if  2swap  then  2drop u<  ;
