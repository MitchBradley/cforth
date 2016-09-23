\ See license at end of file
purpose: Miscellaneous Tools

\ random numbers
here value seed
: random   ( -- u )   seed  h# 107465 *  h# 234567 +  dup to seed  ;
\ : choose   ( n -- u )   ( 0 <= u < n )   random um* nip  ;
random value magic

\ manage data fields
: getc   ( a1 -- a2 c )   count  ;
: gets   ( a1 n -- a2 a1 )   over + swap  ;
: getw   ( a1 -- a2 w )   dup wa1+ swap be-w@  ;
: getl   ( a1 -- a2 l )   dup la1+ swap be-l@  ;
: putc   ( a1 c -- a2 )   over c! 1+  ;
: puts   ( a1 a n -- a2 )   bounds  ?do  i c@ putc  loop  ;
: putw   ( a1 w -- a2 )   over be-w! wa1+  ;
: putl   ( a1 l -- a2 )   over be-l! la1+  ;

\ using a pointer variable...
: putchar   ( c p -- )   tuck @ c!     1 swap +!  ;
: putshort  ( w p -- )   tuck @ be-w!  2 swap +!  ;
: putlong   ( l p -- )   tuck @ be-l!  4 swap +!  ;

\ Add Header fields to a packet.
: makeheader   ( proto a1 -- a2 )   h# ff03 putw  swap putw  ;

\ stubs
: ppp_send_config	4drop  ;
: ppp_recv_config	4drop  ;
: ppp_set_xaccm	drop  ;


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
