\ See license at end of file
purpose: Driver for Armada 610/MMP2 keypad controller

: keypad-on  ( -- )
   5 h# 015018 io!  \ Clock on with reset asserted
   1 h# 015018 io!  \ Clock on, release reset
   1 ms
;
: kp!  ( n offset -- )  h# 012000 + io!  ;
: kp@  ( offset -- n )  h# 012000 + io@  ;
: keypad-direct-mode  ( #keys -- )
   1- 6 lshift  h# 202 or  0 kp!
;
: scan-keypad  ( -- n )
   0 kp@  h# 4000.0000 or  0 kp!
   1 ms
   8 kp@
;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
