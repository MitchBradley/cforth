\ Convert a floating point string like 100.12 to an integer scaled up
\ by the power of 10 given by digits. E.g. "100.12" 1 gives 1001

: f$>int-scaled  ( $ digits -- n )
   >r push-decimal $number? pop-base  0= abort" Invalid floating point number"  ( d r: digits )
   drop  ( n r: digits )

   \ dpl is -1 if no decimal point was present.  We treat that the same as e.g. " 10."
   dpl @ 0<  if  0  dpl !  then     ( n  r: digits )

   r@  dpl @ >=  if                ( n  r: digits )
      \ Scaler is at least the number of postdecimal digits so
      \ we keep all the digits and possibly scale up some more
      r>  dpl @ -  0  ?do  #10 *  loop  ( n )
   else             ( n r: digits )
      \ Scaler is less than the number of postdecimal digits so
      \ we discard the extra ones
      dpl @  r>  -  0  ?do  #10 /  loop  ( n )
   then                                   ( n )
;

\ Convert a floating point string like 100.125 to an integer scaled up
\ by the power of 10 given by digits, with rounding.
\ E.g. "100.125" 2 gives 10013

: f$>int-scaled-rounded  ( $ digits -- n )
   >r push-decimal $number? pop-base  0= abort" Invalid floating point number"  ( d r: digits )
   drop  ( n r: digits )

   \ dpl is -1 if no decimal point was present.  We treat that the same as e.g. " 10."
   dpl @ 0<  if  0  dpl !  then     ( n  r: digits )

   r@  dpl @ >=  if                ( n  r: digits )
      \ Scaler is at least the number of postdecimal digits so
      \ we keep all the digits and possibly scale up some more
      r>  dpl @ -  0  ?do  #10 *  loop  ( n )
   else             ( n r: digits )
      \ Scaler is less than the number of postdecimal digits so
      \ we discard the extra ones.  We know that dpl is at least
      \ 1 more than digits.
      dpl @  r>  -  1-  0  ?do  #10 /  loop  ( n )
      5 + #10 /                              ( n )
   then                                      ( n )
;

\ Convert a floating point string like 100.12 to an integer, discarding
\ postdecimal digits.
: f$>int  ( $ -- n )  0 f$>int-scaled  ;

\ Convert a floating point string like 100.5 to an integer, rounding
\ to the nearest integer.
: f$>int-rounded  ( $ -- n )  0 f$>int-scaled-rounded  ;

\ Tests/examples
false [if]
" 100.5999" f$>int .d cr \ expect 100
" 0.5" f$>int .d cr  \ expect 0
" 0.5" f$>int-rounded .d cr  \ expect 1
" 0.4" f$>int-rounded .d cr  \ expect 0
" 100" f$>int-rounded .d cr  \ expect 100
" 100.4999" f$>int-rounded .d cr  \ expect 100
" 100.5999" f$>int-rounded .d cr  \ expect 101
" 100.1234" 1 f$>int-scaled .d cr \ expect 1001
" 100.1234" 2 f$>int-scaled .d cr \ expect 10012
" 100" 2 f$>int-scaled .d cr \ expect 10000
" 100.1" 2 f$>int-scaled .d cr \ expect 10010
" 100.1251" 2 f$>int-scaled-rounded .d cr \ expect 10013
" 100.1249" 2 f$>int-scaled-rounded .d cr \ expect 10012
[then]
