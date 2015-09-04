only forth also hidden also definitions
decimal
variable sift-string
: vsift  ( adr len voc-cfa -- )
   ??cr ."    In vocabulary " dup .name cr
   follow  2>r                         ( r: test$ )
   begin  another?  while              ( xt )
      dup >name$                       ( xt this$ )
      2dup 2r@ search  if              ( xt this$ this$' )
         2drop ?cr                     ( xt this$ )
         ." (" rot (u.) type ." ) "    ( this$ )
	 type 3 spaces                 ( )
      else                             ( xt this$ this$' )
         2drop 3drop                   ( )
      then                             ( )
   repeat                              ( r: test$ )
   2r> 2drop                           ( )
;
forth definitions
: $sift  ( adr len -- )
   voc-link  begin  another-link?  while  ( adr len )
      >r 2dup r@ vsift                    ( adr len )
      r> >voc-link                        ( adr len )
   repeat                                 ( adr len )
   2drop                                  ( )
;
: sifting \ name ( -- )
   safe-parse-word $sift
;
only forth also definitions
