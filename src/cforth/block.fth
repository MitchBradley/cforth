\ This file implements standard Forth BLOCKs
\ The buffer management scheme is based on an LRU (Least Recently Used)
\ replacement policy.  This implementation was adapted from the buffer
\ management code in F83; thanks to Mike Perry and Henry Laxen.

decimal

nuser scr

\NCF nuser blk
\NCF : >in  ( -- adr )  bfcurrent  ;

nuser offset		\ Used to bias block numbers
0 offset !

nuser block-fid		\ 0 for global blocks, fileid for blocks in files
0 block-fid !

\needs d=  : d=  ( n1a n1b n2a n2b -- f )  rot =  -rot =  and  ;

\ Interfaces to the system-dependent code that does the actual I/O

defer read-block    (s adr block# fileid -- )
defer write-block   (s adr block# fileid -- )

1024 constant b/buf
  64 constant c/l

\ The order of >block# and >file# must be preserved, and they
\ must be at the start of the structure.  The program accesses
\ them both at once with    <header-address> 2@

struct ( buffer-header )
   /n field >file#
   /n field >block#
   /n field >bufadd
   /n field >bufflags	\ -1: dirty block  0: clean block  1: no block
constant /bufhdr

\ : /bufhdr*  ( u1 -- u2 )  /bufhdr *  ;
: /bufhdr*  ( u1 -- u2 )  4 <<  ;	\ Optimization for 32-bit machines

\ Some debugging tools
\ : .bh ( buffer-header -- )
\    dup >block#      ." Block# "     @ .
\    dup >file#       ."   File# "    @ .
\    dup >bufadd      ."   Address "  @ .
\        >bufflags    ."   Flags "    @ .
\ ;
\ : .bhs (s -- )  #buffers 1+ 0  do  i >header .bh  cr  loop  ;
\ 
\ : .read  ( bufadd file block -- )  ." Read "  . . . cr ;
\ : .write ( bufadd file block -- )  ." Write " . . . cr ;
\ ' .read  is read-block
\ ' .write is write-block

\ Allocation of data structures

4 value #buffers

#buffers 1+ /bufhdr*  buffer: bufhdrs
b/buf #buffers *   buffer: first

: >header    (s n -- adr )   /bufhdr* bufhdrs +   ;
: >update    (s -- adr )   1 >header >bufflags  ;

: update   (s -- )  >update on   ;
: discard  (s -- )  1 >update !  ;

\ Write buffer if it is dirty
: ?write-block  ( buf-header -- buf-header )
   dup >bufflags @ 0<  if
      dup >bufadd @ over 2@ write-block
      dup >bufflags off
   then
;

\ Discard least-recently-used buffer, writing it if necessary,
\ and move it to the head of the list.
: replace-buffer   (s -- )
   #buffers >header  ?write-block                    ( last-buffer-header )
   >bufadd @  bufhdrs >bufadd !                      ( ) \ Copy buffer address
   bufhdrs  dup /bufhdr +  #buffers /bufhdr*  move   ( ) \ Move into position
   discard					 	 \ No assigned block
;

: file-buffer   (s u fileid -- adr )
   pause

   \ Quick check in case the first buffer in the cache is the one we want
   swap  offset @ +  swap                   ( u' fileid )
   2dup   1 >header 2@   d=  0=  if         ( u fileid )

      \ Search the buffer cache
      true   #buffers 1+ 2  do              ( u fileid true)
         drop  2dup i >header 2@ d=  if     ( u fileid )
            \ Found it; move it to the head of the list
            i >header                       ( u fileid &hdrN)
            dup bufhdrs /bufhdr move        ( u fileid &hdrN )  \ temp slot
            >r  bufhdrs dup /bufhdr +       ( u fileid &hdr0 &hdr1 )
            over r> swap  -  move           ( u fileid )
            false leave                     ( u fileid false )
         then                               ( u fileid )
         true                               ( u fileid true )
      loop                                  ( u fileid not-in-cache? )

      if  2dup bufhdrs 2!  replace-buffer  then    ( u fileid )
   then                                     ( u fileid )
   2drop
   1 >header >bufadd @                      ( buffer-adr )
;

: file-block    (s u fileid -- a )
   file-buffer                  ( adr )
   >update @ 0>  if		( adr )		  \ Contents invalid?
      1 >header  dup >bufadd @	( adr hdr buf )
      swap 2@  read-block	( adr )		  \ Read it in
      >update off               ( adr )           \ block is clean
   then				( adr )
;

: empty-buffers   (s -- )
   first    b/buf #buffers *      erase		\ Clear buffers
   bufhdrs  #buffers 1+ /bufhdr*  erase		\ Clear headers
   first                                       ( adr )
   1 >header  #buffers /bufhdr*  bounds  do    ( adr )
      -1  i >block# !                          ( adr )	\ Invalid block#
      dup i >bufadd !                          ( adr )	\ Point to buffer
      b/buf +                                  ( adr' )
   /bufhdr +loop                               ( adr' )
   drop
;

: save-buffers   (s -- )
   1 >header  #buffers /bufhdr*  bounds  do    ( )
      i >block# @  -1 <>  if			\ Flush valid blocks
         i ?write-block drop
      then
   /bufhdr +loop
;

: buffer  (s n -- a )   block-fid @ file-buffer  ;
: block   (s n -- a )   block-fid @ file-block   ;
: flush   (s -- )  save-buffers  0 block drop  empty-buffers  ;

\NCF : block-sizeop  ( fid -- n )  drop b/buf  ;
\NCF : load-file  ( block# fileid -- )
\NCF    blk @ >r  over blk !  ( block# fileid )
\NCF    file-block
\NCF 
\NCF    \ Create a stream descriptor
\NCF    get-fd					\ Get a descriptor
\NCF 
\NCF    bfbase @  b/buf  move			\ Copy in buffer contents
\NCF    bfbase @  b/buf +  dup bftop !  bfend !	\ Set limit pointers
\NCF 
\NCF    0 modify					\ Low-level stream operations
\NCF    ['] block-sizeop  ['] noop       ['] drop
\NCF    ['] nullseek      ['] fakewrite  ['] nullread
\NCF    setupfd
\NCF 
\NCF    file @ (fload)
\NCF    r> blk !
\NCF ;
\NCF : load  ( block# -- )  block-fid @ load-file  ;
\NCF 
\NCF \ Backslash (comment to end of line) for blocks
\NCF : \  \ rest-of-line  ( -- )
\NCF    input-file @ file !
\NCF    sizeop @  ['] block-sizeop  =  if
\NCF       bfcurrent @  bfbase @ -                   ( offset-into-buffer )
\NCF       c/l 1- +   c/l 1- not  and                ( offset-of-next-line )
\NCF       bfbase @ +  bflimit @  umin  bfcurrent !  ( )
\NCF    else
\NCF       [compile] \
\NCF    then
\NCF ; immediate

\CF : load  ( block# -- )
\CF    blk @ >r  >in @ >r  tib >r  #tib @ >r
\CF    blk !  0 >in !  blk @ block  'tib !  1024 #tib !
\CF    interpret
\CF    r> #tib !  r> 'tib !  r> >in !  r> blk !
\CF    blk @  if  blk @  block 'tib !  then
\CF ;
\CF 
\CF \ Backslash (comment to end of line) for blocks
\CF : \  \ rest-of-line  ( -- )
\CF    blk @  if
\CF       >in @ negate  c/l mod  >in +!
\CF    else
\CF       [compile] \
\CF    then
\CF ; immediate

: thru   (s n1 n2 -- )  2 ?enough   1+ swap ?do   i load   loop   ;
: +thru  (s n1 n2 -- )  blk @ + swap   blk @ + swap   thru   ;
: -->    (s -- )  blk @ 1+ load  ;   immediate

: list  ( scr# -- )
   dup scr !  ." Screen " dup .  cr  ( scr# )
   block  b/buf  bounds  do   i  c/l  type  cr  c/l +loop
;
: n  ( -- )   1 scr +!  ;
: b  ( -- )  -1 scr +!  ;
: l  ( -- )  scr @ list  ;

empty-buffers
