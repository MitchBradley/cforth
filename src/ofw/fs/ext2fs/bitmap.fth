\ See license at end of file
purpose: bitmaps for Linux ext2fs file system

decimal

\ Group descriptor access

0 instance value gd-modified?

: gd-update   ( block# -- )
   dup group-desc set-gd-csum  ( )
   true to gd-modified?        ( )
;
: d.block-bitmap  ( group# -- d.block# )
   group-desc  dup le-l@       ( adr n )
   desc64?  if                 ( adr n )
      swap h# 20 + le-l@       ( d.block# )
   else                        ( adr n )
      nip u>d                  ( d.block# )
   then                        ( d.block# )
;
: d.inode-bitmap  ( group# -- d.block# )
   group-desc  dup 4 + le-l@   ( adr n )
   desc64?  if                 ( adr n )
      swap h# 24 + le-l@       ( d.block# )
   else                        ( adr n )
      nip u>d                  ( d.block# )
   then                        ( d.block# )
;
[ifdef] notdef
: d.inode-table   ( group# -- d.block# )
   group-desc  dup 8 + le-l@   ( adr n )
   desc64?  if                 ( adr n )
      swap h# 28 + le-l@       ( d.block# )
   else                        ( adr n )
      nip u>d                  ( d.block# )
   then                        ( d.block# )
;
[then]
: free-blocks@  ( group# -- n )
   group-desc dup  h# 0c + le-w@       ( adr w )
   desc64?  if                         ( adr w )
      swap h# 2c + le-w@ wljoin        ( n )
   else                                ( adr w )
      nip                              ( n )
   then                                ( n )
;
: free-blocks!  ( n group# -- )
   group-desc >r            ( n     r: adr )
   desc64?  if              ( n     r: adr )
      lwsplit               ( lo hi r: adr )
      r@ h# 2c + le-w!      ( lo    r: adr )
   then                     ( n     r: adr )
   r> h# 0c + le-w!         ( )
;

: free-blocks+!  ( n group# -- )
   tuck free-blocks@ +  0 max   ( group# n' )
   over free-blocks!            ( group# 'gd )
   gd-update                    ( )
;
: free-inodes@   ( group# -- n )
   group-desc  dup  h# 0e + le-w@   ( adr lo )
   desc64?  if                      ( adr lo )
      swap h# 2e + le-w@ wljoin     ( n )
   else                             ( adr lo )
      nip                           ( n )
   then                             ( n )
;
: free-inodes!  ( n group# -- )
   group-desc >r            ( n     r: adr )
   desc64?  if              ( n     r: adr )
      lwsplit               ( lo hi r: adr )
      r@ h# 2e + le-w!      ( lo    r: adr )
   then                     ( n     r: adr )
   r> h# 0e + le-w!         ( )
;
: free-inodes+!  ( n group# -- )
   tuck free-inodes@  +   ( group# n' )
   over free-inodes!      ( group# )
   gd-update              ( )
;
: used-dirs@   ( group# -- n )
   group-desc  dup  h# 10 + le-w@   ( adr lo )
   desc64?  if                      ( adr lo )
      swap h# 30 + le-w@ wljoin     ( n )
   else                             ( adr lo )
      nip                           ( n )
   then                             ( n )
;
: used-dirs!  ( n group# -- )
   group-desc >r            ( n     r: adr )
   desc64?  if              ( n     r: adr )
      lwsplit               ( lo hi r: adr )
      r@ h# 30 + le-w!      ( lo    r: adr )
   then                     ( n     r: adr )
   r> h# 10 + le-w!         ( )
;
: used-dirs+!  ( n group# -- )
   tuck used-dirs@  +   ( group# n' )
   over used-dirs!      ( group# )
   gd-update            ( )
;

[ifdef] 386-assembler
code find-low-zero  ( n -- bit# )
   ax pop
   cx cx xor
   clc
   begin
      cx inc
      1 # ax rcr
   no-carry? until
   cx dec
   cx push
c;
[else]
create lowbits
   8 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 0-f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 10-1f

   5 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 20-2f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 30-3f

   6 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 40-4f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 50-5f

   5 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 20-2f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 30-3f

   7 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 80-8f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 90-9f

   5 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ a0-af
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ b0-bf

   6 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ c0-cf
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ d0-df

   5 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ e0-ef
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ f0-ff

: find-low-zero  ( byte -- bit# )  invert h# ff and  lowbits + c@  ;
[then]

\ Find the first clear bit in a bitmap, set it if found
: d.first-free   ( len d.block# -- false | block#-in-group true )
   d.block swap				( map len )

   2dup  h# ff bskip  dup  0=  if	( map len 0 )
      3drop false exit
   then					( map len residue )
   - 					( map byte# )
   tuck +  dup  c@  dup  find-low-zero	( byte# adr byte bit# )

   \ Set the bit we just found
   >r  1 r@ lshift  or			( byte# adr byte' r: bit# )
   swap c!  \ Write back to map		( byte# r: bit# )

   8* r> +				( block#-in-group )
   update				( block#-in-group )
   true
;

: bitup    ( n adr -- mask adr' )
   over 3 rshift +			( n adr' )
   1 rot 7 and lshift			( adr' mask )
   swap
;

: d.clear-bit?  ( bit# d.block# -- cleared? )
   d.block  bitup			( mask adr' )
   tuck c@				( adr mask byte )
   2dup and  0=  if	\ Already free	( adr mask byte )
      3drop  false  exit		( -- false )
   then					( adr mask byte )
   swap invert and			( adr byte' )
   swap c!				( )
   update				( )
   true					( true )
;

: d.free-block      ( d.block# -- )
   datablock0 u>d d- bpg um/mod		( bit# group# )
   tuck d.block-bitmap 			( group# bit# d.block# )
   d.clear-bit?  if			( group# )
      1  swap  free-blocks+!		( )
   else					( group# )
      drop				( )
   then					( )
;
: n.free-block      ( block# -- )  u>d d.free-block  ;

: d.alloc-block   ( -- d.block# )
   #groups 0  ?do			( )
      i free-blocks@  if		( )
         bpg 3 rshift  bsize min	( len )	\ XXX stay in this block
         i  d.block-bitmap  		( len d.block# )
         d.first-free  if		( block#-in-group )
            -1 i free-blocks+!		( block#-in-group )
	    u>d				( d.block#-in-group )
	    i bpg um*  d+		( d.block#-offset )
	    datablock0 u>d d+		( d.block# )
            2dup d.buffer bsize erase update	( d.block# )
            unloop exit			( -- d.block# )
         else				( )
            \ The allocation bitmap disagrees with the free block count,
            \ so fix the free block count to prevent thrashing.
            i free-blocks@  negate  i free-blocks+!
         then
      then
   loop
   true abort" no free blocks found"
;
: u.alloc-block  ( -- n.block# )
   #groups 0  ?do			( )
      i 1+ bpg um*  datablock0 u>d d+	( d.end-block# )
      h# 1.0000.0000. d>  abort" No free blocks found with 32-bit block number"  ( )

      i free-blocks@  if		( )
         bpg 3 rshift  bsize min	( len )	\ XXX stay in this block
         i  d.block-bitmap  		( len d.block# )
         d.first-free  if		( block#-in-group )
            -1 i free-blocks+!		( block#-in-group )
	    u>d				( d.block#-in-group )
	    i bpg um*  d+		( d.block#-offset )
	    datablock0 u>d d+		( d.block# )
            2dup d.buffer bsize erase update	( d.block# )
            drop  unloop exit			( -- n.block# )
         else				( )
            \ The allocation bitmap disagrees with the free block count,
            \ so fix the free block count to prevent thrashing.
            i free-blocks@  negate  i free-blocks+!
         then
      then
   loop
   true abort" no free blocks found"
;

: free-inode      ( inode# -- )
   1- ipg /mod 				( bit# group# )
   tuck d.inode-bitmap			( group# bit# d.block# )
   d.clear-bit?  if			( group# )
      1  swap  free-inodes+!
   else					( group# )
      drop
   then
;

: alloc-inode   ( -- inode# )
   #groups 0 ?do
      ipg 3 rshift  bsize min		( len )		\ XXX stay in this block
      i  d.inode-bitmap 		( len d.block# )
      d.first-free  if			( inode#-in-group )
         -1 i free-inodes+!		( inode#-in-group )
         i ipg * +  1+			( inode# )
         dup inode /inode erase update	( inode# )
         unloop exit
      then
   loop
   true abort" no free inodes found"
;

: update-sb   ( -- )
   0   #groups 0  ?do  i free-inodes@      +  loop    total-free-inodes!
   0.  #groups 0  ?do  i free-blocks@ u>d d+  loop  d.total-free-blocks!
   put-super-block abort" failed to update superblock "
   gds /gds d.gds-block# d.write-ublocks abort" failed to update group descriptors "
;

: update-gds   ( -- )
   gd-modified? if
      \ Copy group descriptors to backup locations
      \ If SPARSE_SUPER, then write only to groups 0,1, and powers of 3,5,7
      \ One way to find out, other than checking the numbers, is to inspect
      \ the block bitmap number in the group descriptor.  If it is larger than
      \ the calculated block number, do the backup.
      #groups 1  do
         i bpg * u>d  d.gds-fs-block# d+	( d.possible-gn )
         2dup  i d.block-bitmap d<  if		( d.possible-gn )
            d.block				( gdn-adr )
            0 group-desc			( gdn-adr gd0-adr )
            swap bsize move                     ( )
	    update		                ( )
         else					( d.possible-gn )
            2drop				( )
         then					( )
      loop
      false to gd-modified?
      update-sb
   then
;

: d.add-block   ( -- d.block# )
   d.#blks-held 2. d+ d.#blks-held!
   d.alloc-block
;
: u.add-block   ( -- block# )
   d.#blks-held 2. d+ d.#blks-held!
   u.alloc-block
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
