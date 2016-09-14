only forth also hidden also definitions
decimal
headerless

variable sift-vocabulary

variable sift-string

headers

\ Leave a "hook" for showing the name of the vocabulary
\ only once, the first time a matching name is found.
\ Showing the name of a device can be plugged in here also...
defer .voc     ' noop is .voc

: .in  ( -- )  ??cr tabstops @ spaces  ." In "  ;

headerless
: .vocab  ( -- )
   .in ['] vocabulary .name space
   sift-vocabulary @ .name cr
   ['] noop is .voc
;

\ Show the "sifted" name, preceded by its  cfa  in parentheses.
\ Show the name of the vocabulary only the first time.
\ Control the display with  exit?
: .sift?  ( xt -- exit? )
   .voc
   exit? tuck  if  drop exit  then 		( exit? xt )
   ?cr                             		( exit? xt )
   dup  ." (" (u.) type ." ) "                  ( exit? xt )
   .name  2 spaces                              ( exit? )
;

\ Sift through the given vocabulary, using the sift-string given.
\ Control the display with  exit?
: vsift?  ( adr len voc-xt -- adr len exit? )
   dup sift-vocabulary !  follow   2>r          ( r: test$ )
   begin  another?  while			( xt )
      dup >name$         			( xt this$  r: test$ )
      2r@ search  nip nip  if                   ( xt  r: test$ )
         .sift?  if  2r> true exit  then        ( xt  r: test$ )
      else                                      ( xt  r: test$ )
         drop                                   ( r: test$ )
      then                                      ( r: test$ )
   repeat                                       ( r: test$ )
   2r> false
;

forth definitions
: $sift  ( adr len -- )
   voc-link  begin  another-link?  while  ( adr len voc-xt )
      ['] .vocab is .voc                          ( adr len voc-xt )
      >r r@ vsift?  if  r> 3drop exit  then       ( adr len r: voc-xt )
      r> >voc-link                                ( adr len )
   repeat                                         ( adr len )
   2drop                                          ( )
;
: sifting \ name ( -- )
   safe-parse-word $sift
;
only forth also definitions
