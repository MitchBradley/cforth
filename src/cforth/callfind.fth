create trace-tools.f
only forth also hidden definitions
: rom-dict-limit  ( -- adr )  origin 'ramct @ ta+  ;
: ram-dict-start  ( -- adr )  'ramtokens @  ;
: ram-rom-dictionary?  ( -- flag )  here 'ramtokens @  >=  ;
: reasonable-ip? ( ip -- flag)
   \ IP values are always aligned
   dup  dup aligned <>  if  drop false exit  then  ( ip )

   origin                           ( ip start )
   ram-rom-dictionary?  if          ( ip start )
      \ If this is a RAM/ROM dictionary layout, first check the ROM portion
      \ then set the start address to the RAM portion
      over swap                     ( ip  ip start )
      rom-dict-limit within  if  drop true exit  then  ( ip )
      ram-dict-start                ( ip start )
   then                             ( ip start )
   here within                      ( flag )
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

   ram-rom-dictionary?  if               ( xt start )
      \ If this is a RAM/ROM dictionary layout, first search the ROM portion
      \ then set the start address to the RAM portion
      rom-dict-limit  2 pick  (.calls)   ( xt )
      ram-dict-start                     ( xt start' )
   then                                  ( xt start )

   \ Finish by searching up to here
   here (.calls)
;
only forth also definitions
