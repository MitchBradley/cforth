\ See license at end of file

\ Action definition for multiple-code-field words.
\ Data structures:
\   nth-action-does-clause   acfs  unnest
\   n-1th-action-does-clause acfs  unnest
\   ...
\   1th-action-does-clause acfs  unnest
\   nth-adr
\   n-1th-adr
\   ...
\   1th-adr
\   n
\   0th-action-does-clause acfs  unnest
\   object-header  build-acfs
\   (') 0th-adr uses

\ Object data structure:
\
\ Created by object defining words (actions, action:, etc):
\
\   tokenN-1  tokenN-1   ...    token1   #actions  (does-clause) ...
\   |________|________|________|________|________|________
\                                                ^
\                                                |
\                     ___________________________|
\                    |
\ Object instance:   |
\                    |
\   name  link  code-field  parameter-field
\               ^           ^
\               |           |
\            object-acf  object-apf

needs doaction objsup.fth	\ Machine-dependent support routines

decimal
headerless

0 value action#
0 value #actions
0 value action-adr
headers
: actions  ( #actions -- )
   is #actions
   #actions 1- /token * na1+ allot    ( #actions )   \ Make the jump table
   \ The default action is a code field, which must be aligned
   align acf-align  here is action-adr
   0 is action#
   #actions  action-adr /n -  n!
;
headerless
\ Sets the address entry in the action table
: set-action  ( -- )
   action#  #actions  >= abort" Too many actions defined"
   lastacf  action-adr  action# /token * -  /n -  token!
;
headers
: action:  ( -- )
   action# if   \ Not the default action
      doaction set-action
   else \ The default action, like does>
      place-does
   then

   action# 1+ is action#
   !csp
   ]
;
: use-actions  ( -- )
   state @  if
      compile (')  action-adr  token,  compile used
   else
      action-adr  used
   then
; immediate

headerless
: .object-error
   ( object-acf action-adr false  |  acf action# #actions true -- ... )
   ( ... -- object-acf action-adr )
   if
      ." Unimplemented action # " swap .d  ." on object " swap .name
      ." , whose maximum action # is " 1- .d cr
      abort
   then
;

headers

\ Executes the numbered action of the indicated object
\ It might be worthwhile to implement perform-action entirely in code.

: perform-action  ( object-acf action# -- )
   dup if
      >action-adr .object-error  ( object-apf action-adr )
      execute
   else
      drop execute
   then
;

warning @ warning off
1 action-name to
2 action-name addr
warning !

\ Add these words to the decompiler case tables so that the
\ debugger will display their arguments and so that the decompiler
\ will not show the action name and its argument on separate lines
\ if it happens to be near the end of a line.

[ifdef] install-decomp
also hidden also
: .action  ( ip -- ip' )
   d# 15 ?line  \ Just a guess
   dup token@ >name name>string cr". space ta1+
   .compiled
;
' to   ' .action  ' skip-(')  install-decomp
' addr ' .action  ' skip-(')  install-decomp
previous previous
[then]

: ?has-action  ( object-acf action-acf -- object-acf action-acf )
   2dup >body >action# >action-adr .object-error  2drop
;
: action-compiler:  \ name  ( -- )
   parse-word  2dup $find  $?missing drop  \ adr len xt
   -rot $create  token,  immediate
   does>             ( apf )
      ' swap token@  ( object-acf action-acf )
      ?has-action    ( object-acf action-acf )
      +level         ( apf )	\ Enter temporary compile state if necessary
      compile,		\ Compile run-time action-name word
      compile,		\ Compile object acf
      -level		\ Exit temporary compile state, perhaps run word
;

also hidden
[ifdef] object-definer
: (object-definer)  ( action-acf -- definer )
   dup /n -  @                 ( action-acf #actions )
   1- /token * - /n -  token@  ( last-action-acf )
   ta1+                        ( adr )

   taligned
   begin
      dup in-dictionary?  0=  if  drop ['] lose  exit  then
      ta1+  dup  probably-cfa?
   until
;
' (object-definer) is object-definer
[then]
previous

warning @ warning off
\ action-compiler: to
action-compiler: addr
warning !


\ Makes "is" and "to" synonymous.  "is" first checks to see if the
\ object is of one of the kernel object types (which don't have multiple
\ code fields), and if so, compiles or executes the "(is) <token>" form.
\ If the object is not of one of the kernel object types, "is" calls
\ "to-hook" to handle the object as a multiple-code field type object.

warning @ warning off
: (to-hook)  ( [data] acf -- )  +level  compile to  compile, -level  ;
' (to-hook) is to-hook
alias to is
warning !

\ 3 actions
\ action:  @  ;
\ action:  !  ; ( is )
\ action:     ; ( addr )
\ : value  \ name  ( initial-value -- )
\    create ,
\    use-actions
\ ;

3 actions
action: >user 2@ ;
action: >user 2! ;
action: >user    ;
: 2value-cf  create-cf use-actions  ;
: 2value  ( n1 n2 "name" -- )  header 2value-cf  2 /n* user#,  2!  ;

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
