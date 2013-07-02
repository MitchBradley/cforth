only forth also hidden also definitions
decimal
variable sift-string
: vsift  ( adr len voc-cfa -- )
   ??cr ." ** Vocabulary: " dup .name cr
   follow  2>r                         ( r: test$ )
   begin  another?  while              ( acf )
      >name$                           ( this$ )
      2dup 2r@ search  if              ( this$ this$' )
         2drop ?cr type space          ( )
      else                             ( this$ this$' )
         2drop 2drop                   ( )
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
