\ Dr. Charles Eaker's case statement
\ Example of use:
\ : foo ( selector -- )
\   case
\     0  of  ." It was 0"   endof
\     1  of  ." It was 1"   endof
\     2  of  ." It was 2"   endof
\     ( selector) ." **** It was " dup u.
\   endcase
\ ;
\ The default clause is optional.
\ When an of clause is executed, the selector is NOT on the stack
\ When a default clause is executed, the selector IS on the stack.
\ The default clause may use the selector, but must not remove it
\ from the stack (it will be automatically removed just before the endcase)

\ At run time, the code compiled by OF tests the top of the stack against
\ the selector.  If they are the same, the selector is dropped and the
\ following Forth code is executed.  If they are not the same, execution
\ continues at the point just following the the matching ENDOF .

: case    ( -- 4 )  ?comp  csp @ !csp  4   ; immediate

: of      ( [ addresses ] 4 -- 5 )
   4 ?pairs
   compile over compile =  compile ?branch
   >mark compile drop
   5
; immediate

: endof   ( [ addresses ] 5 -- [ one more address ] 4 )
   5 ?pairs
   compile  branch     >mark
   swap  >resolve
   4
; immediate

: endcase ( [ addresses ] 4 -- )
   4 ?pairs
   compile drop
   begin  sp@  csp @  <>  while  >resolve  repeat
   csp !
; immediate
