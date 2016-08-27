\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: cirstack.fth
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
id: @(#)cirstack.fth 1.6 03/12/08 13:22:21
purpose: 
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Circular stack defining words
\
\ 10 cirstack: foo    Create a new stack named foo with space for 10 numbers
\ 123 foo push        Push the number 123 on the stack foo
\ foo pop             Pop the top element from the stack foo onto the data stack
\
\ Advantages of a circular stack:
\    does not have to be cleared
\    cannot overflow or underflow
\
\ Disadvantages:
\    can silently lose data
\    implementation is cumbersome
\
\ Applications:
\    Useful for implementing user interfaces where you want to remember a
\    limited amount of "history", such as the last n commands, or the
\    last n directories "visited", but it is not necessary to guarantee
\    unlimited backtracking.

\ Implementation notes:
\    The circular stack data structure contains the following elements:
\        stack data   Space to store the stacked numbers
\        current      Offset into stack data of the next element to pop
\        limit        Size of stack data plus 1 cell
\
\    The elements are located as follows:
\        pfa:   user#   limit
\
\    user# is the offset of a user area location containing the address of
\    an allocated memory buffer.  That buffer contains "current" and "stack
\    data".
\
\    Note that this parameter field is intentionally the same as the parameter
\    field of word defined by "buffer:".  This allows us to automatically
\    allocate the necessary storage space using the buffer: mechanism.
\
\        user area location:  buffer-address
\        buffer-address:      current   stack-data ...

headerless
\ Implementation factor
: stack-params  ( stack -- adr limit current )
   dup  /user# + unaligned-@  /n -  ( stack limit )
   swap do-buffer                   ( limit adr )
   tuck @                           ( adr limit current )
;
headers

\ Creates a new stack
: circular-stack:  \ name  ( #entries -- )
   create
   here body> swap    ( acf #entries )
   1+ /n*             ( acf size )
   0 /n user#,  !     ( acf size )  ,   ( acf )
   buffer-link link@  link,  buffer-link link!
;

\ Adds a number to the stack
: push  ( n stack -- )
   stack-params  na1+       ( n adr limit next )
   tuck  <=  if             ( n adr next )
      drop 0                ( n adr next' )     \ Wrap around
   then                     ( n adr next' )
   2dup swap !              ( n adr next' )
   + na1+ !
;

\ Removes a number from the stack
: pop  ( stack -- n )
   stack-params             ( adr limit current )
   ?dup  if                 ( adr limit current )
      nip 2dup /n - swap !  ( adr current )     \ Decrement current
      +                     ( data-adr- )
   else                     ( adr limit )
      /n - over !           ( data-adr- )       \ Wrap around
   then
   na1+ @
;

\ Returns, without popping, the number on top of the stack
: top@  ( stack -- n )
   stack-params             ( adr limit current )
   dup  if                  ( adr limit current )
      nip  +                ( data-adr- )
   else                     ( adr limit current )
      2drop                 ( data-adr- )       \ Wrap around
   then
   na1+ @
;
