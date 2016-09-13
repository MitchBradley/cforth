\ See license at end of file
purpose: Enumerate directory entries

private

\ Convert DOS file attributes to the firmware encoding
\ see showdir.fth for a description of the firmware encoding
: >canonical-attrs  ( dos-attrs -- canon-attrs )
   >r
   \ Access permissions
   r@     1 and  if  o# 666  else  o# 777  then \ rwxrwxrwx

   \ Bits that are independent of one another
   r@     2 and  if  h# 10000 or  then		\ hidden
   r@     4 and  if  h# 20000 or  then		\ system
   r@ h# 20 and  if  h# 40000 or  then		\ archive

   \ Mutually-exclusive file types
   r@     8 and  if  h#  3000 or  then		\ Volume label
   r> h# 10 and  if  h#  4000 or  then		\ Subdirectory
   dup h# f000 and  0=  if  h# 8000 or  then	\ Ordinary file	
;

public
: file-info  ( -- s m h d m y len attributes name$ )
   file-time  file-date  file-size  file-attributes >canonical-attrs
   file-name
;

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup 0=  if  0 0 0 set-search  then  ( id )
   next-file  if                       ( id )
      1+  file-info  true
   else
      drop false
   then
;
: $create  ( adr len -- error? )  h# 20 dos-create  ;  \ Set archive bit
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
