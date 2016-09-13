\ See license at end of file
purpose: Convert date and time to DOS packed format

: >hms  ( dos-packed-time -- secs mins hours )
   dup h#   1f and      2*   swap  ( secs packed )
   dup h# 07e0 and      5 >> swap  ( secs mins packed )
       h# f800 and  d# 11 >>       ( secs mins hours )
;  
: hms>  ( secs mins hours -- dos-packed-time )
   d# 11 << h# f800 and swap      ( secs packed mins )
       5 << h# 07e0 and + swap    ( packed secs )
         2/ h# 001f and +         ( packed )
;
: >dmy  ( dos-packed-date -- day month year )
   dup h#   1f and          swap   ( day packed )
   dup h# 01e0 and  5 >>    swap   ( day month packed )
       h# fe00 and  9 >> d# 1980 + ( day month year )
;  
: dmy>  ( day month year -- dos-packed-date )
   d# 1980 -
   9 << h# fe00 and   swap    ( day packed month )
   5 << h# 01e0 and + swap    ( packed day )
        h# 001f and +         ( packed )
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
