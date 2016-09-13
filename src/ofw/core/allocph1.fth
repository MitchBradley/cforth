\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: allocph1.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
copyright: Use is subject to license terms.
purpose: Allocator for physical memory - 1-cell version
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved

\ Methods:

\ claim  ( [ phys ] size alignment -- base )
\       If "alignment" is non-zero, allocates at least "size" bytes of
\	physical memory aligned on the indicated boundary, returning
\	its address "base".  This implementation rounds
\	"alignment" up to a multiple of the page size.
\
\	If "alignment" is zero, removes the range of physical memory
\	denoted by phys and size from the list of available
\	physical memory, returning "base" equal to "phys"
\
\ release  ( phys size -- )
\	Frees the physical memory range denoted by phys and size.

\ clear-mem is a deferred word so that a system-dependent implementation,
\ perhaps using bzero hardware, can be installed in the system-dependent
\ part of the load sequence.

headerless
defer clear-mem  ( phys size -- )  ' 2drop is clear-mem
defer initial-memory  ( -- adr len )  ' no-memory to initial-memory

headers
root-device
new-device

" memory" device-name

list: physavail   0 physavail !

headers
: first-phys-avail  ( -- phys size )
   physavail last-node node-range  ( phys size )
;
headerless

: accum-size  ( total node -- total' false )  >size @ +  false  ;
: total-size  ( list -- size )
   0 swap ['] accum-size find-node  2drop
;

: (claim-phys-callback)
   ( aln|adr size  aln size max min -- aln|adr size false | phys true )
   4 " claim-phys"  ($callback)  if                 ( adr size )
      \ There was no "claim-phys" callback, so we return false to
      \ indicate that the firmware should proceed.
      false                                       ( adr size false )
   else                                           ( adr size  [ phys ] err? n )
      \ There was a "claim-phys" callback.  If it succeeded, we return
      \ the result under true to indicate that the operation has
      \ been performed.  If it failed, we throw the error because we
      \ are no longer in charge of allocation services.
      drop throw                                  ( aln size phys )
      nip nip true
   then      
;
: alloc-phys-callback?  ( aln size -- aln size false | phys true )
   2dup  -1 0  (claim-phys-callback)
;
: claim-phys-callback?  ( adr size -- adr size false | phys true )
   2dup  pagesize -rot swap dup  (claim-phys-callback)
;
: release-phys-callback?  ( adr size -- true | adr size false )
   2dup 2  " release-phys"  ($callback)  if       ( adr size )
      \ There was no "release-phys" callback, so we return false to
      \ indicate that the firmware should proceed.
      false                                       ( adr size false )
   else                                           ( adr size  err? n )
      \ There was a "release-phys" callback.  If it failed, oh well.
      \ Discard the arguments and return true to indicate that the
      \ operation has been done.
      2drop 2drop true
   then      
;

: allocate-aligned-physical  ( alignment size -- phys )
   \ Minumum granularity of memory chunks is 1 page
   swap pagesize round-up
   swap pagesize round-up			( aln+ size+ )

   alloc-phys-callback?  if  exit  then         ( aln+ size+ )

   tuck physavail				( size alignment size list )
   allocate-memrange				( size [ adr ] error? )
   abort" Insufficient physical memory"		( size adr )
   dup rot clear-mem				( phys )
;

variable allow-reclaim  true allow-reclaim !
: claim-physical  ( adr len -- )
   >page-boundaries                               ( adr' len' )

   claim-phys-callback?  if  drop exit  then      ( adr' len' )

   \ Look first in the monitor's piece list
   physavail  ['] contained?  find-node           ( adr len prev next|0 )
   is next-node  is prev-node                     ( adr len )

   next-node 0=  if
      allow-reclaim @  0=
      abort" physical address already used"       ( adr len )
      2drop  exit
   then

   \ There are 4 cases to consider in removing the requested physical
   \ address range from the list:
   \ (1) The requested range exactly matches the list node range
   \ (2) The requested range is at the beginning of the list node range
   \ (3) The requested range is at the end of the list node range
   \ (4) The requested range is in the middle of the list node range

   \ Remember the range of the node to be deleted
   next-node node-range                            ( adr len node-a,l )

   \ Remove the node from the list
   prev-node delete-after  memrange free-node      ( adr len node-a,l )

   \ Give back any left-over portion at the beginning
   over 4 pick over -  dup  if            ( adr len node-a,l begin-a,l )
      physavail free-memrange
   else
      2drop
   then                                            ( adr len node-a,l )

   \ Give back any left-over portion at the end
   2swap +  -rot  +   over -                            ( end-a,l )
   ?dup  if  physavail free-memrange  else  drop  then  (  )
;
headers
: claim ( [ phys ] size align -- base )
   ?dup  if                          ( size align )
      \ Alignment should be next power of two
      swap allocate-aligned-physical ( base )
   else                              ( phys size )
      >r dup r> claim-physical       ( base )
   then                              ( base )
;
: release  ( phys size -- )
   >page-boundaries                         ( adr' size' )
   release-phys-callback?  if  exit  then   ( adr' size' )
   ['] 2drop  is ?splice                    ( adr' size' )
   physavail free-memrange
;
: close  ( -- )  ;
: open  ( -- ok? )
   physavail @  if  true exit  then
   initial-memory  dup  if   ( phys size )
      release
   else
      2drop
   then
   true
;

-2 constant mode

finish-device
device-end

headers
stand-init: memory node
   " /memory" open-dev  memory-node !
;
