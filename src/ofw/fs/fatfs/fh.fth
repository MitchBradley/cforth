\ See license at end of file
\ DOS file handle.  There is one of these for each open file.

\ Logical cluster numbers are relative to the start of the file.
\ Physical cluster numbers are relative to the start of the partition.

hex

private

instance variable  fh

: hfield  (s handle-offset size -- handle-offset+size )
   create over , + does> @ fh @ +
;

struct \ fh
  /n hfield fh_dev        \ Device # where file lives
  /n hfield fh_dircl      \ Cluster # of directory entry
                          \ Must be long because we must encode both
                          \ negative root directory sector number and
                          \ unsigned 16-bit cluster numbers
  /l hfield fh_first      \ First cluster number of file
  /l hfield fh_length     \ #bytes in file
  /l hfield fh_logicalcl  \ Current position - logical cluster#
  /l hfield fh_physicalcl \ Current position - physical cluster#
  /l hfield fh_prevphyscl \ Predecessor of current physical cluster#
   2 hfield fh_diroff     \ Offset of directory entry within its cluster
   2 hfield fh_clshift    \ Shift count to convert from position to cl#
   2 hfield fh_flags

       0001 constant fh_isopen
       0002 constant fh_writeable
       0004 constant fh_dirty

   /l round-up
constant /fh

\ Releases the current file handle
: clear-fh  ( -- )  fh @ /fh free-mem  ;

\ Allocates a free file handle if possible
: allocate-fh  ( -- fh true  |  false )
   /fh alloc-mem fh !  fh @  if  fh @ true  else  false  then
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
