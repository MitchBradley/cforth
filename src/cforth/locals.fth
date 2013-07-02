\ Implementation of ANS Forth Local Variables.

variable to?  to? off

: do-local  ( local# -- )
   postpone literal
   to? @  if  postpone set-local  else  postpone get-local  then
   to? off
;

\ This is the word defined in Basis
: (local)  ( adr len -- )
   dup  if
      #ins @  ['] do-local local-name
   else
      2drop
      #ins @  postpone literal   postpone allocate-locals
   then
;

warning @ warning off
\ Redefine TO to handle the local variable case also
: to  ( "name" [ val ] -- )	\ val is present only in interpret state
   >in @ >r  '  r> >in !             ( xt )	\ Peek at next name
   ['] do-local-name token@  =  if          \ Do the local variable thing
      to? on                         ( )
   else						\ Call the old version
      postpone to
   then
; immediate
warning !

\ Greg Bailey's syntax

: local  ( "name" -- )  parse-word (local)  ; immediate
: end-locals  ( -- )  0 0 (local)  ; immediate
: example  ( n -- n n^2 n^3 )  local n end-locals n dup n * dup n * ;

\ Creative Solution's Syntax

: locals|  ( "name ... name |" -- )
   begin
      parse-word  over c@  [char] | -  over 1 - or
   while
      (local)
   repeat
   2drop  0 0 (local)
; immediate
: x1  ( n -- n n^2 n^3 )  locals| n |  n  dup n *  dup n *  ;


\ Bradley Forthware's Syntax, with "ins" and "locals", but not "outs"
variable local#
d# 32 8 * buffer: locnames
: >locname  ( n -- adr )  d# 32 *  locnames +  ;

variable ;seen?
variable -seen?
: save-local  ( adr len -- )
   -seen? @  if                                ( adr len )  \ output
      2drop                                    ( )
   else                                        ( adr len )  \ scratch or input
      ;seen? @  if  postpone false  then       ( adr len )  \ scratch
      local# @  >locname  place  1 local# +!   ( )
   then
;
: declare-locals  ( -- )	\ Declare locals in reverse order
   local# @  ?dup  if
      begin  ?dup  while  1- dup >locname count  (local)  repeat
      0 0 (local)
   then 
;

: {  ( "name ... ; name ... -- name ... }" -- )
   -seen? off  ;seen? off  local# off
   begin
      parse-word
      over c@  case
         [char] }  of             2drop true   endof
         [char] ;  of  ;seen? on  2drop false  endof
         [char] -  of  -seen? on  2drop false  endof
            false swap 2swap  save-local              ( false char )
      endcase                                         ( }-seen? )
   until                                              ( )
   declare-locals
; immediate
: x2  { n -- }  n  dup n *  dup n *  ;
