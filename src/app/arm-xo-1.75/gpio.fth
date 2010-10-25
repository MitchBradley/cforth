create gpio-offsets
\  0     1     2        3         4         5
   0 ,   4 ,   8 , h# 100 ,  h# 104 ,  h# 108 ,

: >gpio-pin ( gpio# -- mask pa )
   dup h# 1f and    ( gpio# bit# )
   1 swap lshift    ( gpio# mask )
   swap 5 rshift  gpio-offsets swap na+ @  gpio-base +  ( mask pa )
;
: gpio-pin@     ( gpio# -- flag )  >gpio-pin l@ and  0<>  ;

: >gpio-dir     ( gpio# -- mask pa )  >gpio-pin h# 0c +  ;
: gpio-out?     ( gpio# -- out? )  >gpio-dir l@ and  0<>  ;

: gpio-set      ( gpio# -- )  >gpio-pin h# 18 +  l!  ;
: gpio-clr      ( gpio# -- )  >gpio-pin h# 24 +  l!  ;

: >gpio-rer     ( gpio# -- mask pa )  >gpio-pin h# 30 +  ;
: gpio-rise@    ( gpio# -- flag )  >gpio-rer l@ and  0<>  ;

: >gpio-fer     ( gpio# -- mask pa )  >gpio-pin h# 3c +  ;
: gpio-fall@    ( gpio# -- flag )  >gpio-fer l@ and  0<>  ;

: >gpio-edr     ( gpio# -- mask pa )  >gpio-pin h# 48 +  ;
: gpio-edge@    ( gpio# -- flag )  >gpio-edr l@ and  0<>  ;
: gpio-clr-edge ( gpio# -- )  >gpio-edr l!  ;

: gpio-dir-out  ( gpio# -- )  >gpio-pin h# 54 + l!  ;
: gpio-dir-in   ( gpio# -- )  >gpio-pin h# 60 + l!  ;
: gpio-set-rer  ( gpio# -- )  >gpio-pin h# 6c + l!  ;
: gpio-clr-rer  ( gpio# -- )  >gpio-pin h# 78 + l!  ;
: gpio-set-fer  ( gpio# -- )  >gpio-pin h# 84 + l!  ;
: gpio-clr-fer  ( gpio# -- )  >gpio-pin h# 90 + l!  ;

: >gpio-mask    ( gpio# -- mask pa )  >gpio-pin h# 9c +  ;
: gpio-set-mask ( gpio# -- )  >gpio-mask l!  ;

: >gpio-xmsk     ( gpio# -- mask pa )  >gpio-pin h# a8 +  ;
: gpio-set-xmsk  ( gpio# -- )  >gpio-xmsk l!  ;




