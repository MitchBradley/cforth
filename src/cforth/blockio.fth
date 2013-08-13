\ The low level I/O used to implement standard Forth BLOCKs

decimal

vocabulary sys
also sys also definitions
20 constant max#files

: open-block-file  ( adr len -- fid )
   2dup r/w open-file  if                 ( adr len fid )
      drop  ." Can't open "  type  abort  ( )
   then                                   ( adr len fid )
   nip nip
;

nuser default-block-fid		\ File referenced by block-fid=0
0 default-block-fid !

: map-fid  ( fid -- fid' )
   ?dup  0=  if				\ Not the default block space
      default-block-fid @  0=  if	\ Open on first access
         " forth.blk"  open-block-file  default-block-fid !
      then
      default-block-fid @
   then
;

\ Seek to the correct starting address and prepare the arguments
\ to the gem read or write call
: setio  ( address block# fid -- address b/buf fid )
   map-fid                                  ( address block# fid' )
   swap b/buf * 0  2 pick reposition-file   ( address fid ior )
   abort" Can't set block file position"    ( address fid )
   b/buf swap                               ( address b/buf fid )
;

: ?disk-abort  ( #transferred ior -- )
   0=  if  b/buf =  if  exit  then  else  drop  then  \ Exit if okay
   true abort" Disk error"
;
: (read-block)   ( address block# file -- )  setio read-file  ?disk-abort  ;
: (write-block)  ( address block# file -- )  setio write-file ?disk-abort  ;

: install-block-io  ( -- )
   ['] (read-block)  is read-block
   ['] (write-block) is write-block
   0 default-block-fid !
;
install-block-io
\ : (cold-hook  (cold-hook install-block-io  ;
forth definitions


: .file  ( fid -- )  drop ." File name unknown"  ;

previous previous definitions
