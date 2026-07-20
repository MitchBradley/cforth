Marker -fetching.fth lastacf .name #20 to-column .( 12-10-2024 )

0 value fhandle

: read-no-check ( &dest n fd - )
   s" read-file 2drop " evaluate ; immediate

: |f@| ( rel-adr - ) ( f: - n )
   s>d fhandle reposition-file
   pad /f fhandle read-no-check pad f@ drop ;

: |f!| ( f: r - ) ( rel-adr - )
   s>d fhandle reposition-file
   pad dup f! /f fhandle  write-file 2drop ;

: |@|  ( rel-adr - n )
   s>d fhandle reposition-file  sp@ cell fhandle read-no-check ;

: |2@| ( rel-adr - D )
   s>d fhandle reposition-file
   dup sp@ [ 2 cells ] literal fhandle read-no-check ;

\ \s

