\ See license at end of file
purpose: User interface commands for file manipulation

\needs 2nip  : 2nip  ( $1 $2 -- $2 )  2swap 2drop  ;

\needs internal alias internal headerless
\needs public   alias public   headers
\needs private  alias private  headerless

internal

: dev&path  ( path$ -- dev$ file-path$ )  [char] \ split-string  ;

: $volatile?  ( $ -- $ flag )  over in-dictionary? 0=  over 0<>  and  ;
: ?save-string  ( $1 -- $2 )
   $volatile?  if               ( $1 )
      dup alloc-mem swap        ( adr1 adr2 len )
      2dup 2>r move 2r>         ( $2 )
   then
;
: ?release-string  ( $ -- )  $volatile?  if  free-mem  else  2drop  then  ;

variable current-volume

: >directory  ( xt -- adr )  >body >user  ;

public

3 actions
action:  body> current-volume token!  ;
action:  body> >directory >r  r@ 2@ ?release-string  ?save-string r> 2!  ;
action:  body> >directory 2@  ;
: volume:  ( "name" -- )  create  0 0  2 /n* user#,  2!  use-actions  ;

: current-volume-name  ( -- adr len )
   current-volume token@ 0= abort" There is no current volume"
   current-volume token@ >name name>string
;
: pcwd  ( -- name$ )
   current-volume-name type
   current-volume token@ >directory 2@  dup  if  type  else  2drop  ." \"  then
   cr
;

volume: A:
volume: B:
volume: C:
volume: D:
volume: E:
volume: F:

C:

internal

d# 256 buffer: file-path-buf
d# 32  buffer: drive-name
: +path  ( adr len -- )  file-path-buf $cat  ;
: +\  ( -- )  " \" +path  ;

: file&dir  ( path$ -- basename$ dirname$ )  [char] \ right-split-string  ;
: parse-volume  ( $1 -- path$ volume$ )
   " :" lex  if  drop  else  current-volume-name 1-  then  ( path$ volume$: )
;
: drive-volume  ( -- adr len false | xt true )
   drive-name count  dup  if    ( adr len )
      + 1- c@ [char] : <>  if   ( )
         " :" drive-name $cat   ( )
      then                      ( )
      drive-name count          ( adr len )
   then
   $find
;
: insert-directory  ( -- )
   drive-volume  if
      2 perform-action  dup  if  +path  else  2drop  +\  then
   else
      2drop  +\
   then
;
\ Removes the first character from tail$ and puts it at the end of head$
: copy\  ( head$ tail$ -- head$' tail$' )
   dup  if  over c@ >r  2over +  r> swap c!  rot 1+ -rot  1 /string  then
;
: remove..  ( $1 -- $2 )
   dev&path copy\                             ( head$ tail$ )
   begin  dup  while                          ( head$ tail$ )
      dev&path                                ( head$ next$ tail$' )
      2over " .."  $=  if                     ( head$ next$ tail$' )
         \ ".." found - remove the previous directory component and
         \ any backslash at the beginning of the tail string
         2>r                                  ( head$ next$ )
         2drop                                ( head$ )
         1-     \ Remove trailing \           ( head$' )
         [char] \ right-split-string          ( right$ left$ )
         dup  if  2nip  else  2drop 1+  then  ( head$' )
         2r>  dup  if  1 /string  then        ( head$' tail$' )
      else                                    ( head$ next$ tail$' )
         \ ".." not found - append the current name component 
         \ to the end of the head string
         2>r   >r >r                          ( head$ r: tail$ next-len,adr)
         2dup +  r> swap r@ move              ( head$ r: tail$ next-len)
         r> +                                 ( head$' r: tail$' )
         2r>  copy\                           ( head$' tail$' )
      then                                    ( head$' tail$' )
   repeat                                     ( $2 null$ )
   2drop
;

: ?+:  ( adr len -- adr len' )
   \ If the last character is already a colon or a comma, just exit
   file-path-buf count  + 1- c@                          ( last-char )
   dup [char] : =  swap [char] , =  or  if  exit  then   ( )

   \ Otherwise, append a colon if the last pathname component of the string
   \ doesn't already contain one or a comma if it does.
   file-path-buf count  [char] / right-split-string      ( tail$ head$ )
   2drop  [char] :  split-string                         ( head$ tail$ )
   if  " ,"  else  " :"  then  +path  3drop              ( )
;
: canonical-path  ( $1 -- $2 )
   \ In the following code, file-path-buf is used to store the output
   \ string as it is being constructed.  drive-name is an intermediate.
   0 file-path-buf c!                                    ( $1 )
   parse-volume                                          ( path$ volume$ )
   drive-name place                                      ( path$ )

   \ If the name could be an alias, convert it to lower case, so that,
   \ for example, "C:" will work
   drive-name count nip 0<>  if                          ( path$ )
      drive-name count drop c@  [char] / <>  if          ( path$ )
         drive-name count lower                          ( path$ )
      then                                               ( path$ )
   then                                                  ( path$ )

   \ If the drive name matches a user-created configuration variable,
   \ replace it with that variable's value
   drive-name count  2dup $getenv  if                    ( path$ drive$ )
      2dup not-alias?  0=  if  2swap 2drop  then         ( path$ drive$' )
   else                                                  ( path$ drive$ exp$ )
      2swap 2drop                                        ( path$ drive$' )
   then                                                  ( path$ drive$' )
                                                         ( path$ drive$ )
   +path                                                 ( path$ )

   \ XXX we probably should insert a ":" or a "," after the expanded name
   ?+:

   \ Insert working directory if the path name is relative
   dup  if                                               ( path$ )
      [char] ,  split-string                             ( head$ tail$ )

      dup  if                                            ( head$ ,tail$ )
         \ If tail$ is not empty, there was a , in the path
         \ so we copy the head$ to the path buffer verbatim
         2swap +path  " ," +path                         ( tail$ )
         1 /string                                       ( tail$' )
      else                                               ( head$ null$ )
         2drop                                           ( head$ )
      then                                               ( path$ )

      \ Insert directory if path string doesn't start with '\'
      over c@ [char] \ <>  if  insert-directory  then    ( path$ )
   else                                                  ( path$ )
      \ Insert directory if path string is empty
      insert-directory                                   ( path$ )
   then                                                  ( path$ )

   +path                                                 ( )

   file-path-buf count                                   ( $2 )

   \ Edit the output string to eliminate any "dir/.." sequences
   remove..                                              ( $2' )
;

: case-insensitive?  ( ihandle -- flag )
   \ If the "case-sensitive" property does not exist,
   \ then we use case-insensitive pattern matching
   " case-sensitive"  rot ihandle>phandle get-package-property  if  ( )
      \ Property does not exist; use case-insensitive matching
      true
   else                                                        ( adr len )
      \ Property exists; use case-sensitive matching
      2drop false
   then
;

0 value search-ih
0 value search-index
0 value search-case
d# 64 buffer: search-pattern
: $open-canonical-file  ( canonical-path$ -- ih )
   open-dev dup 0= abort" Can't open file"
;
: $open-file  ( path$ -- ih )
   canonical-path $open-canonical-file
;
: $open-dir   ( path$ -- ih )  open-dev dup 0= abort" Can't open directory"  ;
: open-directory  ( path$ -- file$ ih )  canonical-path file&dir  $open-dir  ;
: begin-search  ( pattern$ -- )
   open-directory      ( base-pattern$ ihandle )
   to search-ih  search-pattern place
   0 to search-index
   search-ih case-insensitive? to search-case
;
: close-search  ( -- )  search-ih close-dev  ;
: drop-attributes  ( s m h m d y attr len -- )  2drop 3drop 3drop  ;
: another-match?  ( -- false | 8*attributes name$ true )
   begin  search-index " next-file-info"  search-ih  $call-method  while
      ( index s m h d m y len attr name$ )
      2>r  8 roll to search-index      ( 8*n r: name$ )
      search-case  search-pattern count  2r@  pattern-match?  if
         2r> true exit
      else
         2r> 2drop drop-attributes
      then
   repeat
   close-search  false
;
: first-match  ( pattern$ -- false | 8attributes name$ true )
   begin-search  another-match?  dup  if  close-search  then
;

: dir-attr?  ( attribute -- flag )  h# f000 and  h# 4000 =  ;
: dir?  ( 8attributes -- flag )  >r drop 3drop 3drop r> dir-attr? ;

\ Standard file type encoding; this is a melange of Unix and DOS file
\ type semantics.  We map the DOS types into the Unix encoding where
\ that will work, and then add on some extra bits for the DOS-specific
\ things.  Portable client programs should not depend upon any of the
\ OS-specific bits or file types.

\ Permissions:
\    Low 9 bits are Owner RWX, Group RWX, World RWX using the well-known
\    Unix encoding.  For DOS, the only two possibilities are r-xr-xr-x
\    and rwxrwxrwx.  (Portable programs should pay attention to only the
\    h# 00002 bit, i.e. the "world writeable" bit).
\ File Types:
\    The h# f000 nibble is the file type.  The encoding are the same as
\    the Unix types (see stat.h), with some DOS-specific types inserted
\    in otherwise-unused slots.  These file types are mutually exclusive.
\    h#  1000   FIFO (Unix-specific)
\    h#  2000   Character special (Unix-specific)
\    h#  3000	Volume Label (DOS-specific)
\    h#  4000	Subdirectory
\    h#  6000   Block special (Unix-specific)
\    h#  8000	Ordinary File
\    h#  a000	Symbolic link (Unix-specific)
\    h#  c000   Socket (Unix-specific)
\ Other attributes: (DOS-specific)
\    DOS-specific attributes other then file type are mutually independent
\    h# 10000	Hidden
\    h# 20000	System
\    h# 40000	Archive
\ Other attributes: (Unix-specific)
\    h# 00200   Sticky
\    h# 00400   Set GID
\    h# 00800   Set UID

: ?.c  ( n mask char -- )  -rot  and  if  emit  else  drop  ." -"  then  ;
: .rwx  ( n -- )  dup 4  ascii r ?.c  dup 2  ascii w  ?.c  1 ascii x ?.c  ;
: .attrs  ( attributes -- )
   dup h# 20000  ascii S  ?.c
   dup h# 10000  ascii H  ?.c
   dup h# 40000  ascii A  ?.c
   dup h#  f000  and  case
       h#  4000  of  ." d"  endof
       h#  3000  of  ." v"  endof
       h#  8000  of  ." -"  endof
       h#  a000  of  ." l"  endof
                     ." ?"	\ Don't bother decoding specials and sockets
   endcase
   dup 6 >> .rwx  dup 3 >> .rwx  .rwx
   space
;

: .file  ( s m h d m y len atr name$ -- )
   2>r >r r@ .attrs  base @ >r decimal 9 u.r r> base !
   2 spaces  .date space .time 2 spaces  r> 2r> 2dup type  ( atr name$ )

   \ display the referent of links
   rot  h# f000 and h# a000 =  if                          ( name$ )
      " $readlink" search-ih  ['] $call-method  catch  if  ( x x x x x )
         5drop                                             ( )
      else                                                 ( t | name$' f )
         0=  if  ."  -> " type  then                       ( )
      then                                                 ( )
   else                                                    ( name$ )
      2drop                                                ( )
   then                                                    ( )
;

public

: $delete1  ( path$ -- )
   open-directory ?dup 0= abort" Can't open directory"      ( name$ dir-ih )
   >r  " $delete!" r@ $call-method  ( error?  r: dir-ih ) 
   r> close-dev                     ( error? )
   abort" Can't delete file"  
;
' $delete1 to _ofdelete

: $delete-all  ( pattern-adr pattern-len -- )
   begin-search  begin  another-match?  while           ( 8*attributes name$ )
      \ Check attributes to see if this is a directory
      2 pick dir-attr? if
	 \ Filter out '.' and '..' from printing
	 2dup " ." $= >r 2dup " .." $= r> or if           ( 8*attributes name$ )
	    2drop                                         ( 8*attributes )
	 else						  ( 8*attributes name$ )
	    ." Not deleting directory: " type cr          ( 8*attributes )
	 then						  ( 8*attributes )
     else						  ( 8*attributes name$ )
	2dup " $delete"  search-ih  $call-method          ( 8*n name$ err? )
	if  ." Can't delete " type cr  else  2drop  then  ( 8*n )
     then                                                 ( 8*attributes )
     drop-attributes					  ( )
   repeat                                                 ( )
;

internal

: last-char  ( adr len -- adr len char )  2dup + 1- c@  ;

: separator?  ( adr len -- adr len flag )
   last-char  dup [char] : =  swap [char] \ =  or
;
: is-pattern?  ( adr len -- flag )
   false -rot  bounds ?do
      i c@  dup [char] * =  swap [char] ? =  or  if  0= leave  then
   loop
;

\ If the pathname contains no pattern matching characters, and it
\ refers to a directory, append a "\" so that later code will append
\ a "*", thus causing all the files to be listed.
: add\  ( pstr -- )  " \" rot $cat  ;
: ?add\  ( adr len -- adr' len' )
   2dup is-pattern?  0=  if                     ( adr len )
      separator?  if  exit  then                ( adr len )
      2dup  first-match  if                     ( adr len 8*attrs name$ )
         2drop  dir?  if                        ( adr len )
            string2 pack  add\  string2 count   ( adr' len' )
         then                                   ( adr len )
      then                                      ( adr len )
   then                                         ( adr len )
;

: .fs-name  ( -- )
   " name"  search-ih ihandle>phandle get-package-property  0=  if
      get-encoded-string type cr
   then
;

public

: $dir  ( pattern$ -- )
   \ If the pattern$ is null or has no name component, add a "*" to the end
   dup  if   ?add\  separator?  else  true  then        ( pattern$ no-name? )

   if  string2 pack  " *" rot $cat  string2 count  then

   begin-search
   .fs-name
   begin  another-match?  while           ( 8*attributes name$ )
      .file cr
      exit?  if  close-search exit  then
   repeat
;
: dir  ( "pattern" -- )  parse-word  $dir  ;
: dir" ( "pattern"" -- )  [char] " parse  $dir  ;

defer handle-dirent  ( 8*attributes $name )

d# 256 buffer: ls-r-name
0 value ls-r-len

: ls-r-name$  ( -- adr len )  ls-r-name ls-r-len  ;

variable indent-level

: .totsize  ( d.size name$ -- )
   indent-level @ spaces  type ."  Total: "  push-decimal ud. pop-base cr
;
: ($ls-r)  ( name$ -- d.totsize )

   search-ih >r  ls-r-len >r

   \ Extend the path with the new name component and start new search
   tuck                               ( len name$ )
   ls-r-name$ +  swap move            ( len )
   dup  ls-r-name$ + +  [char] \ swap c!  ( len )
   ls-r-len + 1+  to ls-r-len         ( )

   ls-r-name$ $open-dir to search-ih  ( )

   1 indent-level +!                  ( )

   0. 0                               ( d.totsize index )
   begin  " next-file-info"  search-ih  $call-method  while    ( index 8*attributes name$ )
      handle-dirent                   ( d.totsize index d.size )
      rot >r  d+  r>                  ( d.totsize index' )
   exit? until   \ Resolves "begin"   ( d.totsize index )
      \ This block executes only if the loop terminates via "until"
      drop                            ( d.totsize )
   then          \ Resolves "while"   ( d.totsize )
   close-search                       ( d.totsize )

   -1 indent-level +!                 ( d.totsize )

   2dup  ls-r-name$ .totsize          ( d.totsize )

   \ Restore the path (removing the new name) and the search parameters
   r> to ls-r-len  r> to search-ih    ( d.totsize )
;

: recursive-.file  ( 8*attributes $name -- d.size )
   2dup " ." $= >r   2dup " .." $=  r> or  if   ( 8*attributes $name )
      2drop 4drop 4drop  0.  exit
   then

   3 pick >r  2dup 2>r 2 pick >r    ( 8*attributes $name r: len $name attr )
   indent-level @ spaces  .file cr  ( r: len $name attr )
   r> dir-attr?  if                 ( r: len $name )
      2r>  r> drop   ($ls-r)        ( d.size )
   else                             ( r: len $name )
      2r> 2drop  r> 0               ( d.size )
   then
;
' recursive-.file to handle-dirent

: $ls-r  ( pattern$ -- )
   \ If the pattern$ is null or has no name component, add a "*" to the end
   dup  if                     ( pattern$ )
      ?add\                    ( pattern$' )
      2dup file&dir 2nip       ( pattern$ dir$ )
      dup to ls-r-len          ( pattern$ dir$ )
      ls-r-name swap move      ( pattern$ )
      separator?               ( pattern$ no-name? )
   else  true  then            ( pattern$ no-name? )

   if  string2 pack  " *" rot $cat  string2 count  then  ( pattern$ )

   0 indent-level !                       ( pattern$ )
   2dup 2>r                               ( pattern$ r: pattern$ )
   begin-search    0.                     ( d.totsize )
   begin  another-match?  while           ( d.totsize 8*attributes name$ )
      handle-dirent  d+                   ( d.totsize' )
      exit?  if  close-search 2drop 2r> 2drop  exit  then
   repeat                                 ( d.totsize r: pattern$ )
   2r>  .totsize                          ( )
;
: ls-r  ( "pattern" -- )  parse-word  $ls-r  ;
: ls-r"  ( "pattern"" -- )  [char] " parse  $ls-r  ;

internal

: do-fileop  ( ... path$ op$ -- )
   2>r  open-directory         ( ... file$ ih )
   2r>  rot dup >r  $call-method  ( )
   r> close-dev
;


public

: $delete  ( path$ -- )  " $delete!" do-fileop abort" Can't delete file"  ;
: $rmdir   ( path$ -- )  " $rmdir"  do-fileop abort" Can't delete directory"  ;
: $mkdir   ( path$ -- )  " $mkdir"  do-fileop abort" Can't create directory"  ;
: $disk-free  ( path$ -- d.bytes )   " free-bytes" do-fileop 2nip  ;
: $disk-size  ( path$ -- d.bytes )   " total-size" do-fileop 2nip  ;

: $chdir  ( name$ -- )
   2dup is-pattern? abort" Can't use wildcards in directory name"
   canonical-path
   last-char  [char] \  <>  if  2dup + [char] \ swap c! 1+  then
   2dup $open-dir  close-dev                                      ( path$ )
   drive-volume  0= abort" Unassigned volume"                     ( path$ xt )
   -rot  dev&path 2nip  rot                                       ( tail$ xt )
   1 perform-action
;

internal

: safe-parse"  ( "name"" -- adr len )
   [char] " parse  dup 0=  abort" Missing command line argument"
;

public

: chdir  ( "name" -- )   safe-parse-word $chdir  ;
: chdir" ( "name"" -- )  safe-parse"     $chdir  ;

: delete  ( "pattern" -- )   safe-parse-word  $delete-all  ;
: delete" ( "pattern"" -- )  safe-parse"      $delete-all  ;
alias del  delete
alias del" delete"
alias rm   delete
alias rm"  delete"


internal

h# 8000 constant /copybuf
: (fcopy)  ( in-ih out-ih -- )
   /copybuf alloc-mem >r
   " size" 3 pick $call-method drop    ( in-ih out-ih input-file-size )
   begin  ?dup  while                  ( in-ih out-ih #remaining )
      r@  /copybuf " read" 6 pick $call-method  ( i o #remaining #read )
      tuck -  r@ rot                   ( i o #remaining' adr #read )
      " write" 5 pick $call-method     ( i o #remaining' #written )
      drop                             ( i o #remaining' )
   repeat                              ( i o )
   close-dev  close-dev  \ order is important for date/time keeping
   r> /copybuf free-mem
;

public

: $create-file  ( path$ -- ih )
   2dup open-directory                                     ( path$2 file$2 ih )
   >r " $create" r@ $call-method abort" Can't create file" ( path$2 ) ( r: ih )
   r> close-dev                                            ( path$2 )
   $open-file
;
' $create-file to _ofcreate

dev /client-services
: firmworks,create  ( cstr -- ihandle )
   cscount                   ( path$ )

   \ If the file already exists, delete it so it can be
   \ recreated with 0 initial length.
   2dup ['] $open-file catch  if  ( path$ x x )
      2drop                       ( path$ )
   else                           ( path$ ih )
      close-dev                   ( path$ )
      2dup ['] $delete catch  if  2drop  then  ( path$ )
   then                           ( path$ )

   ['] $create-file  catch  if  2drop 0  then
;
device-end

internal

: ?delete-file  ( path$ -- continue? )
   2dup  canonical-path open-dev  ?dup  if  ( path$2 ihandle )
      close-dev                             ( path$2 )
      collect( ." Overwrite " 2dup type ." ?" )collect  ( path$2 message$ )
      confirmed? if                         ( path$2 )
	 $delete true                       ( continue? )
      else                                  ( path$2 )
	 2drop false                        ( continue? )
      then                                  ( continue? )
   else                                     ( path$2 )
      2drop true                            ( continue? )
   then                                     ( continue? )
;
: same-device?  ( path$1 path$2 -- flag )
   canonical-path dev&path 2drop  string2 $save      ( path$1 dev$2 )
   2swap canonical-path dev&path 2drop    $=         ( flag )
;

: $copy1  ( path$1 path$2 -- )
   2swap $open-canonical-file -rot          ( ih path$2 )
   2dup ?delete-file if                     ( ih path$2 )
      $create-file                          ( ih out-ih )
      (fcopy)
   then
;
d# 128 buffer: source$
d# 128 buffer: destination$
: $copy-to-dir  ( file-name$ dir-path$ -- )
   last-char [char] \ = >r destination$ pack r> if
      drop                                   ( file-name$ )
   else
      add\                                   ( file-name$ )
   then
   2dup  file&dir 2drop  destination$ $cat   ( file-name$ )
   destination$ count  $copy1
;

: is-dir?  ( name$ -- flag )
   \ Special case to detect the root directory which does not appear inside
   \ any other directory.
   2dup canonical-path [char] \ split-string 2nip nip 1 = if
      2drop true exit
   then
   first-match  if  2drop dir?  else  false  then
;   
d# 128 buffer: search-dir
: $copy-all  ( pattern$ dir$ -- )
   2>r                                                 ( pattern$ r: dir$ )
   2r@ is-dir?  0= abort" The destination for pattern copies must be a directory"
   2dup canonical-path                                 ( pattern$ canonical$ r: dir$ )
   file&dir 2nip search-dir place  \ note source dir   ( pattern$ r: dir$ )
   begin-search  begin  another-match?  while          ( 8attributes name$ r: dir$ )
      2>r dir?  if                                     ( r: dir$ name$ )
         ." Not copying the directory: " 2r> type cr   ( r: dir$ )
      else                                             ( r: dir$ name$ )
         search-dir count source$ place                ( r: dir$ name$ )
         2r> source$ $cat                              ( r: dir$ )
         source$ count  2r@  $copy-to-dir              ( r: dir$ )
      then                                             ( r: dir$ )
   repeat                                              ( r: dir$ )
   2r> 2drop                                           ( )
;

: $copy2  ( path$1 path$2 -- )
   2dup is-dir? >r 2swap canonical-path 2swap r> if
      $copy-to-dir
   else
      $copy1
   then
;

public

: $copy  ( path$1 path$2 -- )
   2dup is-pattern? abort" Can't use wildcards in destination filename"
   2over is-pattern?  if
      $copy-all
   else
      \ Check whether the source and destination file are identical.
      2over canonical-path tuck source$ swap move source$ swap
      2over canonical-path $=
      abort" Can't copy file to itself"
      $copy2 
   then
;

: copy  ( "name1" "name2" -- )  safe-parse-word  safe-parse-word  $copy  ;

: $rename  ( path$1 path$2 -- )
   2over 2over is-pattern? -rot is-pattern? or
   abort" Can't use wildcards with rename"
   2over 2over same-device?  if           ( path$1 path$2 )
      2swap canonical-path dev&path 2nip  ( path$2 file-path$1 )
      string2 $save  2swap                ( file-path$1 path$2 )
      " $rename"  do-fileop  abort" Can't rename file"  ( )
   else   
      2>r  2dup  2r>  $copy2  $delete
   then
;
: rename  ( "name1" "name2" -- )
   safe-parse-word safe-parse-word $rename
;
alias ren rename
alias mv rename

: rmdir  ( "name" -- )   safe-parse-word $rmdir  ;
: rmdir" ( "name"" -- )  safe-parse"     $rmdir  ;

: mkdir  ( "name" -- )   safe-parse-word $mkdir  ;
: mkdir" ( "name"" -- )  safe-parse"     $mkdir  ;

public

: disk-free  ( "name" -- )
   parse-word $disk-free           ( d.size )
   dup  if    \ Larger than 4G, so display size in GB
      d# 1,000,000,000 um/mod nip  ( gbytes )
      .d ." GB" cr                 ( )
      exit
   then                            ( d.size )
   2dup  h# 40.0000.  d<  if       ( d.size )
      d# 1024 um/mod nip           ( kbytes )
      .d ." KB" cr                 ( )
      exit
   then                            ( d.size )
   d# 1,000,000 um/mod nip         ( mbytes )
   .d ." MB" cr                    ( )
;

: more  ( "devspec" -- )
   safe-parse-word
   open-dev  dup 0=  abort" Can't open it"   ( ih )
   >r                                        ( r: ih )
   load-base " load" r@ $call-method         ( len r: ih )
   r> close-dev                              ( len )
   load-base swap list
;

\ Read entire file into allocated memory
: $read-file  ( filename$ -- true | data$ false )
   open-dev  ?dup  0=  if  true exit  then  >r  ( r: ih )
   " size" r@ $call-method  drop   ( len r: ih )
   dup alloc-mem  swap             ( adr len r: ih )
   2dup " read" r@ $call-method    ( adr len actual r: ih )
   r> close-dev                    ( adr len actual )
   over <>  if                     ( adr len )
      free-mem  true exit
   then                            ( adr len )
   false
;

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
