purpose: Load builtin drivers
\ See license at end of file

hex
headers

false value probemsg?	\ Optional probing messages

\ >tmp$ copies the string to allocated memory.  This is necessary because
\ the loading of a driver may cause another driver to be loaded,
\ thus re-entering $load-dropin .

: >tmp$  ( $1 -- $2 )
   >r r@ alloc-mem    ( name-adr adr r: len )
   tuck r@ move       ( adr r: len )
   r>                 ( adr len )
;

\ any-drop-ins? and do-drop-in are fcode driver loading methods in
\ FirmWorks' OpenFirmware implementation.
\ The following code may have to be changed for other OpenFirmware
\ implementation, provided they have a special way of loading fcode
\ driver from system ROM.

\ If any-drop-ins? or do-drop-in is missing, eval will throw an error
\ that will be caught in $load-driver.

: did-drop-in?  ( name$ -- flag )
   2dup  any-drop-ins?              ( name$ flag )
   0=  if  2drop false  exit  then  ( name$ )

   probemsg?  if                                  ( name$ )
      ." Matched dropin driver "  2dup type  cr   ( name$ )
   then                                           ( name$ )

   do-drop-in  true
;

: $load-driver  ( name$ -- done? )
   >tmp$            ( name$' )

   2dup ['] did-drop-in?  catch  if  2drop false  then  ( name$' done? )

   -rot  free-mem   ( done? )
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
