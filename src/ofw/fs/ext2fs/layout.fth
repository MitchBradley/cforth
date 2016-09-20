\ See license at end of file
\ file layout

\ in inode: block0..block11, ind1, ind2, ind3
\ if block# is 0, read returns all 0s

0 instance value #ind-blocks1
0 instance value #ind-blocks2
0 instance value #ind-blocks3

\ first	number
\ 0	12		direct
\ 12	256		indirect1
\ 268	65536		indirect2
\ 65806	16777216	indirect3
\ maximum 16843020

: >direct     ( index -- adr )     direct0 swap la+  ;
: get-direct  ( index -- block# )  >direct int@  ;
: put-direct  ( block# index -- )  >direct int! update  ;

\ reads: if any indir block is 0, bail and return 0

: >ind1  ( index block# -- adr )
   dup 0=  if  nip exit  then
   
   block swap la+
;
: >ind2  ( index block# -- adr )
   dup 0=  if  nip exit  then
   
   block
   >r  #ind-blocks1 /mod  r>		( index-low index-high adr )
   swap la+ int@			( index-low block# )
   >ind1				( adr )
;
: >ind3  ( index block# -- adr )
   dup 0=  if  nip exit  then
   
   block
   >r  #ind-blocks2 /mod  r>		( index-low index-high adr )
   swap la+ int@			( index-low block# )
   >ind2				( adr )
;
: >pblk-adr  ( logical-block# -- 0 | physical-block-adr )
   dup #direct-blocks <  if     ( lblk# )
      >direct exit		( -- adr )
   then                         ( lblk# )
   #direct-blocks -             ( lblk#' )

   dup #ind-blocks1 <  if       ( lblk# )
      #direct-blocks    get-direct >ind1  exit	( -- adr )
   then
   #ind-blocks1 -               ( lblk#' )

   dup #ind-blocks2  <  if	( lblk# )
      #direct-blocks 1+ get-direct >ind2 exit	( -- adr )
   then				( lblk# )
   #ind-blocks2  -              ( lblk#' )

   dup #ind-blocks3  <  if	( lblk# )
      #direct-blocks 2+ get-direct >ind3 exit	( -- adr )
   then				( lblk# )

   drop 0			( 0 )
;
: >d.pblk#  ( logical-block# -- false | d.physical-block# true )
   extent?  if                ( logical-block# )
      extent->pblk# true exit ( -- d.physical-block# true )
   then                       ( logical-block# )
   >pblk-adr dup 0=  if       ( 0 )
      exit                    ( -- false )
   then                       ( adr )
   int@ dup 0<>  if           ( u.physical-block# )
      u>d true                ( -- d.physical-block# true )
   then                       ( -- false ) \ there is no physical block
;


\ writes: if any indir block is 0, allocate and return it.

: get-ind1  ( index ind1-block# -- block# )
   >r					( index ) ( r: ind3-block# )
   r@ block over la+ int@		( index block# )
   dup if				( index block# )
      nip
   else
      drop u.add-block			( index new-block# )
      dup rot r@ block swap la+ int! update	( new-block# )
   then					( block# )
   r> drop				( block# )
;
: get-ind2  ( index ind2-block# -- block# )
   >r					( index ) ( r: ind3-block# )
   #ind-blocks1 /mod			( index-low index-high )
   r@ block over la+ int@		( index-low index-high block# )
   dup if				( index-low index-high block# )
      nip
   else
      drop u.add-block			( index-low index-high new-block# )
      dup rot r@ block swap la+ int! update	( index-low new-block# )
   then					( index-low block# )
   get-ind1				( block# )
   r> drop				( block# )
;
: get-ind3  ( index ind3-block# -- block# )
   >r					( index ) ( r: ind3-block# )
   #ind-blocks2 /mod			( index-low index-high )
   r@ block over la+ int@		( index-low index-high block# )
   dup if				( index-low index-high block# )
      nip
   else
      drop u.add-block			( index-low index-high new-block# )
      dup rot r@ block swap la+ int! update	( index-low new-block# )
   then					( index-low block# )
   get-ind2				( block# )
   r> drop				( block# )
;

\ get-pblk# will allocate the block if necessary, used for writes
: get-pblk#  ( logical-block# -- 0 | physical-block# )
   dup #direct-blocks <  if			( lblk# )
      dup get-direct ?dup  if			( lblk# pblk# )
         nip exit				( -- pblk# )
      then					( lblk# )
      
      u.add-block				( lblk# pblk# )
      dup rot >direct int! update		( pblk# )
      exit					( -- pblk# )
   then						( lblk# )
   #direct-blocks -				( lblk#' )

   dup #ind-blocks1 <  if			( lblk# )
      #direct-blocks    get-direct ?dup 0=  if	( lblk# )
	 u.add-block				( lblk# ind1-pblk# )
         dup #direct-blocks put-direct		( lblk# ind1-pblk# )
      then					( lblk# ind1-pblk# )
      get-ind1 exit				( -- pblk# )
   then						( lblk# )
   #ind-blocks1 -				( lblk#' )

   dup #ind-blocks2  <  if
      #direct-blocks 1+ get-direct ?dup 0=  if	( lblk# )
	 u.add-block				( lblk# ind2-pblk# )
         dup #direct-blocks 1+ put-direct	( lblk# ind2-pblk# )
      then					( lblk# ind2-pblk# )
      get-ind2 exit				( -- pblk# )
   then						( lblk# )
   #ind-blocks2  -				( lblk#' )

   dup #ind-blocks3  <  if			( lblk#' )
      #direct-blocks 2+ get-direct ?dup 0=  if	( lblk# )
	 u.add-block				( lblk# ind3-pblk# )
         dup #direct-blocks 2+ put-direct	( lblk# ind3-pblk# )
      then					( lblk# ind3-pblk# )
      get-ind3 exit				( -- pblk# )
   then						( lblk# )

   drop 0					( 0 )
;

\ deletes

\ this code is a bit tricky, in that after deleting a block,
\ you must update the block that pointed to it.

: del-blk0   ( a -- deleted? )
   int@ dup 0= if  exit  then   n.free-block  true
;
: del-blk1   ( a -- deleted? )
   int@ dup 0= if  exit  then			( blk# )
   
   bsize 0 do					( blk# )
      dup block i + del-blk0 if  0 over block i + int! update  then
   4 +loop					( blk# )
   n.free-block  true
;
: del-blk2   ( a -- deleted? )
   int@ dup 0= if  exit  then			( blk# )
   
   bsize 0 do					( blk# )
      dup block i + del-blk1 if  0 over block i + int! update  then
   4 +loop					( blk# )
   n.free-block  true
;
: del-blk3   ( a -- deleted? )
   int@ dup 0= if  exit  then			( blk# )
   
   bsize 0 do					( blk# )
      dup block i + del-blk2 if  0 over block i + int! update  then
   4 +loop					( blk# )
   n.free-block  true
;
: delete-directs   ( -- )
   #direct-blocks 0 do
      direct0 i la+ del-blk0  if  0 direct0 i la+ int! update  then
   loop
;
: delete-blocks   ( -- )
   extent?  if  delete-extents exit  then
   delete-directs
   indirect1 del-blk1  if  0 indirect1 int! update  then
   indirect2 del-blk2  if  0 indirect2 int! update  then
   indirect3 del-blk3  if  0 indirect3 int! update  then
;

: append-block   ( -- )
   u.add-block							( pblk# )
   dfile-size bsize um/mod nip  dup bsize um* dfile-size!	( pblk# #blocks )
   1+ >pblk-adr int! update
;

: read-file-block  ( adr lblk# -- )
   >d.pblk#  if          ( adr d.pblk# )
      d.block swap bsize move
   else                  ( adr )
      bsize erase        ( )
   then
;

: zeroed?   ( a -- empty? )
   0 swap  bsize bounds do  i l@ or  4 +loop  0=
;
: write-file-block  ( adr lblk# -- )
   \ see if it is already allocated (XXX later: deallocate it)
   over zeroed? if              ( adr lblk# )
      >d.pblk# 0=  if           ( adr )
         drop  exit             ( -- )
      then                      ( d.pblk# )
   else			        ( adr lblk# )  \ find or allocate physical block
      extent?  if	        ( adr lblk# )
         >d.pblk#  0= abort" EXT4: Allocating blocks inside extents not yet supported"
				( adr d.pblk# )
      else		        ( adr lblk# )
         get-pblk# u>d		( adr d.pblk# )
      then			( adr d.pblk# )
   then
\ This interferes with journal recovery
\  dup h# f8 < if  dup . ." attempt to destroy file system" cr abort  then
   d.block bsize move update
;


\ installation routines

\ **** Allocate memory for necessary data structures
: allocate-buffers  ( -- error? )
   init-io
   /super-block do-alloc is super-block
   get-super-block ?dup  if
      super-block /super-block do-free exit
   then

   /gds do-alloc is gds
   gds /gds d.gds-block# d.read-ublocks dup  if
      gds         /gds          do-free
      super-block /super-block  do-free exit
   then

   bsize /buf-hdr + dup to /buffer
   #bufs *  do-alloc is block-bufs
   empty-buffers

   bsize /l /  dup to #ind-blocks1  ( #ind-blocks1 )
   dup dup *   dup to #ind-blocks2  ( #ind-blocks1 #ind-blocks2 )
   *               to #ind-blocks3  ( )
;

: release-buffers  ( -- )
   gds             /gds             do-free
   block-bufs      /buffer #bufs *  do-free
   super-block     /super-block     do-free
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
