\ See license at end of file
purpose: FDisk partition map decoder

\ Returns true if the sector buffer appears to contain a BIOS Parameter Block,
\ which signifies the beginning of a DOS "FAT" file system.
: fat?  ( -- flag )
   sector-buf d# 11 +  le-w@              ( bps )
   dup  dup 1- and 0=                  ( bps power-of-2? )
   swap  d# 256  d# 4096 between  and  ( bps-ok? )
   sector-buf d# 16 + c@ 1 2 between and  ( flag )  \ #FATS ok?
;

\ This is a lame check to see if there might be a partition map entry.
\ It is for the case where the disk has a valid BPB in sector 0, but
\ also has a partition that doesn't start at 0.  Thit is a bogus layout,
\ but we need to handle it anyway, because people often screw up when
\ using fdisk and mkdosfs under Linux.  It is too easy to run mkdosfs on
\ the overall disk (not the partition).
: unpartitioned?  ( -- flag )
   \ In partition maps, the status byte is 0 (not bootable) or 80 (bootable)
   sector-buf h# 1be + c@  h# 7f and  0<>     ( unpartitioned? )
   \ and the end of the sector contains a signature
   sector-buf h# 1fe + le-w@ h# aa55 <>  or   ( unpartitioned?' )
   \ and the first partition entry has a non0 starting sector number
   sector-buf h# 1c6 + le-l@ 0=  or           ( unpartitioned?' )
;

: ptable-bounds  ( -- end start )  sector-buf  h# 1be +  h# 40  bounds  ;
: ptable-sum  ( -- n )   0  ptable-bounds  do  i c@ +  loop  ;
: fdisk?  ( -- flag )
   sector-buf h# 1fe + le-w@  h# aa55  <>  if  false exit  then

   \ If the partition table area is all zero, then it's not a partition table
   ptable-sum     ( sum )
   0=  if  false exit  then

   \ Look for at least one recognizable partition type code
   ptable-bounds  do
      i 4 + c@                                        ( type )
      dup 1 =                   \ FAT12
      over 4 7 between or       \ 4: FAT16<32M  5: Extended 6: FAT16>32M 7: NTFS
      over h#  b =     or	\ FAT-32
      over h#  c =     or	\ FAT-32
      over h#  e =     or	\ FAT-16 LBA
      over h#  f =     or	\ Extended LBA
      over h# 41 =     or       \ PowerPC PreP
      over iso-type =  or       \ ISO9660
      over minix-type =  or     \ Minix
      over ufs-type =  or       \ Unix file system
      swap ext2fs-type =  or    \ Linux ext2/3, reiser, etc  ( recognized? )
      if  i 4 + c@ to partition-type true unloop exit  then
   h# 10 +loop
   false
;

\ ??? n,s,b,t means #sectors start-sector boot-indicator type
\ type: 0 empty, 1 12-bit FAT, 4 16-bit FAT, 5 extended, 6 over 32M
\            ... b FAT 32, c FAT 32 LBA, e FAT-16 LBA, f extended LBA
\ boot-indicator: 80 bootable

: process-ptable  ( -- true | n,s,b,t4 n,s,b,t3 n,s,b,t2 n,s,b,t1 false )
   sector-buf h# 1fe + le-w@  h# aa55  <>  if  true exit  then

   \ Process a real partition table
   sector-buf h# 1ee +  h# -30  bounds  do
      i d# 12 + le-l@  i 8 + le-l@  i c@  i 4 + c@
   h# -10 +loop
   false
;

\ (find-partition) scans ordinary and extended partitions looking for one that
\ matches a given criterion.

0 instance value extended-offset
false value found?
defer suitable?  ( b t -- b t flag )

: (find-partition  ( sector-offset -- not-found? )
   >r process-ptable  if  r> drop false exit  then  r>  ( n,s,b,t*4 sector-offset )

   4 0 do			( n,s,b,tN ... n,s,b,t1 sector-offset )
      >r						( ... n,s,b,t )
      found?  if		\ partition was found	( ... n,s,b,t )
         2drop 2drop					( ... )
      else						( ... n,s,b,t )
         ?dup 0=  if					( ... n,s,b )
	    \ empty, skip it.
	    3drop					( ... )
         else						( ... n,s,b,t )
            dup 5 = over h# f = or  if   \ extended partition          ( ... n,s,b,t )
               2drop nip                                ( ... s )
               extended-offset dup 0=  if  over to extended-offset  then
               + dup                                    ( ... es )
               sector-buf >r sector-alloc               ( ... es )
               read-sector recurse drop                 ( ... )
               sector-free r> to sector-buf             ( ... )
            else		\ Ordinary partition	( ... n,s,b,t )
               suitable?  if                		( ... n,s,b,t )
                  to partition-type drop		( ... n,s )
                  \ FAT partitions encode offsets in 512 byte sectors
                  r@ + /sector d# 512 / / to sector-offset	( ... n )
                  /sector um* to size-high to size-low	( ... )
                  true to found?			( ... )
               else					( ... n,s,b,t )
                  4drop					( ... )
               then					( ... )
            then					( ... )
         then						( ... )
      then						( ... )
      r>						( ... sector-offset )
   loop
   drop found? 0=
;
: (find-partition)  ( sector-offset criterion-xt -- not-found? )
   to suitable?  false to found?  (find-partition
;

\ These are some criteria used for finding specific partitions

\ Matches UFS partitions
: is-ufs?  ( type -- type flag )  dup ufs-type =  ;

\ Matches partitions with the bootable flag set
: bootable?  ( boot? type -- boot? type flag )  over h# 80 =  ;

\ Kludge for Linux: bootable flag is not always set, accept ext2fs-type
\ : bootable?  ( boot? type -- boot? type flag )
\    over h# 80 =  over h# 83 = or
\ ;

\ Matches the Nth partition, where N is initially stored in the value #part
: nth?  ( -- flag )  #part 1- dup to #part  0=  ;

: find-partition  ( sector-offset -- )
   0  ['] nth? (find-partition) abort" No such partition"
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
