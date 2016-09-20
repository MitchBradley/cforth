\ See license at end of file
purpose: BLOCK primitive for Linux ext2fs file system

decimal

\ the return of BLOCK, complete with an LRU buffer manager

0 instance value block-bufs
8 constant #bufs

false value bbug?
\ true to bbug?

struct	\ buffer
   /n field >dirty
   2 /n * field >d.blk#
   \ /n field >device
   0 field >data
constant /buf-hdr
0 instance value /buffer

: >bufadr   ( n -- a )   /buffer * block-bufs +  ;
: >buffer   ( n -- adr )      >bufadr >data  ;
: dirty?    ( n -- dirty? )   >bufadr >dirty @  ;
: dirty!    ( dirty? n -- )   >bufadr >dirty !  ;
: d.blk#      ( n -- d.blk# )     >bufadr >d.blk# 2@  ;
: d.blk#!     ( d.blk# n -- )     >bufadr >d.blk# 2!  ;

create buf-table  #bufs allot

: d.read-fs-block  ( adr d.fs-blk# -- error? )
   bsize -rot  logbsize dlshift  d.read-ublocks
;
: d.write-fs-block  ( adr d.fs-blk# -- error? )
   bsize -rot  logbsize dlshift  d.write-ublocks
;

: empty-buffers   ( -- )
   block-bufs /buffer #bufs * erase
   #bufs 0 do  -1. i d.blk#!  loop
   buf-table  #bufs 0 ?do  i 2dup + c!  loop  drop
;

: mru   ( -- buf# )   buf-table c@  ;
: update   ( -- )   true mru dirty!  ;
: mru!   ( buf# -- )			\ mark this buffer as most-recently-used
   dup mru = if  drop exit  then	\ already mru
   
   -1 swap   #bufs 1 do	( offset buf# )
      dup i buf-table + c@ = if				( offset buf# )
	 nip i swap leave
      then
   loop						( offset buf# )
   over #bufs >= abort" mru problem "
   
   swap  buf-table dup 1+ rot move
   buf-table c!
;
: lru   ( -- buf# )
   buf-table #bufs + 1- c@	( n )
   buf-table dup 1+ #bufs 1- move
   dup buf-table c!
;

: flush-buffer   ( buffer# -- )
   dup dirty? if			( buffer# )
      false over dirty!
      dup >buffer  swap d.blk#		( buffer-adr d.block# )
      2dup d.gds-fs-block# d<=  if      ( buffer-adr d.block# )
         2dup d. ." attempt to corrupt superblock or group descriptor" abort
      then                              ( buffer-adr d.block# )
      bbug? if ." W " 2dup d. cr then   ( buffer-adr d.block# )
      d.write-fs-block abort" write error "
   else
      drop
   then
;
: flush   ( -- )   #bufs 0 ?do   i flush-buffer   loop  ;

: d.(buffer)   ( d.block# -- buffer-adr in-buf? )
   \ is the block already in a buffer?
   #bufs 0  ?do				( d.block# )
      2dup i d.blk# d=  if  \ found it	( d.block# )
	 2drop  i mru!			( )
         i >buffer true unloop exit	( -- buffer-adr true )
      then				( d.block# )
   loop					( d.block# )      
   
   \ free up the least-recently-used buffer
   lru dup flush-buffer			( d.block# buf# )
   
   dup >r  d.blk#!			( r: buf# )
   r> >buffer false			( buffer-adr false )
;

: d.buffer   ( d.block# -- a )	\ like block, but does no reads
   d.(buffer) drop
;
: d.block   ( d.block# -- a )
   2dup d.(buffer) if  nip nip exit  then		( d.block# buffer-adr )

   bbug? if ." r " 2 pick 2 pick d. cr then		( d.block# buffer-adr )
   dup 2swap d.read-fs-block abort" read error "	( buffer-adr )
;
: block  ( block# -- a )  u>d d.block  ;

: d.bd   ( d -- )   d.block bsize dump  ;

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
