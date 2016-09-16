\ Sends a file in chunks

\ Files sent with XMODEM are padded at the end with ^Z
\ Ideally they would be removed by xmodem-to-file:
: remove-eofs  ( adr len -- adr len' )
   begin  dup  while
      2dup + 1- c@ $1a <>  if  exit  then
      1-
   repeat
;

: get-chunk  ( -- adr len )
   rx-pcb tcp-sendbuf  /chunk min      ( thislen )
   chunk swap  ['] read-fid catch  if  ( x x )
      2drop 0                          ( len )
   then                                ( len )
   chunk swap                          ( adr len )
   remove-eofs                         ( adr len' )
;

: send-file-data  ( -- )
   begin                ( )
      get-chunk         ( adr len )
   dup while            ( adr len )
      tcp-write-wait    ( )
   repeat               ( adr 0 )
   2drop                ( )
   close-fid            ( )
;

defer send-file-not-found  ( -- )
' noop is send-file-not-found

: send-file  ( filename$ -- )
   ['] open-fid catch  if   ( x x )
      2drop                 ( )
      send-file-not-found   ( )
   else                     ( )
      send-file-data        ( )
   then                     ( )
;
