\ String-array
\ Creates an array of strings.
\ Used in the form:
\ $array: name
\   ," This is the first string in the table"
\   ," this is the second one"
\   ," and this is the third"
\ ;$array
\
\ name is later executed as:
\
\ name ( index -- addr )
\   index is a number between 0 and one less than the number of strings in
\   the array.  addr is the address of the corresponding packed string.
\   if index is less than 0 or greater than or equal to the number of
\   strings in the array, name aborts with the message:
\        String array index out of range

: $array:  ( "name" -- )  ( Later: index -- adr len )
   create
   0 ,       \ the number of strings
   origin token,  \ the starting address of the pointer table
   does>     ( index pfa -- adr len )
      2dup @ ( index pfa  index #strings )
      0 swap within  0= abort" String array index out of range"  ( index pfa )
      na1+ token@   ( index table-address )
      swap ta+ token@ count
;
: ;$array ( -- )
   here align          ( string-end-addr )
   lastacf >body       ( string-end-addr pfa )
   na1+ here over token!    \ Store table address in the second word of the pf
   ta1+                ( string-end-addr first-string-addr )
   begin               ( string-end-addr this-string-addr )
      2dup >          ( string-end-addr this-string-addr )
   while
      \ Store string address in table
      dup token,      ( string-end-addr this-string-addr )
      \ Find next string address
      extract-str 2drop
   repeat              ( string-end-addr next-string-addr )
   2drop               ( )
   \ Calculate and store number of strings
   lastacf >body        ( pfa )
   dup na1+ token@      ( pfa table-addr )
   here swap - /token / ( pfa #strings )
   swap !
;
