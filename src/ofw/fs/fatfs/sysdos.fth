\ See license at end of file
\ DOS file interface

hex

private

\ Protection to be assigned to newly-created files
\ Defaults to unprotected

\ variable file-protection

\ Interfaces between the buffering code and the lower level operating
\ system code.  This is the stuff that has to be reimplemented to port
\ to a different operating system.

\ Rounds down to a block boundary.  This causes all file accesses to the
\ underlying operating system to occur on disk block boundaries.  Some
\ systems (e.g. CP/M) require this; others which don't require it (e.g. GEM)
\ usually run faster with alignment than without.  It is required for
\ the Forth DOS file system, which only handle cluster-sized chunks
\ at the low level, depending on the higher level buffering to handle
\ the fragments.

: dosdfalign  ( d.byte# 'fh -- d.aligned )
   drop swap /cluster 1- invert and  swap
;

: dosdflen   ( 'fhandle -- d.size )  fh !  fh_length l@  0  ;

: dosdfseek  ( d.byte# 'fh -- )  nip dos-seek  abort" dosdfseek failed"  ;

: dosfread   ( addr count 'fh -- #read )  dos-read  abort" dosfread failed"  ;

: dosfwrite  ( addr count 'fh -- #written )  dos-write  if  0  then  ;

: dosfclose  ( 'fh -- )
   dos-close abort" dosfclose failed"
   bfbase @  /cluster free-mem
;

: $dosopen  ( adr len mode -- ... )
   dup >r  name-open  ( error? )  if
      false
   else
[ifndef] dos-fd
\ In the context of the file system reading support package, a buffer
\ hasn't been previously allocated.
      bfbase @ /fbuf free-mem
[then]
      /cluster alloc-mem /cluster initbuf
      r@  ['] dosdflen  ['] dosdfalign  ['] dosfclose  ['] dosdfseek
      r@ read  =  if  ['] nullwrite  else  ['] dosfwrite  then
      r@ write =  if  ['] nullread   else  ['] dosfread   then
      true
   then
   r> drop
;
[ifdef] dos-ui
: dosopen  ( name mode -- ...)
   ( ... -- fid sizeop alignop closeop seekop writeop readop true  | false )
   >r  count  r> $dosopen
;

\ Creates an empty file with name "name".  The file still must be
\ opened if it is to be accessed. true = success, false = failure.
: dosmake  ( name -- flag )  
   count
   2dup file-protection @  dos-create  ?dup if  ( adr len [-2|-1|0>] )
      -1 = if  \ file exists, delete it first and try again ***
         2dup  $delete  if  ( adr len )
            2drop false
         else
            file-protection @  dos-create  0=   then
      else  2drop  false  then  \ i/o error or no space  *** 10/28/91
   else 
      2drop true
   then
;

\ Installs DOS filing in basic file I/O.
: install-dos-files  ( -- )
   0 is file-protection  \ no special protection
   ['] dosopen  to do-fopen
   ['] dosmake  to make
;
[then]

[ifdef] notdef
\ Removes DOS filing from basic file I/O.
: unload-dos-files  ( -- )
   o# 664 is file-protection \ rw-rw-r--
   ['] sys_fopen  to do-fopen
   ['] sys_make   to make
;
[then]

[ifdef] dos-ui
public

warning @ warning off
: stand-init  ( -- )  stand-init  install-dos-files  ;
warning !
[then]

[ifdef] notdef
public
\ ** cpt 10/30/90: added fast dos I/O words. RESTRICTION: they are  
\ good only for ONE SHOT (whole) I/O after the file is opened/created.
\ Fclose must be called after this calls.
\ file handle pointing is based on current Kernel 'fd' field offset (32) !

: fread   ( addr count 'fd -- #read )  d# 32 + @ dosfread  ;

: fwrite  ( addr count 'fd -- )        d# 32 + @ dosfwrite drop  ;
[then]
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
