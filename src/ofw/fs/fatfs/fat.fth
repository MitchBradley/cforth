\ See license at end of file
\ File Allocation Table manipulation.

\ For performance, we cache a portion of the FAT (currently 3 sectors).
\ This also makes it easier to extract entries from the FAT, because
\ for floppy disk, FAT entries are 1.5 bytes long, and if we have 3
\ (or multiples of 3) sectors in the cache, then the cache contains
\ an integral number of FAT entries, with no fragments.

\ We keep a separate FAT cache for each device.
\ This improve performance and simplifies the code which deals with
\ flushing the cache, since switching devices does not require a cache
\ flush.  This also helps in supporting devices with sector sizes
\ > 512 bytes, because we can size the FAT cache as a multiple of the
\ device's native sector size.

hex

private

\ Magic numbers for FAT entries

0000.0000 constant fat-free
0fff.ffff constant fat-eof
0fff.fff7 constant fat-bad

( external )
: fat-end?  ( cl# -- flag )
   fat-type c@  case
      fat12  of  h# ff8  endof
      fat16  of  h# fff8  endof
      fat32  of  h# fff.fff8  endof
   endcase
   >=
;

: cl#>sector  ( cl# -- entry# sector# )
   cl#/fat-cache w@ /mod  sectors/fat-cache w@ *  ( entry# offset-sectors )
   fat-sector0 w@ +                               ( entry# sector# )
;

\ The number of sectors of the FAT cache which actually represent valid
\ disk sectors.  For instance, if the FAT has 5 total sectors, and the
\ FAT cache has 3 sectors, then sometimes only 2 of the sectors in the
\ FAT cache will be valid.

: #valid-sectors  ( -- n )
   spf l@ fat-sector @ fat-sector0 w@ -  -  sectors/fat-cache w@ min
;

create "fat ," File Allocation Table"

\ If the FAT cache has been modified since it was last written, flush it
\ to disk.

: .sectors  ( sector# #sectors -- )
   ."  " . ." sectors starting at " .
;
: ?flush-fat-cache  ( -- )
   fat-dirty w@ if
      fat-sector @ #valid-sectors fat-cache @ write-sectors  ( err? )  if
         "CaW ".  "FAT ".
         fat-sector @  #valid-sectors  .sectors
         abort
      then

      fat-sector @ spf l@ + #valid-sectors fat-cache @ write-sectors  if
         "CaW ".  ." alternate "  "FAT ".
         fat-sector @ spf l@ +  #valid-sectors  .sectors
         abort
      then

      false fat-dirty w!
   then
   write-fsinfo 
;
: get-fat-entries  ( cl# -- entry# cache-adr )
   cl#>sector                   ( entry# sector# )
   dup fat-sector @ =  if       \ Requested sector is in the FAT cache
      drop                      ( entry# )
   else                         \ Refill the FAT cache.
      ?flush-fat-cache          ( entry# sector# )

      \ Invalidate fat cache in case read fails
      -1 fat-sector !

      dup  sectors/fat-cache w@ fat-cache @ read-sectors
      ( entry# sector# error? )  if  "CaR ".  "FAT ".  abort  then

      fat-sector !            ( entry# )
   then                       ( entry# )
   fat-cache @
;

: cluster@  ( cl# -- cl#' )
   dup max-cl# l@ > if  drop fat-eof exit then   \ *** cpt 06/27/90: no overrun
                                                 \ *** cpt 10/30/90: >, no >= 
   get-fat-entries      ( entry# cache-adr )
   fat-type c@  case
      fat12  of
	 over 2/ 3 *  +  le24@  ( entry# 2-entries )
         swap 1 and  if  d# 12 >>  else  000fff and  then
      endof
      fat16  of
         swap wa+ lew@
      endof
      fat32  of
         swap la+ lel@  h# 0fff.ffff and
      endof
   endcase
;

: cluster!  ( new-cl# adr-cl# -- )
   get-fat-entries        ( new-cl# entry# cache-adr )
   fat-type c@  case
      fat12  of
         rot fff and -rot
         over 2/ 3 *  +  dup >r  le24@  ( cl# entry# 2-entries )  ( r: adr )
         swap 1 and  if  000fff and  swap d# 12 <<  or  else  fff000 and or  then
         r> le24!
      endof
      fat16  of
         rot ffff and -rot
         swap wa+ lew!
      endof
      fat32  of
         swap la+ lel!
      endof
   endcase
   true fat-dirty w!
;

private

\ For performance sake, we search for clusters physically near the
\ cluster presently at the end of the file, and we especially try to
\ find one which would be in the fat cache at the same time as the
\ previous cluster.

: search-up  ( high-cluster# low-cluster# -- cluster# true  |  false )
   false -rot  ?do
      i cluster@ 0=  if  drop i true leave  then
   loop
;
: search-down  ( low-cluster# high-cluster# -- cluster# true  |  false )
   false -rot  ?do
      i cluster@ 0=  if  drop i true leave  then
   -1 +loop
;

\ Search order for free clusters:  First search toward the nearest
\ fat cache boundary, then search toward the other fat cache boundary, then
\ search from the beginning of the disk, then search the rest of the disk.

VARIABLE hint  VARIABLE fatc-start  VARIABLE fatc-end

\ Be careful to avoid cluster numbers 0 and 1, which are reserved
: set-breaks  ( hint-cluster# -- )
   2 max  dup hint !
   dup cl#/fat-cache w@ mod -  2 max  dup fatc-start !
   cl#/fat-cache w@ +  max-cl# l@ min  fatc-end !
;

\ Set the new cluster's link to "eof", thus removing it from the free list.
\ This depends on the fact that newly-allocated clusters are always attached
\ to the end of a file.

: mark-cluster  ( cluster# -- cluster# true )
   \ Set the new cluster's link to "eof"
   fat-eof over cluster!   ( cluster# )
   true
;

: (allocate-cluster)  ( hint-cluster# -- cluster# true  |  false )
   set-breaks
   hint @ fatc-start @ -  fatc-end @ hint @ -  <  if    \ Search down first
      fatc-start @ hint @  search-down  if  mark-cluster exit  then
      fatc-end @   hint @  search-up    if  mark-cluster exit  then
   else                                                 \ Search up first
      fatc-end @   hint @  search-up    if  mark-cluster exit  then
      fatc-start @ hint @  search-down  if  mark-cluster exit  then
   then

   \ Search up to the end of the disk ** 10/30/90 cpt: up to last cl (1+)
   max-cl# l@ 1+ fatc-end @  search-up    if  mark-cluster exit  then

   \ Search down to the beginning of the disk
   2         fatc-start @  search-down  if  mark-cluster exit  then

   false
;
: allocate-cluster  ( hint-cluster# -- false | cluster# true )
   fsinfo @  if                                    ( hint )
      fs_#freeclusters lel@   if                   ( hint )
         fs_freecluster# lel@ max-cl# l@ <=  if    ( hint )
            drop fs_freecluster# lel@              ( hint' )
         then                                      ( hint )
         (allocate-cluster)                        ( false | cluster# true )
         dup  if  over fs-free#!  -1 +fs-#free  then  ( false | cluster# true )
      else                                         ( hint )
         drop false                                ( false )
      then                                         ( false | cluster# true )
   else                                            ( hint )
      (allocate-cluster)                           ( false | cluster# true )
   then                                            ( false | cluster# true )
;

\ Frees first-cl# and all clusters linked after it.
: deallocate-clusters  ( first-cl# -- )
   begin
      dup 0<>  over fat-end? 0= and
   while                                 ( cluster# )
      dup  cluster@                      ( cluster# next-cluster# )
      0 rot  cluster!                    ( next-cluster# )
      fsinfo @  if  1 +fs-#free  then    ( next-cluster# )
   repeat
   drop
   ?flush-fat-cache
;

internal

: unmount  ( device# -- )
   current-device @ >r  ( device# )  current-device !
   ?flush-fat-cache
   \ XXX should free memory for FAT cache
   uncache-device
   r> current-device !
;

: total-size  ( -- d.bytes )  max-cl# l@ 1+  /cluster *  0  ;

public
: free-bytes  ( -- d.#bytes )
   \ Search up to the end of the disk
   0  max-cl# l@ 1+ 2  ?do  i cluster@ 0= if  1+  then  loop ( #free-clusters )
   /cluster *  ( #bytes )
   0
;

[ifdef] notdef
\ Returns the amount of total and free space on the disk
: disk-size  ( device -- #bytes )  set-device total-size drop  ;
: disk-free  ( device -- #bytes )  set-device  free-bytes drop  ;
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
