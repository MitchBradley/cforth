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
\ Test:
\ : x1  ( n -- n n^2 n^3 )  locals| n |  n  dup n *  dup n *  ;


\ Bradley Forthware's Syntax, with "ins" and "locals", but not "outs"
0 value locnames
0 value last-locname

variable ;seen?
variable -seen?
: save-local  ( adr len -- )
   -seen? @  if                                ( adr len )  \ output
      2drop                                    ( )
   else                                        ( adr len )  \ scratch or input
      ;seen? @  if  postpone false  then       ( adr len )  \ scratch
     tuck last-locname place                   ( len )
     1+ last-locname + to last-locname         ( )
   then
;

: -locname  ( -- adr len )
    begin  -1 last-locname +!  last-locname @ c@ #32 <  until
    last-locname @ count
;
: declare-locals  ( -- )
   last-locname locnames <>  if   ( )
      last-locname   begin        ( adr )
         1-  dup c@ #32 <  if     ( adr' )
            dup count (local)     ( adr )
         then                     ( adr )
         dup locnames =           ( adr )
      until                       ( adr )
      drop                        ( )
      0 0 (local)                 ( )
   then                           ( )
;

: {  ( "name ... ; name ... -- name ... }" -- )
   -seen? off  ;seen? off
   here #20 na+ to locnames
   locnames to last-locname
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
\ Test:
\ : x2  { n -- }  n  dup n *  dup n *  ;
