\ See license at end of file
\ Directory operations:
\ file and subdirectory creation, renaming, changing directory
\
\ TODO:
\   Allow renames across directory boundaries.
\   Media change handling (hard to actually implement due to crummy OMTI
\       floppy controller, but the hooks should be put in)

private

: set-file-name  ( ext-adr ext-len name-adr name-len -- )
   de_name d# 11 blank ( ext-adr ext-len name-adr name-len )
   de_name swap 8 min cmove  de_extension swap 3 min cmove ( )
;

: set-stamps  ( attributes -- )
   de_attributes c!
   0 de_length lel!
   now today (set-modtime)
   now today (set-createtime)
   today (set-accessdate)
;

public
: dos-create  ( adr len protection -- error? )
\ error? =  0 is success,
\          -1 means: couldn't create (no free entry or already exists),
\          0> means: error writing directory cluster.
   -rot        ( protection adr len )

   \ Error if the file already exists
   at_rdonly at_system or at_subdir or at_hidden or     ( protection )
   find-first if  drop true  exit  then                 ( protection )

   \ Create the file but don't open it
   find-free-dirent  if  drop true  exit  then          ( protection )

   base-ext be-len c@ base-name bn-len c@ set-file-name ( protection )
   set-stamps
   0 file-cluster!

   write-dir-cl    ( error? )  \ Flush directory cluster image to disk
;

private
: (dos-delete)  ( -- error? )   
\ dirent points to the file to be deleted !
   file-cluster@  ( 1st-cl# )         \ remember first cluster  
   0 file-cluster!  h# e5 de_name c!
   write-dir-cl   ( 1st-cl#  error? ) \ delete entry in directory cluster first
   swap  ?dup  if                     \ & from cluster table second (10/28/91)
      deallocate-clusters  then 
   ( error? )
;

public

\ This version will delete any file, even read-only, hidden, and system files
: $delete!  ( adr len -- error? )
   at_rdonly at_system or at_hidden or
   find-first  0=  if  true  exit  then    ( adr len )
   (dos-delete)  ( error? )
;
: $delete  ( adr len -- error? )
   0  find-first  0=  if  true  exit  then    ( adr len )
   (dos-delete)  ( error? )
;

private

\ Creates one of the "special" entries "." and ".."
: make-dotent  ( cluster# adr len -- )
   " " 2swap  set-file-name   ( cluster# )
   file-cluster!              ( )
   at_subdir set-stamps
;
: prime-directory  ( parent-cluster# my-cluster# my-dev -- error? )
   over swap 0 -rot  set-dirent             ( parent-cl# my-cl# error? )
   if  2drop true exit  then                ( parent-cl# my-cl# )

   \ Clear the first cluster.
   dirent @  /cluster  0 fill               ( parent-cl# my-cl# )

   \ Make the "." entry.
   " ."  make-dotent                        ( parent-cl# )

   \ Make the ".." entry.
   /dirent dirent +!                        ( parent-cl# )
   " .." make-dotent                        ( )

   write-dir-cl  ( error? )
;

public

: $mkdir  ( adr len -- error? )
   at_subdir dos-create  ?dup  if  exit  then

   \ Allocate a cluster for the directory entries.
   \ We don't want to just fault it in as though the directory were
   \ being extended, because we don't have an appropriate value for
   \ the de_first field to indicate this condition.  We could use
   \ fat-eof, but we would still have the problem that extend-dir
   \ would need to hook the new cluster to the head node instead of
   \ to a cluster link.  We might as well just do it here.

   \ Allocate the new cluster near the directory containing it
   search-cl @ allocate-cluster  ( cl# true | false )  if  ( cl# )
      ?flush-fat-cache             \ cpt - force to update FAT on device first
      dup file-cluster!
      \ ??? what should be done with the de_length field of a subdirectory?
      write-dir-cl ?dup if  exit  then
   else
      true exit
   then                         ( cl# )

   search-dir-cl @              ( subdir-cl# parent-dir-cl# )

   \ chdir to the new subdirectory
   dv_cwd-cl l@ -rot  ( old-curdir subdir-cl# parent-dir-cl# )
   over dv_cwd-cl l!  ( old-curdir subdir-cl# parent-dir-cl# )

   \ Clear the new directory and create the "." and ".." entries
   swap search-dev @ prime-directory    ( old-curdir error? )

   swap dv_cwd-cl l!            ( error? )
;

private

\ Returns true if current directory is empty.
: directory-empty?  ( -- flag )
   " *.*" 0 init-search  \ Attrib.s don't matter; next-file ignores them
   begin  next-file  while
      file-name  dup 2 >  if   2drop false  exit  then   ( adr len )
      dot-name? 0=  if  false  exit  then 
   repeat
   true
;

public

: $rmdir  ( addr len -- error? )
   at_subdir init-search
   begin  find-next  while
      de_attributes c@ at_subdir and  if   \ Found it

         \ Remember the current directory location
         dv_cwd-cl l@ dirent @ dir-buf -  dir-cl @ dir-dev @ ( cwd offs cl dev)

         \ Change to the directory to be deleted and see if it's empty
         file-cluster@ dv_cwd-cl l!  directory-empty?  >r    ( cwd offs cl dev)

         \ Go back to where we were
         set-dirent drop  ( cwd )   dv_cwd-cl l!
         r>  if  (dos-delete)  else  true  then  exit
      then
   repeat
   true
;

private

variable new-device  variable new-directory
8 buffer: new-name  3 buffer: new-ext

public

: $rename  ( old-adr old-len  new-adr new-len -- error? )
\ Complications:
\ We need to find the device and directory containing both the old file
\ and the new file.  The following cases are interesting (in order):
\  a) If the new file already exists, error.
\  b) If the files are on different devices, error.
\  c) If the files are in different directories, create a new directory
\     entry, copy the old dirent to the new place, delete old entry.
\  d) If the files are in the same directory, overwrite the file name field
\ A file may be identified by (device, dirent == (cluster,offset)), which is
\ the set of parameters used by set-dirent.  If the file doesn't exist,
\ the enclosing directory needs to be known; a directory is specified by
\ (device, starting-cluster)

   \ Error if the "new" file name already exists
   at_subdir  find-first  if  2drop true exit  then  ( old-adr,len )

   \ The "new" file doesn't already exist, but as a side effect of looking
   \ for it, we have processed the directory portion of the pathname.
   \ Save that directory and the final file name.
   search-dev @ new-device !  search-dir-cl @ new-directory ! ( old-adr,len )
   new-name 8 blank  new-ext 3 blank
   base-name new-name bn-len c@ cmove                ( old-adr,len )
   base-ext  new-ext  be-len c@ cmove                ( old-adr,len )

   at_subdir  find-first  if                         ( )

      \ If the new file and the old file are in the same directory, then
      \ all we have to do is to change the name.  Otherwise, we have to
      \ move the directory entry.

      search-dev @ new-device @ =  search-dir-cl @ new-directory @ = and  if
         new-ext 3  new-name 8  set-file-name
         write-dir-cl                                      ( error? )
      else
         \ We don't handle this case yet.  Here's what would be required:
         \ Make a temporary copy of the "old" dirent.  Remember the
         \ (device,cluster,offset) for the "old" dirent.  Select the
         \ "new" directory.  Allocate a new directory entry with
         \ "find-free-dirent".  Copy the temporary copy of the "old"
         \ dirent to the newly allocated dirent.  write out that cluster.
         \ Switch back to the old dirent and mark it free.
         true
      then
   else
      true
   then
;

external

: $chdir  ( adr len -- error? )
   dup 0=  if   2drop false  exit   then  \ Bail out early if null argument

   2dup at_subdir init-search   ( adr len )

   \ If the pathname search failed, we give up immediately
   search-dir-cl @ cl#eof = if  2drop true  exit  then

   \ If the pathname ends with a backslash or colon character, we won't
   \ actually perform the search; instead we'll just use the directory that
   \ was found as part of the search initialization

   1- + c@  dup ascii \ =  swap ascii : = or  if
      search-dev @ dup drive ! set-device
      search-dir-cl @ dv_cwd-cl l!  false  exit
   then

   find-dir  if
      search-dev @ dup drive ! set-device
      file-cluster@ dv_cwd-cl l!  false
   else
      true
   then
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
