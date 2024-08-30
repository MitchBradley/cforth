\ File tools for ESP32 CForth

\needs $=  : $=  ( $1 $2 -- )  compare 0=  ;

char , value seperator

: (xud,.)       ( ud seperator -- a1 n1 )
   >r
   <#                         \ every 'seperator' digits from right
   r@ 0 do # 2dup d0= ?leave loop
        begin   2dup d0= 0=   \ while not a double zero
        while   seperator hold
            r@ 0  do # 2dup d0= ?leave  loop
        repeat  #> r> drop
;

: (ud,.)        ( ud -- a1 n1 )
   base @                     \ get the base
   dup  #10 =                 \ if decimal use seperator every 3 digits
   swap #8 = or               \ or octal   use seperator every 3 digits
   #4 + (xud,.)               \ display seperators every 3 or 4 digits
;

: ud,.r  ( ud l -- )              \ display double right justified, with seperator
    >r (ud,.) r> over - spaces type ;

: ud,.  ( ud -- ) 0 ud,.r ;       \ display double unsigned, with seperator
: u,.r  ( u l -- ) 0 swap ud,.r ; \ display number unsigned, justified in field, with seperator
: +place  ( adr len adr )  2dup c@ dup >r  + over c!  r> char+ +  swap move ;

create &valid-paths ," /spiffs/" ," /sdcard/"

: valid-path?  ( path& - flag )
   &valid-paths      count 2over $= >r
   &valid-paths +str count 2swap $= r> or
;

: get-path  ( - path$ )  0. -9 open-file drop cscount ;
: expand-name  ( name$ - fullname$ )  negate -9 open-file drop cscount ;

: set-path  ( path$ - )
   2dup valid-path?   if
       0. -9 open-file drop swap cmove
   else
       2drop ." Invalid path. "
   then
;

: open-dir?  ( path& - dirp|0 )
   2dup valid-path?  ?dup 0=    if
       2drop ." Invalid path. " false
       else
           drop open-dir ?dup 0=    if
               ." Can't open directory. " false
       then
   then
;

: list-files  ( path& - )
   base @ >r decimal 0. 2>r                 ( path$ )
   2dup open-dir? ?dup 0<>  if              ( path$ )
       begin  dup next-file ?dup  while  >r ( path$ dirp )
           -rot 2dup pad place              ( dirp path$ )
           r@ file-name cscount             ( dirp path$ file-name$ )
           2dup pad +place pad count        ( dirp path$ file-name$ full-file-name$ )
           r> file-bytes dup >r             ( dirp path& file-name$ file-size )
           #13 u,.r space                   ( dirp path& file-name$ )
           type cr rot                      ( path$ dirp )
           2r> + r> 1 + swap 2>r            ( path$ dirp )
       repeat                               ( path$ dirp )
       close-dir  2drop                     ( )
   else 2drop
   then
   2r> swap 1 u,.r  ."  file(s), " 1 u,.r  ."  bytes."
   r> base ! cr
;

: dir  ( "optinal-path"  -- )
   parse-word dup 0=
    if  2drop get-path  then
   cr ." Directory of: " 2dup type cr list-files
;

alias ls dir

0 value fid
: close-fid  ( -- )  fid close-file drop  ;
: create-fid  ( filename$ -- )  w/o create-file abort" Can't create file"  to fid  ;
: write-fid  ( adr len -- )  fid write-file abort" File write error"  ;
: open-fid  ( filename$ -- )  r/o open-file abort" Can't open file" to fid  ;
: read-fid  ( adr len -- actual )  fid read-file abort" File read error"  ;
: read-line-fid  ( adr len -- len more? )  fid read-line abort" File read error"  ;

warning @ warning off

: delete-file  ( filename$ -- ior )  expand-name delete-file ;

: rename-file  ( $Old $New -- ior )
   expand-name 256 allocate drop dup >r place expand-name
   r@ count rename-file
   r> free drop
;

warning !

: xmodem-to-file:  ( "filename" -- )
   rx   ( adr len )
   safe-parse-word create-fid  write-fid  close-fid
;
alias rf xmodem-to-file:

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

: rm*  ( -- )  \ Removes all files in the active path.
   get-path open-dir? ?dup 0= if  exit  then  ( dirp )
   begin  dup next-file  ?dup  while          ( dirp dirent )
      file-name cscount delete-file drop      ( dirp )
   repeat                                     ( dirp )
   close-dir
;

: rm  ( "filename" -- )
   safe-parse-word  ( name$ )
   2dup " *" $=  if  2drop rm*  else  delete-file drop then
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
