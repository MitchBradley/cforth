\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: memlist.fth
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
id: @(#)memlist.fth 2.9 05/04/08
purpose: Common routines for memory list manipulation
copyright: Copyright 2005 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
listnode
   /n field >adr
   /n field >size
nodetype: memrange

headerless
\ local variable for use by memory list code
0 value prev-node	\ The node preceding (above) the insertion point
0 value next-node	\ The node following (below) the insertion point
0 value memlist		\ The memory list we're working on
defer ?splice	( adr node -- )  \ Routine to free spanning resources

headers
: node-range  ( node -- adr size )  dup >adr @  swap >size @  ;
headerless
\ Convenience functions

: prev-start  ( -- adr )  prev-node >adr @  ;
: next-end  ( -- adr )  next-node node-range +  ;

\ Allocates and initializes a new memory node
headers
: set-node  ( adr size -- node )
   memrange allocate-node                 ( adr' size' node )
   tuck >size !  tuck >adr !              ( node )
;
headerless
\ Expands the address range adr,len out to page boundaries in both directions.

: >page-boundaries  ( adr len -- page-aligned-adr page-multiple-len )
   bounds                                        ( top-adr bottom-adr )
   pagesize round-down  swap pagesize round-up   ( bottom-adr' top-adr' )
   over -                                        ( adr' len' )
;


\ Used with "find-node" to locate the pair of nodes around "adr"

: lower?  ( adr node -- adr flag )  >adr @  over u<=  ;


\ Used with "find-node" to locate a memory node at least as big as "size"

: big-enough?  ( size node-adr -- size flag )  >size @  over u>=  ;


\ Handle possible singularity at 0
: handle-0  ( end-adr start-adr -- end-adr' start-adr' )
   2dup =  if  exit  then               \ Don't do it for 0-length ranges
   over  0=  if  nip -1 swap  then
;

\ Used with "find-node" to locate a memory node containing the range adr,len

: (contained?)  ( adr1 len1 adr2 len2 -- adr1 len1 flag )
   bounds handle-0              ( adr len  node-end node-start )
   2over bounds handle-0        ( adr len  node-end,start end,start )
   rot u>= -rot  u>=  and       ( adr len flag )
;
: contained?  ( adr len node-adr -- adr len flag )  node-range  (contained?)  ;

\ Frees the range of memory "adr size", adding it to the free list "list".
\ Every attempt is made to add the memory range to an existing node, and
\ to join adjacent nodes into one larger node.  When memory is added to an
\ existing node, or when nodes are joined, the defer word "?splice" is
\ called with the join address as an argument, allowing for spanning
\ resources (e.g. PMEGS) to be freed if possible.
: free-memrange  ( adr size list -- )
   over 0=  if  3drop exit  then
   is memlist                             ( adr size )

   swap memlist  ['] lower?  find-node    ( size adr prev-node this-node|0 )
   is next-node  is prev-node             ( size adr )

   \ Error check to catch attempts to free already-free memory.

   next-node  if                          ( size adr )
      dup  next-node >adr @  next-end  within
      abort" Freeing memory that is already free"
   then                                   ( size adr )

   \ Try to add this node to the end of the lower piece in the available list

   next-node  if                          ( size adr )
      dup next-end =  if                  ( size adr )

         \ This piece can be added to the end of the lower piece

         swap  next-node >size +!         ( adr )
	 next-node ?splice                ( )  \ Perhaps free PMEG

	 \ Now try to collapse 2 adjacent nodes
	 prev-node memlist <>  if                             ( )
	    next-end prev-start =  if                         ( )
               next-end                                       ( splice-adr )
               next-node >size @  prev-node >size +!          ( splice-adr )
               next-node >adr  @  prev-node >adr   !          ( splice-adr )
	       prev-node delete-after  memrange free-node     ( splice-adr )
               prev-node ?splice          ( )  \ Perhaps free PMEG
	    then
         then

         exit
      then
   then

   \ Try to add this node to the start of the upper piece in the available list
   prev-node memlist <>  if               ( size adr )
      2dup +  prev-start =  if            ( size adr )
         2dup prev-node >adr !            ( size adr size )
         prev-node >size +!               ( size adr )
         +  prev-node ?splice             ( )  \ Perhaps free PMEG
	 exit
      then
   then                                   ( size adr )

   \ Oh bother!  We have to create another node
   swap set-node prev-node insert-after
;

: suitable?  ( alignment size node-adr -- alignment size flag )
   >r r@ >adr @  2 pick round-up          ( alignment size aligned-adr )
   r> node-range -rot -                   ( alignment size node-size waste )
   2dup u<=  if  2drop false  exit  then  ( alignment size node-size waste )
   -                                      ( alignment size aln-node-size )
   over u>=                               ( alignment size flag )
;   
: end-piece-aligned?  ( aln size -- flag )
   next-end           ( aln size end-adr )
   swap - dup rot     ( adr adr aln )
   round-up =         ( flag )
;

: allocate-memrange  ( alignment size list -- phys-adr false | true )

   ['] suitable?  find-node is next-node  is prev-node ( aln+ size+ )

   next-node 0=  if  2drop true  exit  then               ( aln+ size+ )

   2dup  end-piece-aligned?  if                           ( aln+ size+ )
      dup  next-node >size @ =  if                        ( aln+ size+ )
         \ Node is exactly the right size; return the
         \ address and remove the node from the list
         next-node >adr @                                 ( aln+ size+ adr )
         prev-node delete-after  memrange free-node       ( aln+ size+ adr )
      else                                                ( aln+ size+ )
         \ Node is bigger than requested size.  Decrease the size of the
         \ node's region and return the last part of its address range.
         dup negate next-node >size +!                    ( aln+ size+ )
         next-end                                         ( aln+ size+ adr )
      then
   else         \ The piece was not already aligned       ( aln+ size+ )

      \ Change the size of the current node to reflect only the
      \ fragment after the allocated piece.

      next-end  over - 2 pick round-down                  ( aln+ size+ adr )
      2dup +  dup  next-end swap -      ( aln+ size+ adr frag-adr frag-len )
      next-node >adr @ >r                                 \ Save for later
      next-node >size !  next-node >adr !                 ( aln+ size+ adr )

      r> 2dup -                         ( aln+ size+ adr frag-adr frag-len )
      dup if                            ( aln+ size+ adr frag-adr frag-len )
         \ Create a new node for the fragment before the allocated range.
         \ We don't have to worry about splicing it to adjacent nodes,
         \ because we know that it came from the beginning of an existing
         \ separate node.
         set-node next-node insert-after                  ( aln+ size+ adr )
      else                              ( aln+ size+ adr frag-adr frag-len )
         \ There is no fragment before the allocated range.
         2drop                                            ( aln+ size+ adr )
      then                                                ( aln+ size+ adr )
   then                                                   ( aln+ size+ adr )
   nip nip  false                                         ( adr false )
;
headers
