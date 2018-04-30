\ Defining words to construct Forth interfaces to C subroutines.
\ This uses the "ccall" primitive in the kernel, which contains a
\ mini-interpreter which does argument type conversion based
\ on an argument type string.  The argument type string is constructed
\ for each call by an argument specification list which looks a lot like
\ a Forth stack diagram.
\
\ Defines:
\
\ ccall:      ( subroutine-adr -- ) ( Input Stream: name arg-spec )

decimal
only forth also definitions

vocabulary ccalls
also ccalls definitions

\ Scan the argument specification list.  For each argument, add a character
\ to the argument specifier string.

\ Valid argument specifier characters are:
\ h	- host
\ i	- int
\ l	- long
\ a	- address
\ s	- string
\ --	- separates arguments from results
\ }	- terminates the list
: {  ( -- )
   0
   begin  safe-parse-word  drop c@  dup [char] - =  until
   drop    \ Get rid of the '-'
   \ Now the stack has the argument spec characters in reverse order
   \ Put the input argument specs characters in the parameter field
   begin  dup  while  c,  repeat  drop
   [char] - c,
   \ Now do the result spec characters in forward order
   begin  safe-parse-word drop c@  dup [char] } <>  while  c,  repeat
   0 c,
   drop align
   previous
;
forth definitions
: (ccall:)  \ name  { args } ( n -- )
   create , 0 here c!
   also ccalls
;
: ccall:  \ name  { args } ( entry# -- )
   (ccall:)
   does>  dup na1+ swap @ ccall
;
: acall:  \ name  { args } ( subroutine-adr -- )
   (ccall:)
   does>  dup na1+ swap @ acall
;

previous definitions

[ifdef] glop
: gcall:  ( n "name" -- )  create ,  does> @ glop   ;
[then]
