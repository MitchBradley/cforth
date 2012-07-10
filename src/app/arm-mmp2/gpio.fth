create gpio-offsets
\  0     1     2        3         4         5
   0 ,   4 ,   8 , h# 100 ,  h# 104 ,  h# 108 ,

: >gpio-pin ( gpio# -- mask pa )
   dup h# 1f and    ( gpio# bit# )
   1 swap lshift    ( gpio# mask )
   swap 5 rshift  gpio-offsets swap na+ @  gpio-base +  ( mask pa )
;
: gpio-pin@     ( gpio# -- flag )  >gpio-pin io@ and  0<>  ;

: >gpio-dir     ( gpio# -- mask pa )  >gpio-pin h# 0c +  ;
: gpio-out?     ( gpio# -- out? )  >gpio-dir io@ and  0<>  ;

: gpio-set      ( gpio# -- )  >gpio-pin h# 18 +  io!  ;
: gpio-clr      ( gpio# -- )  >gpio-pin h# 24 +  io!  ;

: >gpio-rer     ( gpio# -- mask pa )  >gpio-pin h# 30 +  ;
: gpio-rise@    ( gpio# -- flag )  >gpio-rer io@ and  0<>  ;

: >gpio-fer     ( gpio# -- mask pa )  >gpio-pin h# 3c +  ;
: gpio-fall@    ( gpio# -- flag )  >gpio-fer io@ and  0<>  ;

: >gpio-edr     ( gpio# -- mask pa )  >gpio-pin h# 48 +  ;
: gpio-edge@    ( gpio# -- flag )  >gpio-edr io@ and  0<>  ;
: gpio-clr-edge ( gpio# -- )  >gpio-edr io!  ;

: gpio-dir-out  ( gpio# -- )  >gpio-pin h# 54 + io!  ;
: gpio-dir-in   ( gpio# -- )  >gpio-pin h# 60 + io!  ;
: gpio-set-rer  ( gpio# -- )  >gpio-pin h# 6c + io!  ;
: gpio-clr-rer  ( gpio# -- )  >gpio-pin h# 78 + io!  ;
: gpio-set-fer  ( gpio# -- )  >gpio-pin h# 84 + io!  ;
: gpio-clr-fer  ( gpio# -- )  >gpio-pin h# 90 + io!  ;

: >gpio-mask    ( gpio# -- mask pa )  >gpio-pin h# 9c +  ;
: gpio-set-mask ( gpio# -- )  >gpio-mask io!  ;

: >gpio-xmsk     ( gpio# -- mask pa )  >gpio-pin h# a8 +  ;
: gpio-set-xmsk  ( gpio# -- )  >gpio-xmsk io!  ;




