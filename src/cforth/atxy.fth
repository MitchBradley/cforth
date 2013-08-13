\ This implementation of AT-XY requires an ANSI terminal.

: .char#  ( n -- )  base @ >r  decimal  1+ 0 <# #s #> type  r> base !  ;
: at-xy  ( x y -- )
   d# 27 emit  ." ["  over .char#  ." ;"  dup .char#  ." H"  ( x y )
   #line !  #out !
;
