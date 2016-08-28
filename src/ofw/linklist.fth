\ See license at end of file

\ Linked list words.  Assumes a singly-linked list, where the
\ first element in each list node is the link.  Links point to links,
\ and the last link contains 0.
\
\ list:  \ name  ( -- )   Child: ( -- list )
\	Defines a named list.
\
\ listnode   ( -- offset )
\	Used like "struct" to begin the creation of a list node structure
\	The link field is automatically included in the structure.
\
\ nodetype:  \ name  ( size -- )   Child: ( -- nodetype )
\	Defines a new named node type.  Example:
\
\		listnode
\			/n field >node-data
\		nodetype: integer-node
\
\ node-length  ( nodetype -- len )
\	Returns the length of a node of the indicated type.
\
\ allocate-node  ( nodetype -- node )
\	Allocates a node of the indicated type.
\
\ more-nodes  ( #nodes nodetype -- )
\	Adds "#nodes" more nodes to the free list for the indicated node type.
\	Automatically executed by "allocate-node" if necessary.
\
\ free-node  ( node nodetype -- )
\	Returns the indicated node to the free list for the indicated node
\	type.
\
\ insert-after  ( new-node-adr prev-node-adr -- )
\	Inserts "new-node" into a linked list after "prev-node" (and before
\	the node which was the successor of "prev-node").
\
\ delete-after  ( prev-node -- deleted-node )
\	Removes the node AFTER the argument node.  The deleted node is
\	returned so its memory can be freed or whatever.
\
\ find-node  ( ??? list acf -- ??? prev-node this-node|0 )
\	Searches the linked list "list", executing the procedure "acf"
\	for each node in the list.  Returns the node for which "acf"
\	returned "true", and also the preceding node.  See the comments
\	in the code for more information.
\
\ find-node?  ( ??? list acf -- ??? false | ??? node true )
\	Searches the linked list "list", executing the procedure "acf"
\	for each node in the list.  Returns the node and true if found,
\	or false if not found.

alias list: variable

alias listnode /n

: nodetype:  \ name  ( size -- )
   aligned  create 2 /n* user#,  0 over ! na1+ !     \ Free list, size
   does> >user
;
: node-length  ( nodetype -- len )  na1+ @  ;

alias >next-node @     ( node-adr -- next-node-adr )

: list-end?  ( node-adr -- flag )  >next-node @ 0=  ;

\ Inserts "new-node" into a linked list after "prev-node" (and before
\ the node which was the successor of "prev-node").

: insert-after  ( new-node-adr prev-node-adr -- )
   2dup >next-node    ( new-node prev-node  new-node succ-node )
   swap !             ( new-node prev-node  )
   !                  ( )
;

\ Delete-after removes the node AFTER the argument node
\ The deleted node is returned so its memory can be freed or whatever.

: delete-after  ( prev-node -- deleted-node )  dup @ tuck @ swap !  ;


\ find-node  traverses the list, executing "acf" between each pair of nodes.
\ When "acf" returns true, find-node returns the addresses of the pair of
\ nodes.  If the list is exhausted before "acf" returns true, the last node
\ and 0 is returned.

\ "acf" is called as:
\     ( ??? node-data-adr -- ??? flag )
\
\ ??? is whatever was on the stack underneath "list" and "acf" when "find-node"
\ was called.  It would typically be a test value used by the "acf" function.
\ "acf" is only called with valid node addresses, assuming that the list is
\ well-formed.  In other words, "acf" will not be called with either the
\ list head node or with the null node past the end of the list.

\ The data and return stack manipulations in find-node are pretty grim.
\ Reasons:
\ (a) We want the stack diagram for the action routine to be clean in order
\     to make find-node easy to use.  Thus we do not wish to expose the
\     loop information on the data stack when the action routine is called.
\ (b) The arguments to the action routine are arbitrary in number, thus
\     we cannot store loop information underneath them.
\ (c) This routine needs to be reentrant, since it is used by the alarm
\     interrupt handler.  Thus we cannot use variables.

: find-node  ( ??? list acf -- ??? prev-node this-node|0 )
   \ Guard against null lists
   over 0=  if  drop 0 exit  then
   >r >r 0 >r                    ( ??? )       ( r: acf list 0 )
   begin                         ( ??? )       ( r: acf prev-node old-node )
      r> drop  r>                ( ??? new-this-node )        ( r: acf )
      dup >next-node dup 0=  if  ( ??? this-node next-node )  ( r: acf )
         r> drop exit            ( ??? last-node 0 )          ( r: acf )
      then		         ( ??? this-node next-node )  ( r: acf )
      tuck r@ -rot  >r >r        ( ??? data-adr acf ) ( r: acf next this )
      execute                    ( ??? flag )         ( r: acf next this )
   until                         ( ??? )              ( r: acf next this )
   r> r> r> drop                 ( ??? prev-node this-node )
;

: find-node?  ( ??? list acf -- ??? false | ??? node true )
   find-node ?dup  if   ( ??? prev-node this-node )
      nip true          ( ??? node true )
   else                 ( ??? prev-node )
      drop false        ( ??? false )
   then                 ( ??? false | ??? node true )
;

\ Here's how "find-node" could be used to locate the insertion point
\ for a list sorted in ascending order of the second field.

\ : larger?  ( key node-data-adr -- key flag )  na1+ @ over u>  ;
\ : insertion-point  ( key list -- node )   ['] larger?  find-node  drop  ;


\ Locates the last node in the list.  The routine used with "find-node"
\ is "0=", which always returns "false" because find-node is guaranteed
\ not to call its test routine with a 0 node.

: last-node  ( list -- node-adr )  ['] 0=  find-node  drop  ;

\ Add new nodes to the free list of "nodetype", from the block of memory
\ "adr len", whose length must be a multiple of that nodetype's node length.
: add-nodes  ( adr len nodetype -- )
   dup node-length                     ( adr len nodetype /node )

   \ Find the end of the free list
   swap last-node                      ( adr len /node last-node )

   \ Link new nodes onto free list
   2swap bounds  ?do                   ( /node prev-node )
      i swap !  i                      ( /node prev-node' )
   over +loop                          ( /node prev-node' )
   0 swap !   drop                     ( )
;

\ Adds "#nodes" more nodes to the free list for the indicated node type.
\ Automatically executed by "allocate-node" if necessary.

: more-nodes  ( #nodes nodetype -- )
   tuck node-length *                  ( nodetype total-size )
   dup alloc-mem                       ( nodetype total-size adr )
   swap rot  add-nodes
;

\ Allocates a node of the indicated type by removing a node from the
\ free list.  If the free list start out empty, allocate-node first
\ calls more-nodes to populate the free list.

: allocate-node  ( nodetype -- node )
   dup @  0=  if                       ( nodetype )
      d# 10 over more-nodes            ( nodetype )
   then

   dup >next-node dup >next-node       ( nodetype first-node second-node )
   rot !                               ( first-node )
;

\ Adds the node to the free list for the indicated node type.

: free-node  ( node nodetype -- )  insert-after  ;
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
