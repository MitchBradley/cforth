\ See license at end of file
purpose: Internal interfaces to memory node operations

headers
variable memory-node   ' memory-node  " memory" chosen-variable

: $call-mem-method ( ??? method$ -- ???  )  memory-node @  $call-method  ;

: mem-claim  ( [ phys.. ] size align -- base.. )  " claim" $call-mem-method  ;
: mem-release  ( phys.. size -- )  " release" $call-mem-method  ;
: mem-mode  ( -- mode )  " mode" $call-mem-method  ;

\ get-memory can be used by init-program modules instead of mem-claim
\ to avoid the need to know system-specific details
: get-memory  ( adr len -- )
[ '#adr-cells @ 2 = ] [if]
   0 swap  0 mem-claim 2drop
[else]
   0 mem-claim drop
[then]
;
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
