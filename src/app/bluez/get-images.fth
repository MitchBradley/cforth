\ Convenience wrappers for reading binary files into memory

0 value bin-file
0 value bin-name-adr
0 value bin-name-len
0 value bin-file-buf
: bin-filename$  ( -- adr len )  bin-name-adr bin-name-len  ;

$40000 constant /flash-max
0 value /bin-file
: ?alloc-flash-buf  ( -- )
   bin-file-buf 0=  if
      /flash-max alloc-mem  to bin-file-buf
   then
;
: reopen-bin-file  ( -- )
   bin-name-adr bin-name-len r/o open-file  ( fid ior )
   swap to bin-file   ( ior )
   if
      ." Can't open bin file "
      bin-name-adr bin-name-len type  cr
      abort
   then
   ?alloc-flash-buf
   bin-file-buf /flash-max erase
   bin-file-buf /flash-max bin-file read-file  ( n ior )
   abort" Can't read binary file"  to /bin-file
;
: open-bin-file  ( name$ -- )
   to bin-name-len  to bin-name-adr
   reopen-bin-file
;
