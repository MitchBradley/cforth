\ See license at end of file
purpose: Interface methods for FAT file system package

private
false instance value file-open?
: free-device  ( -- )  current-device @ /device free-mem  ;

public

: open  ( -- okay? )
   /device alloc-mem  (set-device)
   current-device @ /device erase

   current-device @  drive !

   init-dir

   my-args " <NoFile>"  $=  if  true exit  then

   ['] ?read-bpb catch  if  free-device  false  exit  then

   my-args  ascii \ split-after                 ( file$ path$ )
   $chdir  if  free-device false  exit  then    ( file$ )

   \ Filename ends in "\"; select the directory and exit with success
   dup  0=  if  2drop  true exit  then          ( file$ )

   file @ >r  dos-fd file !                     ( file$ )

   2dup r/w $dosopen 0=  if                     ( file$ )
      2dup r/o $dosopen 0=  if                  ( file$ )
         r> file !                              ( file$ )
         $chdir  0=  if  true  exit  then       ( )
         ?free-fat-cache  free-bpb  free-fssector  free-device  false    exit
      then
   then            ( file$ file-ops ... )
   setupfd
   2drop
   true to file-open?
   true
   r> file !
;

: close  ( -- )
   file-open?  if
      dos-fd ['] fclose catch  ?dup  if  .error drop  then
   then
   ?free-fat-cache
   free-bpb
   free-fssector
   free-device
;
: read  ( adr len -- actual )
   dos-fd  ['] fgets catch  if  3drop 0  then
;
: write  ( adr len -- actual )
   tuck  dos-fd  ['] fputs catch  if  2drop 2drop -1  then
;
: seek   ( offset.low offset.high -- error? )
   dos-fd  ['] dfseek catch  if  2drop true  else  false  then
;
: size  ( -- d )  fh_length l@  0  ;
: load  ( adr -- size )  size drop read  ;

[ifdef] notdef
\ XXX we need to figure out what environment this runs in! open or not open
\ Creates an empty file with name "name".  The file still must be
\ opened if it is to be accessed. true = success, false = failure.
: $create  ( name$ mode -- flag )  
   3dup  dos-create  ?dup if  ( adr len mode [-2|-1|0>] )
      -1 = if  \ file exists, delete it first and try again
         2 pick 2 pick  $delete  if  ( adr len mode )
            3drop false
         else
            dos-create  0=   then
      else  3drop  false  then  \ i/o error or no space
   else 
      3drop true
   then
;
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
