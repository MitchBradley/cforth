\ See license at end of file
purpose: Linux ext2fs file system package methods

decimal

0 instance value modified?

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

: ext2fsdflen  ( 'fhandle -- d.size )  drop  dfile-size  ;

: ext2fsdfalign  ( d.byte# 'fh -- d.aligned )
   drop swap bsize 1- invert and  swap
;

: ext2fsfclose  ( 'fh -- )
   drop  bfbase @  bsize free-mem		\ Registered with initbuf
   modified? if
      false to modified?
      time&date >unix-seconds dirent-inode@ set-inode ctime!
   then
;

: ext2fsdfseek  ( d.byte# 'fh -- )
   drop
   bsize um/mod nip	( target-blk# )
   to lblk#
;

: ext2fsfread   ( addr count 'fh -- #read )
   drop
   dup bsize > abort" Bad size for ext2fsfread"
   dfile-size  lblk# bsize um*  d- drop		( addr count rem )
   umin swap			( actual addr )
   lblk# j-read-file-block	( actual )
   dup  0>  if  lblk#++  then	( actual )
;

: ext2fsnowrite  ( addr count 'fh -- #written )
   ." Not writing to the ext2 filesystem because of unsupported extensions" cr
   3drop 0
;
: ext2fsfwrite   ( addr count 'fh -- #written )
   drop
   dup bsize > abort" Bad size for ext2fsfwrite"	( addr count )
   tuck 0  lblk# bsize um* d+				( addr count d.new-size )
   dfile-size 2over  d<  if				( actual addr d.new )
      dfile-size!	\ extending file		( actual addr )
   else							( actual addr d.new )
      2drop		\ not extending file		( actual addr )
   then							( actual addr )
   lblk# write-file-block				( actual )

   \ XXX I am skeptical about this line.
   dup  0>  if  lblk#++  then				( actual )
   true to modified?
\   flush					\ XXX kludge for tests
;

: $ext2fsopen  ( adr len mode -- false | fid fmode size align close seek write read true )
   -rot $find-file  if  drop false exit  then	        ( mode )
   wf-type regular-type <>  if  drop false exit  then   ( mode )

   dirent-inode@ set-inode                              ( mode )
   false to modified?

   >r
   bsize alloc-mem bsize initbuf
   dirent-inode@  r@  ['] ext2fsdflen ['] ext2fsdfalign ['] ext2fsfclose ['] ext2fsdfseek 
   r@ read =  unknown-extensions? or if
      ['] ext2fsnowrite
   else
      ['] ext2fsfwrite
   then
   r> write =  if  ['] nullread   else  ['] ext2fsfread   then
   true
;


false instance value file-open?
/fd instance buffer: ext2fs-fd

external

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

   file @ >r  ext2fs-fd file !                     ( file$ )
   2dup r/w $ext2fsopen  0=  if
      2dup r/o $ext2fsopen  0=  if
         release-buffers 2drop  false    r> file !  exit
      then
   then            ( file$ file-ops ... )

   setupfd
   2drop
   false to gd-modified?
   true to file-open?
   true
   r> file !
;

: close  ( -- )
   file-open?  if
      ext2fs-fd ['] fclose catch  ?dup  if  .error drop  then
      false to file-open?
   then
   update-gds
   flush
   release-buffers
   free-overlay-list
;
: read  ( adr len -- actual )
   ext2fs-fd  ['] fgets catch  if  3drop 0  then
;
: write  ( adr len -- actual )
   tuck  ext2fs-fd  ['] fputs catch  if  4drop -1  then
;
: seek   ( offset.low offset.high -- error? )
   ext2fs-fd  ['] dfseek catch  if  2drop true  else  false  then
;
: size  ( -- d )  dfile-size  ;
: load  ( adr -- size )  dfile-size drop  read  ;
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
