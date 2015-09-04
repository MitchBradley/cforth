\ Return the output of a system command as a string.
\ Examples:
\   " hostname" $system$ type
\   " hostname -I" $system$ -newline type
\   " date" $system type

\ Removes, if present, a single instance of the given character from
\ the end of the string
: ?remove  ( adr len char  -- adr len' )
   over 0=  if  drop exit  then   ( adr len char )
   2 pick 2 pick + 1- c@ =  if  1-  then   ( adr len' )
;

\ Removes, if present, a newline sequence from the end of the string
: -newline  ( adr len -- adr len' )  $0a ?remove  $0d ?remove  ;

#4096 buffer: system-buf

\ If the command returned an error code it might be in this value
0 value system-retval

\ Executes the system command cmd$, returning its output (limited to
\ 4096 characters) as a string,
: $system$  ( cmd$ -- result$ )
   " popen:%s" sprintf r/o open-file abort" Can't run command"  >r  ( r:fd )
   system-buf #1024 r@ read-file  abort" Can't read popen output"   ( len r:fd )
   r> close-file to system-retval  ( len )
   system-buf swap                 ( result$ )
;
