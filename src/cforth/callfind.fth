create trace-tools.f
only forth also hidden definitions
: reasonable-ip? ( ip -- flag)
   dup  origin here between  ( ip flag)
   if   dup aligned =     \ acf's are always aligned
   else drop false
   then
;
: probably-cfa? ( cfa -- flag)
   reasonable-ip?
;
: .current-word ( ip -- )  find-cfa .name  ;
: .last-executed ( ip -- )
   /token - token@  ( cfa)
  dup probably-cfa? 
  if  .name  else  drop ." ??"  then
;
: .caller ( ip -- )
   td 18 to-column ." Called from "
   dup .current-word
   td 56 to-column ." at "
   .
;
only forth hidden also forth definitions
: (.calls)   ( xt start end -- )
  >r
  begin ( xt start  r: end )
     2dup r@  tsearch  ( cfa last [ found-at ] f )
  while  dup  .caller cr    ( cfa last found-at)
         nip ta1+
  repeat r> 3drop
;
: .calls ( xt -- )
   ['] context  ( start )      \ Colon definitions begin after the primitives
   here  'ramtokens @  >=  if       ( xt start )
      \ If this is a RAM/ROM dictionary layout, first search the ROM portion
      \ then set the start address to the RAM portion
      over swap                     ( xt xt start )
      origin 'ramct @ ta+ (.calls)  ( xt )
      'ramtokens @                  ( xt start' )
   then                             ( xt start )

   \ Finish by searching up to here
   here (.calls)
;
only forth also definitions
