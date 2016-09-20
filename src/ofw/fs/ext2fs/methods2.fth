\ See license at end of file
purpose: Linux ext2fs file system package methods

decimal

0 instance value modified?
0 instance value deblocker
0 instance value read-only?

external

: free-bytes  ( -- d )  d.total-free-blocks bsize du*  ;

: $create   ( name$ -- error? )
   o# 100666 ($create)
;

: $mkdir   ( name$ -- error? )
   dirent-vars 2>r 2>r                          ( name$ )
   2dup $find-file                              ( name$ error? )
   2r> 2r> restore-dirent                       ( name$ error? )
   0=  if  2drop true exit  then                ( name$ )

   o# 40777 ($create) if  true exit  then

   dirent-inode@ set-inode

   u.add-block					( u.block# )
   dfile-size h# 400. d+ dfile-size!		( u.block# )
   dup direct0 int! update			( u.block# )
   u>d d.block bsize erase update  \  flush	( )
   inode# first-dirent  if  true exit  then	( )
   " ."  bsize	inode#	fill-dirent		( )
   " .." wd-inum  new-dirent			( error? )
   diroff off
;

0 instance value renaming?
: $delete   ( name$ -- error? )
   $resolve-path  if  true exit  then		( )

   \ It's okay to delete a directory if it is a rename, because a
   \ hardlinked copy has just been made
   renaming? 0=  if
      wf-type dir-type =  if  true exit  then
   then

   dirent-unlink
   false
;
: $delete!  $delete ;			\ XXX should these be different?

: $hardlink  ( old-name$ new-name$ -- error? )
   \ Save the current search context.  The path part of the new name
   \ has already been parsed out and resolved.  Resolving old-name$ changes
   \ the directory context, so we will need to restore the context for the
   \ new name to create its dirent.
   dirent-vars 2>r 2>r                            ( old-name$ new-name$ r: 4xVars )

   \ Error if the new name already exists
   2dup $find-file  0=  if                        ( old-name$ new-name$ r: 4xVars )
      2r> 2r> 4drop                               ( old-name$ new-name$ )
      4drop true exit                             ( -- true )
   then                                           ( old-name$ new-name$ )

   2swap $find-file  if                           ( new-name$ r: 4xVars )
      2r> 2r> 4drop                               ( new-name$ )
      2drop  true  exit                           ( -- true )
   then                                           ( new-name$ r: 4xVars )

   \ Hard links to directories mess up the filesystem tree, but they are
   \ okay temporarily if we are renaming and will soon delete the old one
   renaming? 0=  if
      wf-type dir-type =  if                      ( new-name$ r: 4xVars )  
         2r> 2r> 4drop                            ( new-name$ )
         2drop  true exit                         ( -- true )
      then                                        ( new-name$ r: 4xVars)
   then

   2r> 2r> restore-dirent	                  ( new-name$ )
   wf-inum  new-dirent                            ( error? )
;

: $rename  ( old-name$ new-name$ -- error? )
   \ If new-name$ is null, the destination is a directory (which has
   \ already been located), so we set the destination filename to be
   \ the same as the filename component of the old path.
   dup 0=  if                            ( old-path$ new-name$ )
      2drop                              ( old-path$ )
      2dup [char] \  right-split-string  ( old-path$ name$ dir$ )
      2drop                              ( old-path$ new-name$ )
   then                                  ( old-path$ new-name$ )

   true to renaming?                     ( old-path$ new-name$ )
   2over 2swap  $hardlink  if            ( old-path$ )
      false to renaming?                 ( old-path$ )
      2drop true exit                    ( -- true )
   then                                  ( old-name$ )
   $delete                               ( error? )
   false to renaming?                    ( old-path$ )
;

: $rmdir   ( name$ -- error? )
   $find-file  if  true exit  then		( )
   wf-type dir-type <>  if  true exit  then     ( )

   \ Now the dirent is the one for the directory to delete and the
   \ inode is for the parent directory

   dirent-inode@ >r                             ( r: dir-i# )

   \ First verify that the directory to delete is empty
   dirent-vars                                  ( 4xVars r: dir-i# )
   r@ empty-dir?  0=  if  r> drop  4drop true exit  then
   restore-dirent                               ( r: dir-i# )

   \ Remove the dirent from the parent directory; the inode will not
   \ be freed yet because its link count is still nonzero due to the
   \ directory's "." entry.
   dirent-unlink                                ( r: dir-i# )

   \ First delete the ".." entry
   " .." r@ $find-name  if                      ( r: dir-i# )
      ." Corrupt filesystem - directory does not have .. entry" cr
      r> drop  true  exit
   then                                         ( r: dir-i# )
   dirent-unlink                                ( r: dir-i# )

   \ Then delete the "." entry
   \ The link count should go to 0, freeing the directory blocks
   " ." r@ $find-name  if                       ( r: dir-i# )
      ." Corrupt filesystem - directory does not have . entry" cr
      r> drop  true  exit
   then                                         ( r: dir-i# )
   dirent-unlink                                ( r: dir-i# )

   r> drop                                      ( )

   false
;

headers

\ EXT2FS file interface

external

: current-#blocks  ( -- n )  dfile-size d>u  ;
: block-size  ( -- n )  1  ;  \ Variable length; use max-transfer for buffer size
: max-transfer  ( -- n )  bsize  ;

\ Since blocks-size is 1, the argument values are in bytes
: read-blocks  ( adr byte# #bytes -- #bytes-read )
   bsize <> abort" Bad size for ext2fs read-blocks"  ( adr byte# )
   dup u>d                                           ( adr byte# d.byte# )
   dfile-size d>=  if                                ( adr byte# )
      \ Can't read past end of file
      2drop 0			                     ( #bytes-read )
   else			                             ( adr byte# )
      bsize /mod                                     ( adr residue block# )
      swap abort" Unaligned byte# in ext2fs read-blocks"  ( adr block# )
      tuck j-read-file-block		             ( block# )
      bsize um*                                      ( d.block-start )
      dfile-size  2swap d-  d>u                      ( remaining )
      bsize umin                                     ( #bytes-read )
   then
;
: write-blocks  ( adr byte# #bytes -- #bytes-written )
   read-only?  if    ( adr byte# #bytes )
      ." Not writing to the ext2 filesystem because of unsupported extensions" cr
      3drop 0  exit  ( -- #bytess-written )
   then              ( adr byte# #bytes )

   dup bsize > abort" Bad size for ext2fs write-blocks"	( adr byte# #bytes )

   over + u>d                                           ( adr byte# d.end-byte# )
   2dup  dfile-size d>  if                              ( adr byte# d.end-byte# )
      dfile-size!	\ extending file		( adr byte# )
   else							( adr byte# d.end-byte# )
      2drop		\ not extending file		( adr byte# )
   then							( adr byte# )
   bsize /mod  swap abort" Unaligned byte# in ext2fs-write-blocks"  ( adr block# )
   write-file-block					( )

   true to modified?                                    ( )
\   flush					\ XXX kludge for tests
   1                                                    ( #bytes-written )
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
   deblocker  if
      modified? if
         false to modified?
         time&date >unix-seconds dirent-inode@ set-inode ctime!
      then
      deblocker close-package
      update-gds
      flush
      release-buffers
      free-overlay-list
   then
;

: $ext2fsopen  ( adr len mode -- okay? )
   -rot $find-file  if  drop false exit  then	        ( mode )
   wf-type regular-type <>  if  drop false exit  then   ( mode )
   dirent-inode@ set-inode                              ( mode )
   false to modified?                                   ( mode )
   r/o =  unknown-extensions? or  to read-only?         ( )
   true                                                 ( okay? )
;

: open  ( -- okay? )
   allocate-buffers  if  false exit  then

   my-args " <NoFile>"  $=  if  true exit  then

   recover?  if  process-journal  then

   \ Start out in the root directory
   set-root

   my-args  ascii \ split-after                 ( file$ path$ )
   $chdir  if  2drop release-buffers false  exit  then  ( file$ )

   \ Filename ends in "\"; select the directory and exit with success
   dup  0=  if  2drop  true exit  then          ( file$ )

   2dup r/w $ext2fsopen  0=  if                 ( file$ )
      2dup r/o $ext2fsopen  0=  if              ( file$ )
         release-buffers 2drop  false exit      ( -- okay? )
      then                                      ( file$ )
   then                                        ( file$ )

   2drop
   false to gd-modified?
   " "  " deblocker"  $open-package  to deblocker
   deblocker  if  true  else  close false  then
;

: load  ( adr -- size )  size drop  read  ;

\ : files  ( -- )  begin   file-name type cr  next-dirent until  ;

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
