\ See license at end of file
purpose: Linux ext2fs file system directories

decimal

2 constant root-dir#
0. instance 2value d.dir-block#
0 instance value lblk#

instance variable diroff
instance variable totoff

\ Information that we need about the working file/directory
\ The working file changes at each level of a path search

0 instance value wd-inum  \ Inumber of directory to search
0 instance value wf-inum  \ Inumber of file or directory found
0 instance value wf-type  \ Type - 4 for directory, d# 10 for symlink, etc

: find-dirblk  ( -- )
   lblk# >d.pblk# 0= abort" EXT2 - missing directory block"  to d.dir-block#
;
: get-dirblk  ( -- end? )
   lblk# bsize um* dfile-size d< 0=  if  true exit  then
   find-dirblk
   false
;

\ **** Return the address of the current directory entry
: dirent  ( -- adr )  d.dir-block# d.block diroff @ +  ;
\ Dirent fields:
\ 00.l inode
\ 04.w offset to next dirent
\ 06.b name length
\ 07.b flags?
\ 08.s name string

: >reclen   ( name-length -- record-length )   8 + 4 round-up  ;

: dirent-inode@  ( -- n )  dirent int@  ;
: dirent-inode!  ( n -- )  dirent int!  update  ;
: dirent-len@  ( -- n )  dirent la1+ short@  ;
: dirent-len!  ( n -- )  dirent la1+ short!  update  ;
: dirent-nameadr   ( -- adr )  dirent la1+ 2 wa+  ;
: dirent-namelen@  ( -- b )  dirent la1+ wa1+ c@  ;
: dirent-namelen!  ( b -- )  dirent la1+ wa1+ c!  update  ;
: dirent-type@     ( -- b )  dirent la1+ wa1+ ca1+  c@  ;
: dirent-type!     ( b -- )  dirent la1+ wa1+ ca1+  c!  update  ;
: dirent-reclen    ( -- n )  dirent-namelen@ >reclen  ;

: lblk#++  ( -- )   lblk# 1+ to lblk#  ;

: dirent-vars  ( -- diroff totoff lblk# inode# )
   diroff @  totoff @  lblk#  inode#
;
: restore-dirent  ( diroff totoff lblk# inode# -- )
   set-inode  to lblk#  totoff !  diroff !
   get-dirblk drop
;

\ **** Select the next directory entry
: next-dirent  ( -- end? )
   dirent-len@  dup diroff +!  totoff +!
   totoff @ u>d  dfile-size d< 0=  if  true exit  then
   diroff @  bsize =  if
      lblk#++  get-dirblk  if  true exit  then
      diroff off
   then
   false
;

\ **** From directory, get name of file
: file-name  ( -- adr len )
   dirent la1+ wa1+  dup wa1+    ( len-adr name-adr )
   swap c@                       ( adr len )
;

: +link-count  ( increment -- )
   \ link-count = 1 means that the directory has more links than can
   \ be represented in a 16-bit number; don't increment in that case.
   dir? sb-nlink? and  if  ( increment )
      link-count 1 =  if   ( increment )
         drop exit         ( -- )
      then                 ( increment )
   then                    ( increment )

   link-count +            ( link-count' )

   \ If the incremented value exceeds the limit, store 1
   \ We should also set the RO_COMPAT_DIR_NLINK bit in the superblock,
   \ but we assume that OFW won't be used to create enormous directories
   dir? sb-nlink? and  if  ( link-count )
      dup d# 65000 >=  if  ( link-count )
         drop 1            ( link-count' )
      then                 ( link-count' )
   then                    ( link-count )

   link-count!             ( )
;

: new-inode    ( mode -- inode# )
   alloc-inode set-inode        ( mode )   \ alloc-inode erases the inode
   file-attr!			( )
   time&date >unix-seconds	( time )
   dup atime!			( time ) \ set access time
   dup ctime!			( time ) \ set creation time
       mtime!			( )      \ set modification time
   0 link-count!		( )      \ link count will be incremented by new-dirent
   dir?  if
      1 inode# 1- ipg / used-dirs+!
   then
   inode#			( inode# )
;

\ On entry:
\   inode# refers to the directory block's inode
\   d.dir-block# is the physical block number of the first directory block
\   diroff @ is 0
\ On successful exit:
\   d.dir-block# is the physical block number of the current directory block
\   diroff @ is the within-block offset of the new dirent
: no-dir-space?  ( #needed -- true | offset-to-next false )
   begin						( #needed )
      dirent-inode@  if					( #needed )
         dup  dirent-len@ dirent-reclen -  <=  if	( #needed )
            \ Carve space out of active dirent
            drop					( )
            dirent-len@ dirent-reclen -			( offset-to-next )
            dirent-reclen  dup dirent-len!  diroff +!	( offset-to-next )
            false exit
         then
      else						( #needed )
         dup  dirent-len@  <=  if			( #needed )
            \ Reuse deleted-but-present dirent
            drop					( )
            dirent-len@					( offset-to-next )
            false exit
         then						( #needed )
      then						( #needed )
      next-dirent					( #needed )
   until						( #needed )
   drop true
;

\ a directory entry needs 8+n 4-aligned bytes, where n is the name length
\ the last entry has a larger size; it points to the end of the block
: (last-dirent)   ( -- penultimate-offset )
   diroff off   0
   begin						( last )
      dirent-len@				        ( last rec-len )
      dup diroff @ + bsize <				( last rec-len not-end? )
\     over dirent-reclen =  and				( last rec-len not-end? )
   while						( last rec-len )
      nip diroff @ swap					( last' rec-len )
      diroff +!						( last )
   repeat						( last )
   drop							( last )
;
: last-dirent   ( -- free-bytes )
   dfile-size bsize um/mod nip  swap 0= if  1-  then to lblk#	( )
   find-dirblk
   (last-dirent) drop
   dirent-len@  dirent-reclen  -
;
0 constant unknown-type
1 constant regular-type
2 constant dir-type
3 constant chrdev-type
4 constant blkdev-type
5 constant fifo-type
6 constant sock-type
7 constant symlink-type

create dir-types
   unknown-type c,     \ 0
   fifo-type c,        \ 1
   chrdev-type c,      \ 2
   unknown-type c,     \ 3
   dir-type c,         \ 4
   unknown-type c,     \ 5
   blkdev-type c,      \ 6
   unknown-type c,     \ 7
   regular-type c,     \ 8
   unknown-type c,     \ 9
   symlink-type c,     \ 10
   unknown-type c,     \ 11
   sock-type c,        \ 12
   unknown-type c,     \ 13
   unknown-type c,     \ 14
   unknown-type c,     \ 15

: inode>dir-type  ( -- dir-type )
   filetype  d# 12 rshift   ( index )
   dir-types + c@
;

: fill-dirent   ( name$ rec-len inode# -- )
   dup set-inode   1 +link-count	( name$ rec-len inode# dir-type )
   \ XXX this should be contingent upon EXT2_FEATURE_INCOMPAT_FILETYPE
   inode>dir-type  dirent-type!		( name$ rec-len inode# )
   dirent-inode!			( name$ rec-len )
   dirent-len!				( name$ )
   dup dirent-namelen!			( name$ )
   dirent-nameadr swap move		( )
;

: to-previous-dirent  ( -- )
   diroff @  					( this )
   diroff off					( this )
   begin					( this )
      dup  diroff @ dirent-len@ +  <>		( this not-found? )
   while					( this )
      dirent-len@ diroff +!			( this )
   repeat					( this )
   diroff @ swap -  totoff +!			( )
;

\ Delete the currently selected inode. Does not affect the directory entry, if any.
: idelete   ( -- )
   dir? if
      -1 inode# 1- ipg / used-dirs+!
   then

   \ Short symlinks hold no blocks, but have a string in the direct block list,
   \ so we must not interpret that string as a block list.
   d.#blks-held d0<>  if
      extent?  if  delete-extents  else  delete-blocks  then
   then

   \ clear d.#blks-held, link-count, etc.
   0 +i  /inode  6 /l* /string erase
   
   \ delete inode, and set its deletion time.
   time&date >unix-seconds dtime!
   inode# free-inode
;

\ delete directory entry at diroff
: dirent-unlink   ( -- )
   inode# >r
   dirent-inode@ set-inode  -1 +link-count

   \ Release the inode if it has no more links
   link-count  0<=  if  idelete  then

   diroff @  if
      \ Not first dirent in block; coalesce with previous
      dirent-len@				( deleted-len )
      to-previous-dirent			( deleted-len )
      dirent-len@ + dirent-len!			( )
      dirent dirent-reclen +			( adr )
      dirent-len@ dirent-reclen -  erase	( )
   else
      \ First dirent in block; zap its inode
      0 dirent-inode!
   then      
   r> set-inode
;

\ The argument inode# means the inode to which the new directory entry
\ will refer.  The inode of the containing directory is in the *value*
\ named inode#

: new-dirent  ( name$ inode# -- error? )
   >r					( name$ r: inode# )
   \ check for room in the directory, and expand it if necessary
   dup >reclen  no-dir-space?   if	( name$ new-reclen r: inode# )
      \ doesn't fit, allocate more room
      bsize				( name$ bsize r: inode# )
      append-block			( name$ bsize r: inode# )
      lblk#++ get-dirblk  if		( name$ bsize r: inode# )
         r> 4drop			( )
         true exit			( -- true )
      then				( name$ bsize r: inode# )
   then					( name$ rec-len r: inode# )

   \ At this point dirent points to the place for the new dirent
   r> fill-dirent			( )
   false				( error? )
;

: ($create)  ( name$ mode -- error? )
   new-inode		( name$ inode# )

   \ new-inode changed the value of inode#; we must restore it so
   \ new-dirent can find info about the containing directory
   wd-inum set-inode    ( name$ inode# )

   new-dirent		( error? )
;

: linkpath   ( -- a )
   d.file-acl d0<>  if  bsize 9 rshift  else  0  then     ( #acl-blocks )
   u>d  d.#blks-held  d<>  if	\ long symbolic link path
      direct0 int@ block
   else			\ short symbolic link path
      direct0
   then
;

char \ instance value delimiter

defer $resolve-path
d# 1024 constant /symlink   \ Max length of a symbolic link

: set-root  ( -- )
   root-dir# to wd-inum  root-dir# to wf-inum  dir-type to wf-type
;

: strip\  ( name$ -- name$' )
   dup  0<>  if                      ( name$ )
      over c@  delimiter  =  if      ( name$ )
         1 /string                   ( name$ )
         set-root                    ( name$ )
      then                           ( name$ )
   then                              ( name$ )
;

: first-dirent  ( dir-inode# -- end? )  \ Adapted from (init-dir)
   set-inode
   0 to lblk#
   get-dirblk  if  true exit  then
   diroff off  totoff off               ( )
   false                                ( )
;   

\ On entry:
\   inode# is the inode of the directory file
\   d.dir-block# is the physical block number of the first directory block
\   diroff @ and totoff @ are 0
\ On successful exit:
\   d.dir-block# is the physical block number of the current directory block
\   diroff @ is the within-block offset of the directory entry that matches name$
\   totoff @ is the overall offset of the directory entry that matches name$

: $find-name  ( name$ dir-inum -- error? )
   first-dirent                            ( end? )
   begin  0=  while                        ( name$ )
      \ dirent-inode@ = 0 means a deleted dirent at the beginning
      \ of a block; skip those
      dirent-inode@  if                    ( name$ )
         2dup  file-name                   ( name$ name$ this-name$ )
         $=  if
            dirent-inode@ to wf-inum       ( name$ )
            dirent-type@  to wf-type       ( name$ )
            2drop false exit
         then                              ( name$ )
      then
      next-dirent                          ( name$ end? )
   repeat                                  ( name$ )

   2drop                                   ( )
   true
;

: symlink-resolution$  ( inum -- data$ )
   set-inode
   linkpath dup cstrlen
;

\ The work file is a symlink.  Resolve it to a new dirent
: dir-link  ( -- error? )
   delimiter >r  [char] / to delimiter     ( r: delim )

   \ Allocate temporary space for the symlink value (new name)
   /symlink alloc-mem >r                   ( r: delim dst )

   \ Copy the symlink resolution to the temporary buffer
   wf-inum symlink-resolution$    ( src len  r: delim dst )
   tuck  r@ swap move             ( len      r: delim dst )

   r@ swap $resolve-path          ( error?   r: delim dst )

   r> /symlink free-mem           ( error?   r: delim )
   r> to delimiter                ( error? )
;

\ On successful exit, wf-inum is the inode# of the last path component,
\ wf-type is its type, and wd-inum is inode# of the last directory encountered

: ($resolve-path)  ( path$ -- error? )
   dir-type to wf-type
   \ strip\ sets wd-inum if the path begins with the delimiter
   begin  strip\  dup  while                       ( path$  )
      wf-type  case                                ( path$  c: type )
         dir-type  of                              ( path$ )
            delimiter left-parse-string            ( rem$' head$ )
            \ $find-name sets wf-inum and wf-type to the pathname component
            wd-inum  $find-name  if  2drop true exit  then  ( rem$ )
            wf-type dir-type =  if                 ( rem$ )
               wf-inum to wd-inum                  ( rem$ )
            then                                   ( rem$ )
         endof                                     ( rem$ )

         symlink-type  of                          ( rem$ )
            \ dir-link recursively calls $resolve-path, setting
            \ wf-inum and wf-type to the symlink's last component
            dir-link  if  2drop true exit  then    ( rem$ )
         endof                                     ( rem$ )
         ( default )                               ( rem$  c: type )

         \ The parent is an ordinary file or something else that
         \ can't be treated as a directory
         3drop true exit
      endcase                           ( rem$ )
   repeat                               ( rem$ )
   2drop false                          ( false )
;

' ($resolve-path) to $resolve-path

: $find-file  ( name$ -- error? )
   $resolve-path  if  true exit  then  ( )

   begin
      \ We now have the dirent for the file at the end of the string
      wf-type  case
         dir-type      of  wf-inum to wd-inum   false exit  endof  \ Directory
         regular-type  of                       false exit  endof  \ Regular file
         symlink-type  of  dir-link  if  true exit  then  endof    \ Link
         ( default )   \ Anything else (special file) is error
            drop true exit
      endcase
   again
;
\ --

: $chdir  ( path$ -- error? )
   $find-file  if  true exit  then
   wf-type dir-type <>  if  true exit  then
   wd-inum first-dirent
;

\ Returns true if inode# refers to a directory that is empty
\ Side effect - changes dirent context
: empty-dir?  ( inode# -- empty-dir? )
   set-inode

   dir? 0= if  false exit  then

   inode# first-dirent  if  false exit  then   \ Should be pointing to "." entry
   next-dirent  if  false exit  then   \ Should be point to ".." entry
   next-dirent  ( end? )               \ The rest should be empty
;

external

\ directory information

: file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   inode# >r   dirent-inode@ set-inode			( id )
   1+  mtime unix-seconds>  dfile-size drop  file-attr  file-name true
   r> set-inode
;

\ Deleted files at the beginning of a directory block have inode=0
: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup  if  
      begin
	 next-dirent  0= while
	 dirent-inode@  if   file-info exit   then
      
      repeat
      drop false
   else
      file-info
   then
;

: $readlink   ( name$ -- true | link$ false )
   dirent-vars 2>r 2>r
   $resolve-path  if  2r> 2r> restore-dirent  true exit  then
   wf-type symlink-type <>  if  2r> 2r> restore-dirent  true exit  then
 
   wf-inum symlink-resolution$ false
   2r> 2r> restore-dirent
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
