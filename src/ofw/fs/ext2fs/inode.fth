\ See license at end of file
purpose: inodes for Linux ext2fs file system

decimal

0 instance value inode#
: set-inode  ( inode# -- )  to inode#  ;

: ipb	( -- n )  bsize /inode /  ;
: d.itob  ( i# -- offset d.block# )
   1- ipg /mod		( rel-i# group )
   d.gpimin  2>r	( rel-i# r: d.iblock# )
   ipb /mod		( offset rel-blk# r: d.iblock# )
   u>d 2r> d+		( offset d.block# )
;

: inode  ( i# -- adr )   d.itob d.block swap /inode * +  ;
: ind   ( n -- )  inode  /inode dump  ;
: +i  ( n -- )  inode# inode +  ;
: file-attr   ( -- attributes )  0 +i short@  ;
: file-attr!  ( attributes -- )  0 +i short!  update  ;
: uid         ( -- uid )         2 +i short@  ;
: uid!        ( uid -- )         2 +i short!  update  ;
: filetype    ( -- type )  file-attr  h# f000 and  ;
: dfile-size  ( -- d )           4 +i int@  108 +i int@  ;
: dfile-size! ( d -- )         108 +i int!  4 +i int!  update  ;
: atime       ( -- seconds )     8 +i int@  ;
: atime!      ( seconds -- )     8 +i int!  update  ;
: ctime       ( -- seconds )    12 +i int@  ;
: ctime!      ( seconds -- )    12 +i int!  update  ;
: mtime       ( -- seconds )    16 +i int@  ;
: mtime!      ( seconds -- )    16 +i int!  update  ;
: dtime       ( -- seconds )    20 +i int@  ;
: dtime!      ( seconds -- )    20 +i int!  update  ;
: gid         ( -- gid )        24 +i short@  ;
: gid!        ( gid -- )        24 +i short!  update  ;
: link-count  ( -- n )          26 +i short@  ;
: link-count! ( n -- )          26 +i short!  update  ;

: d.#blks-held  ( -- d )
   28 +i int@                                            ( n )
   \ Should be contingent on sb-huge-files? as below, but the field
   \ at 116 was reserved before, so it's going to be 0 without huge files
   116 +i short@                                         ( d )
\   sb-huge-files?  if  116 +i short@  else  u>d  then    ( d )
[ifdef] inode-huge?
   \ I'm not supporting the representation where the inode block
   \ count is in file system blocks instead of 512-byte blocks,
   \ because I can't figure out how it works in the Linux kernel.
   \ I can see how it works when updating an inode, but I don't
   \ see how it works with an already-created file.
   inode-huge?  if  logbsize 9 - dlshift  then           ( d' )
[then]
;

: d.#blks-held! ( d -- )
[ifdef] inode-huge?
   2dup h# 1.0000.0000.0000. d>=  if     ( d )
      logbsize 9 - drshift               ( d' )
      set-inode-huge                     ( d )
   else                                  ( d )
      clear-inode-huge                   ( d )
   then                                  ( d )
[then]
   116 +i short!  28 +i int!  update     ( )
;
: d.file-acl    ( -- d )        104 +i int@  118 +i short@  ;
\ : dir-acl     ( -- n )         108 +i int@  ;

d# 12 constant #direct-blocks
: direct0     ( -- adr )   40 +i  ;
: indirect1   ( -- adr )   88 +i  ;
: indirect2   ( -- adr )   92 +i  ;
: indirect3   ( -- adr )   96 +i  ;

: dir?     ( -- flag )      filetype  h# 4000 =  ;
: file?    ( -- flag )      filetype  h# 8000 =  ;
: symlink? ( -- symlink? )  filetype  h# a000 =  ;

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
