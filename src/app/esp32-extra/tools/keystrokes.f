marker keystrokes.f \ Works under cforth, gforth and win32forth

s" cforth" environment? [IF] drop alias ekey  key  [THEN]

0 value first-key        127 value last-key
0 value &jumptable-keys

: #keys        ( - #keys )  last-key first-key - 1+ ;
: >key         ( char - adr )  first-key - cells &jumptable-keys + ;
: assign-key   ( xt-action char - )  >key ! ;
: unknown-key  ( - )  ."  Unknown, not assigned. "  #500 ms cr ;

: all-keys-to-unknown ( - )
   &jumptable-keys #keys cells bounds
     do   ['] Unknown-key  i ! cell
     +loop ;

: execute-key  ( char - )
   dup first-key last-key 1+ within
     if    >key @  execute
     else  cr emit ."  Not reserved. " #500 ms
     then ;

: empty-key-buffer ( - )
   begin  key?
   while  ekey drop 1 ms
   repeat ;

: on-key       ( - )
   begin  ekey dup #27 <>
   while  execute-key empty-key-buffer
   repeat drop ;

0 [IF] \ Use:

\ The following 4 definitions may also be defined in flash:
: test1 ( - )  cr ." test1" ;
: test2 ( - )  cr ." test2" ;
: test3 ( - )  cr ." test3" ;
: test4 ( - )  cr ." test4" ;

char a to first-key    char e to last-key   \ Limit the range

\ here to &jumptable-keys #keys cells allot \ Uses more code space

#keys cells allocate              \ Saves memory in the code space
  [if]    cr .( allocate for &jumptable-keys failed.) quit
  [else]  to &jumptable-keys
  [then]

all-keys-to-unknown               \ Initial setting for all keys

' test1 char a assign-key
' test2 char b assign-key
' test3 char c assign-key
' test4 char d assign-key

cr   .( Test on-key for a-d <escape> stops.) cr on-key
[THEN]  \ \s
