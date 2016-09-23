\ See license at end of file
purpose: File-based "NVRAM" driver package

dev /
new-device

" file-nvram" device-name

h# 1000 value /nvram

0 instance value nvram-fd
0 instance value nvram-ptr

headerless

: def-name  ( -- filename$ )  " nvram.dat"  ;
defer nv-file  ' def-name to nv-file

: nvopen  ( -- okay? )
   nv-file r/w open-file  0=  if  ( fid )
      to nvram-fd  true exit      ( -- okay? )
   then                           ( fid )
   drop                           ( )

   \ Try to make the file
   nv-file r/w create-file  if  drop false exit  then   ( )
   nv-file r/w open-file if  drop false exit  then      ( fid )
   to nvram-fd                                          ( )
   /nvram allocate  if  drop false exit  then           ( adr )
   dup /nvram erase                                     ( adr )
   dup /nvram nvram-fd write-file drop                  ( adr )
   free drop                                            ( )
   0. nvram-fd reposition-file 0=                       ( okay? )
;
: update-ptr  ( len' -- len' )  dup nvram-ptr +  to nvram-ptr  ;
: clip-size  ( adr len -- adr len' )	\ data buffer
   nvram-ptr +   /nvram min  nvram-ptr -     ( adr len' )
;

headers

: open  ( -- okay? )   true  ;
: close  ( -- )  ;
: seek  ( d.offset -- status )
   0<>  over /nvram u>  or  if
      drop  0 to nvram-ptr  true exit	\ Seek offset too large
   then
   to nvram-ptr   false
;
: read  ( adr len -- actual )
   nvopen if
      clip-size     ( adr len )
      nvram-ptr u>d  nvram-fd reposition-file drop  ( adr len )
      nvram-fd read-file drop                       ( actual-len )
      nvram-fd close-file drop                      ( actual-len )
      update-ptr                                    ( actual-len )
   else
      2drop 0
   then
;
: write  ( adr len -- actual )
   nvopen if
      clip-size  ( adr len )
      nvram-ptr u>d  nvram-fd reposition-file drop  ( adr len )
      tuck nvram-fd write-file drop                 ( len )
      nvram-fd close-file drop                      ( len )
      update-ptr                                    ( len )
   else
      2drop 0
   then
;
: size  ( -- d )  /nvram 0  ;
: nvram@  ( offset -- n )
   0 seek drop   here 1 read if  here c@  else  0  then 
;
: nvram!  ( n offset -- )
   0 seek drop   here c!   here 1 write drop
;

finish-device
device-end

: nvr@   ( offset -- n )   " nvram@" nvram-node $call-method  ;
: nvr!   ( n offset -- )   " nvram!" nvram-node $call-method  ;
' nvr@ to nv-c@
' nvr! to nv-c!

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
