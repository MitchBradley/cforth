: 2constant  ( "name" d -- )
   create  , ,  does>  dup cell+ @  swap @
;
: 2literal  ( d -- )  swap  postpone literal  postpone literal  ; immediate
: 2variable  ( "name" -- )
   create  2 /n* ualloc ,
   does> >user
;

\ : d0=   ( d -- flag )  or  0=  ;
: d0<>  ( d -- flag )  or  0<>  ;
: d0<   ( d -- flag )  nip 0<  ;
: d=    ( d1 d2 -- flag )  d- d0=  ;
: d<>   ( d1 d2 -- flag )  d=  0=  ;
: du<   ( ud1 ud2 -- flag )  rot  swap  2dup <>  if  2swap  then  2drop u<  ;
: d<    ( d1 d2 -- flag )  2 pick over = if drop nip u< else nip < nip then  ;
: d>=   ( d1 d2 -- flag )  d< 0=  ;
: d>    ( d1 d2 -- flag )  2swap d<  ;
: d<=   ( d1 d2 -- flag )  2swap d< 0=  ;
\ : dnegate  ( d -- -d )  0 0  2swap  d-  ;
: dabs     ( d -- +d )  2dup  d0<  if  dnegate  then  ;

\ : s>d   ( n -- d )  dup 0<  ;
\ : u>d   ( u -- d )  0  ;
: d>s   ( d -- n )  drop  ;
: d>u   ( d -- yu )  drop  ;

: (d.)  (  d -- adr len )  tuck dabs <# #s rot sign #>  ;
: (ud.) ( ud -- adr len )  <# #s #>  ;

: d.    (  d -- )     (d.) type space  ;
: ud.   ( ud -- )    (ud.) type space  ;
: ud.r  ( ud n -- )  >r (ud.) r> over - spaces type  ;

: d2*   ( xd1 -- xd2 )  2*  over 0<  if  1+  then  swap  2*  swap  ;
: d2/   ( xd1 -- xd2 )
   dup 2/  swap 1 and  rot 1 rshift  swap
   bits/cell 1- lshift  or  swap
;

: dmax  ( xd1 xd2 -- )  2over 2over d<  if  2swap  then  2drop  ;
: dmin  ( xd1 xd2 -- )  2over 2over d<  0=  if  2swap  then  2drop  ;

: m+    ( d1|ud1 n -- )  s>d  d+  ;
: 2rot  ( d1 d2 d3 -- d2 d3 d1 )  2>r 2swap 2r> 2swap  ;
: drot  ( d1 d2 d3 -- d2 d3 d1 )  2>r 2swap 2r> 2swap  ;
: -drot ( d1 d2 d3 -- d3 d1 d2 )  drot drot  ;
: dinvert  ( d1 -- d2 )  swap invert  swap invert  ;

: dlshift  ( d1 n -- d2 )
   tuck lshift >r                           ( low n  r: high2 )
   2dup bits/cell  swap - rshift  r> or >r  ( low n  r: high2' )
   lshift r>                                ( d2 )
;
: drshift  ( d1 n -- d2 )
   2dup rshift >r                           ( low high n  r: high2 )
   tuck  bits/cell swap - lshift            ( low n low2  r: high2 )
   -rot  rshift  or                         ( low2  r: high2 )
   r>                                       ( d2 )
;
: d>>a  ( d1 n -- d2 )
   2dup rshift >r                           ( low high n  r: high2 )
   tuck  bits/cell swap - lshift            ( low n low2  r: high2 )
   -rot  >>a  or                            ( low2  r: high2 )
   r>                                       ( d2 )
;
: du*  ( d1 u -- d2 )  \ Double result
   tuck u* >r     ( d1.lo u r: d2.hi )
   um*  r> +      ( d2 )
;
: du*t  ( ud.lo ud.hi u -- res.lo res.mid res.hi )  \ Triple result
   tuck um*  2>r  ( ud.lo u          r: res.mid0 res.hi0 )
   um*            ( res.lo res.mid1  r: res.mid0 res.hi0 )
   0  2r> d+      ( res.lo res.mid res.hi )
;
