also root definitions

: get-current  ( -- wid )  current @  ;
: set-current  ( wid -- )  current !  ;

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
   0  do  context i ta+ !  loop
;
: get-order  ( -- wid1 .. widn n )
   0
   context /context  +
   #vocs  0  do
      /token -  dup token@  ?dup  if  -rot  swap 1+ swap  then
   loop
   drop
;
previous definitions
