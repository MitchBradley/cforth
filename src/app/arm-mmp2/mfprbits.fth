: no-update,  ( -- )  8 w,  ;  \ 8 is a reserved bit; the code skips these

: +edge-clr     ( n -- n' )  h#   40 or  ;
: +very-slow    ( n -- n' )  h# 0000 or  ;
: +slow         ( n -- n' )  h# 0800 or  ;
: +medium       ( n -- n' )  h# 1000 or  ;
: +fast         ( n -- n' )  h# 1800 or  ;
: +twsi         ( n -- n' )  h#  400 or  ;
: +pull-up      ( n -- n' )  h# c000 or  ;
: +pull-dn      ( n -- n' )  h# a000 or  ;
: +pull-up-alt  ( n -- n' )  h# 4000 or  ;
: +pull-dn-alt  ( n -- n' )  h# 2000 or  ;
: +pull-sel     ( n -- n' )  h# 8000 or  ;

\ We always start with edge detection off; it can be turned on later as needed
: af,   ( n -- )  +edge-clr w,  ;

: sleep-  ( n -- n' )  h# 0200 or  ;
: sleep0  ( n -- n' )  h# 0000 or  ;
: sleep1  ( n -- n' )  h# 0100 or  ;
: sleepi  ( n -- n' )  h# 0080 or  ;
