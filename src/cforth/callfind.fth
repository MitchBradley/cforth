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
: .calls ( cfa -- )
  \ ['] forth   ( cfa origin)  \ There is some irrelevant stuff before forth
  ['] context  \ Colon definitions begin after the primitives
  begin ( cfa search-start )
         2dup here  tsearch  ( cfa last [ found-at ] f )
  while  dup  .caller cr    ( cfa last found-at)
         nip ta1+
  repeat 2drop
;
only forth also definitions
