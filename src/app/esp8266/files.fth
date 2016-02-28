\ File tools for ESP8266 CForth

: dir  ( -- )
   first-file          ( dirent )
   begin  ?dup  while  ( dirent )
      dup file-bytes   ( dirent size )
      push-decimal 6 u.r pop-base        ( dirent )
      space  file-name cscount type cr   ( )
      next-file        ( dirent )
   repeat
;
alias ls dir

0 value fid
: close-fid  ( -- )  fid close-file drop  ;
: create-fid  ( filename$ -- )  w/o create-file abort" Can't create file"  to fid  ;
: write-fid  ( adr len -- )  fid write-file abort" File write error"  ;
: open-fid  ( filename$ -- )  r/o open-file abort" Can't open file" to fid  ;
: read-fid  ( adr len -- actual )  fid read-file abort" File read error"  ;
: read-line-fid  ( adr len -- len more? )  fid read-line abort" File read error"  ;

: xmodem-to-file:  ( "filename" -- )
   rx   ( adr len )
   safe-parse-word create-fid  write-fid  close-fid
;
alias rf xmodem-to-file:

: cat  ( "filename" -- )
   safe-parse-word open-fid
   begin  pad #100 read-line-fid  while   ( len )
      pad over type         ( len )
      \ If the buffer is full the end-of-line has not yet been read
      #100 <  if  cr  then  ( )
   repeat                   ( 0 )
   close-fid
;
