\ See license at end of file
purpose: Implements the script and its editor

headers

" " 0 config-string nvramrc

false config-flag use-nvramrc?

headerless

0 value nvramrc-buffer	\ Buffer for editing nvramrc
0 value nvramrc-size	\ Current size of file being edited in memory
: /nvramrc-max  ( -- #bytes )  nvramrc nip   cv-unused +  ;

: deallocate-buffer  ( -- )
   nvramrc-buffer  if
      nvramrc-buffer /nvramrc-max free-mem
   then
   0 is nvramrc-buffer
   0 is nvramrc-size
;
: allocate-buffer  ( -- )
   nvramrc-buffer 0=  if
      /nvramrc-max alloc-mem is nvramrc-buffer
      nvramrc-buffer /nvramrc-max erase
      nvramrc is  nvramrc-size  ( adr )
      nvramrc-buffer nvramrc-size cmove   ( cmove? )
   then
;   

headers
\ Returns address and length of edit buffer
: nvbuf  ( -- adr len )   nvramrc-buffer nvramrc-size ;

\ Allows you to recover the contents of the nvramrc file if its size
\ has been set to 0 by set-defaults. (NOT IMPLEMENTED)
: nvrecover  ( -- )  true abort" Nothing to recover"  ;   

\ Stop editing nvramrc, discarding the changes
: nvquit  ( -- )
   ." Discard edits [y/n]? "
   key dup emit cr  upc ascii Y  =  if  deallocate-buffer  then
;

\ Execute the contents of the nvramrc edit buffer
: nvrun  ( -- )  nvbuf interpret-string  ;

\ Copy the contents of the nvramrce edit buffer back into the NVRAM,
\ and deallocate the edit buffer.
: nvstore  ( -- )
   nvramrc-buffer if
      nvbuf to nvramrc
      deallocate-buffer
   then
;

\ Begin or continue editing nvramrc
: nvedit  ( -- )
   allocate-buffer
   [ also hidden ]
   nvbuf /nvramrc-max edit-file  is nvramrc-size
   [ previous ]

   " Store script to NVRAM"  confirmed?  if
      nvstore
      use-nvramrc?  0=  if
         " Enable script"  confirmed?  if  true to use-nvramrc?  then
      then
   then
;

headerless

: execute-nvramrc  ( -- )
   " nvramrc-" do-drop-in
   use-nvramrc?  if  nvramrc interpret-string  then
   " nvramrc+" do-drop-in
;
headers
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
