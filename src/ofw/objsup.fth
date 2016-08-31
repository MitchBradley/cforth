: $?missing  (   ( +-1 | adr len 0 -- +-1 )
   dup 0=  if  drop  .not-found  ( -13 ) abort  then
;
: used  ( xt -- )  lastacf token!  ;

\ Code field for an object action.
: doaction  ( -- )  acf-align  colon-cf  ;

\ Returns the address of the code executed by the word whose code field
\ address is acf
: >code-adr  ( acf -- code-adr )  token@  ;


\ place-does is a no-op because CForth implements does> clauses without
\ needing a little piece of in-line code .
: place-does  ( -- )  ;

: >action-adr  ( xt action# -- xt action# #actions true  | 'body action-adr false )
   over token@                   ( xt action# code-adr )
   2dup -1 na+ @                 ( xt action# code-adr action# #actions )
   >  if                         ( xt action# code-adr )
      -1 na+ @  true             ( xt action# #actions true )
   else                          ( xt action# code-adr )
      rot >body -rot             ( 'body action# code-adr )
      swap 1+ negate na+ token@  ( 'body action-adr )
      false                      ( 'body action-adr false )
   then
;
: action-name  \ name  ( action# -- )
   create ,		\ Store action number in data field
   does>      ( 'body -- <method-executed> )
   @                             ( action# )
   r> dup token@  swap ta1+ >r   ( action# object-xt )
   dup >body -rot                ( object-body action# object-xt )
   token@                        ( object-body action# 'object-struct )
   swap 1+ negate ta+ token@     ( object-body action-xt )
   execute                          
;

: >action#  ( apf -- action# )  @  ;
