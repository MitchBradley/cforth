\ See license at end of file
purpose: Interface methods for FAT file system package

private

0 instance value my-fh

: free-device  ( -- )  current-device @ /device free-mem  ;

0 instance value deblocker

public

: block-size  ( -- n )  1  ;   \ Variable-length so granularity is 1
: max-transfer  ( -- n )  /cluster  ;
: read-blocks  ( adr byte# #bytes -- #bytes-read )
   swap my-fh dos-seek  if  2drop 0 exit  then   ( adr #bytes )
   my-fh dos-read  if  0  then   ( #bytes-read )
;
: write-blocks  ( adr byte# #bytes -- #bytes-written )
   swap my-fh dos-seek  if  2drop 0 exit  then   ( adr #bytes )
   my-fh dos-write  if  0  then   ( #bytes-read )
;

: seek  ( d.offset -- okay? )
   deblocker  if
      " seek"  deblocker $call-method
   else
      2drop 0
   then
;
: read  ( addr len -- actual-len )
   deblocker  if
      " read"  deblocker $call-method
   else
      2drop 0
   then
;
: write ( addr len -- actual-len )
   deblocker  if
      " write" deblocker $call-method
   else
      2drop 0
   then
;
: size  ( -- d )
   deblocker  if
      " size" deblocker $call-method
   else
      0.
   then
;

: close  ( -- )
   deblocker  if  deblocker close-package  then
   ?free-fat-cache
   free-bpb
   free-fssector
   free-device
;

: open  ( -- okay? )
   /device alloc-mem   ( adr )
   dup /device erase   ( adr )
   dup (set-device)    ( adr )
   drive !             ( )

   init-dir

   my-args " <NoFile>"  $=  if  true exit  then

   ['] ?read-bpb catch  if  free-device  false  exit  then

   my-args  ascii \ split-after                      ( file$ path$ )
   $chdir  if  2drop  free-device false  exit  then  ( file$ )

   \ Filename ends in "\"; select the directory and exit with success
   dup  0=  if  2drop  true exit  then          ( file$ )

   2dup r/w  name-open  ( error? )  if          ( file$ )
      2dup r/o  name-open  ( error? )  if       ( file$ )
         $chdir  0=  if  true  exit  then       ( )
         close  false   exit                    ( -- false )
      then                                      ( file$ fh )
   then                                         ( file$ fh )
   to my-fh  2drop                              ( )

   " "  " deblocker"  $open-package  to deblocker
   deblocker  if  true  else  close false  then
;

: load  ( adr -- size )  size drop read  ;

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
