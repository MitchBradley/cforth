\ Cortex-M3 FLASH Patch / Breakpoint words

: patch-ctrl@  ( -- n )  $e0002000 l@  ;
: patch-ctrl!  ( n -- )  $e0002000 l!  ;
: patch-remap@  ( -- n )  $e0002004 l@  ;
: patch-remap!  ( n -- )  $e0002004 l!  ;
: patch-comp@  ( index -- n )  $e0002008 swap la+ l@  ;
: patch-comp!  ( n index -- )  $e0002008 swap la+ l!  ;

8 /l* #32 + buffer: unaligned-remaps
: remaps  unaligned-remaps #32 round-up  ;

: setup-fpr  ( -- )
   remaps patch-remap!
   3 patch-ctrl!
;
: remap  ( what where index -- )
   >r                     ( what where  r: index )
   dup 3 invert and  l@   ( what where old  r: index )
   over 2 and  if         ( what where old  r: index )
      \ Second halfword   ( what where old  r: index )
      $ffff and rot       ( where old' new  r: index )
      wljoin              ( where what'     r: index )
   else                   ( what where old  r: index )
      \ First halfword    ( what where old  r: index )
      $ffff0000 and  rot  ( where old' new  r: index )
      or                  ( where what'     r: index )
   then                   ( where what'     r: index )
   remaps r@ la+ l!       ( where  r: index )
   1 or  r> patch-comp!   ( )
;
: breakpoint  ( where index -- )
   swap $c0000001 or  swap  patch-comp!
;
: ret-at  ( where -- )  $4770 swap 0 remap  ;
: nop-at  ( where -- )  $bf00 swap 1 remap  ;
: stall-at  ( where -- )  $e7fe swap 0 remap  ;
: clr-ret  ( -- )  0 0 patch-comp!  ;
: clr-nop  ( -- )  0 1 patch-comp!  ;
