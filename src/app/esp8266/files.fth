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

also modem
: xmodem-to-file:  ( "filename" -- )
   safe-parse-word create-fid                  ( )
   pad $800 start-receive                      ( )
   begin  +receive  while  write-fid  repeat   ( adr len )
   write-fid                                   ( )
   close-fid                                   ( )
;
alias rf xmodem-to-file:
previous

: $print-file  ( filename$ -- )
   open-fid
   begin  pad #100 read-line-fid  while   ( len )
      pad over type         ( len )
      \ If the buffer is full the end-of-line has not yet been read
      #100 <  if  cr  then  ( )
   repeat                   ( 0 )
   drop                     ( )
   close-fid
;
: cat  ( "filename" -- )  safe-parse-word  $print-file  ;

: rm*  ( -- )
   first-file                        ( dirent )
   begin  ?dup  while                ( dirent )
      file-name cscount delete-file  ( dirent )
      next-file                      ( dirent )
   repeat
;
\needs $= : $= ( $1 $2 -- same? )  compare 0=  ;
: rm  ( "filename" -- )
   safe-parse-word  ( name$ )
   2dup " *" $=  if  2drop rm*  else  delete-file  then
;

\ Create a new file and accept lines from the terminal,
\ copying them to the file until a line with a single
\ "." is entered.
: new-file:  ( "filename" -- )
   safe-parse-word create-fid
   ." Enter lines, finish with a . on a line by itself" cr
   begin
      ." > "
      pad #100 accept     ( len )
      pad swap            ( adr len )
      2dup " ." compare   ( adr len more? )
   while
      write-fid  " "n" write-fid
   repeat
   2drop close-fid
;
