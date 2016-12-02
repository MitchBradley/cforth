\needs voc-link,  : voc-link, lastacf voc-link link@  link,  voc-link link!  ;

also root definitions

: get-current  ( -- wid )  current token@  ;
: set-current  ( wid -- )  current token!  ;

: forth-wordlist  [ also forth ]  ['] forth  [ previous ]  ;
: wordlist  ( -- wid )
   " Xwid" $create
   #threads 0  do    origin link,  loop
   voc-link,
   lastacf
;
: /context  ( -- n )  #vocs /token *  ;
: set-order  ( wid1 .. widn n -- )
   context  /context  erase
   dup -1  =  if  only  exit  then
   0  do  context i ta+ token!  loop
;
: get-order  ( -- wid1 .. widn n )
   0
   context /context  +
   #vocs  0  do
      /token -  dup get-token?  if  rot 1+ rot  then
   loop
   drop
;
previous definitions
