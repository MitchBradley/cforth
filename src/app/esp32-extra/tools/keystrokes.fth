s" cforth" environment? [IF] drop alias ekey  key  [THEN]

0 value &jumptable-keys
0 value first-key
127 value last-key

: unknown-key  ( -- )  ."  Unknown, not assigned. "  #500 ms cr ;
: #keys        ( -- #keys )  last-key first-key - 1+ ;
: >key         ( c -- adr )  first-key - cells &jumptable-keys + ;
: assign-key   ( xt c -- )   >key ! ;

: all-keys-to-unknown  ( -- )
   &jumptable-keys #keys cells bounds  do
      ['] Unknown-key  i !
   cell +loop
;
: execute-key  ( c -- )
   dup first-key last-key 1+ within  if
      >key @  execute
   else
      cr emit ."  Not reserved. " #500 ms
   then
;
: empty-key-buffer  ( -- )
   begin  key?  while  ekey drop 1 ms  repeat
;
: on-key       ( -- )
   begin  ekey dup #27 <>  while  execute-key empty-key-buffer  repeat drop
;
0 [IF] \ Use:
\ The following 4 definitions may also be defined in flash:
: test1  ( -- )  cr ." test1" ;
: test2  ( -- )  cr ." test2" ;
: test3  ( -- )  cr ." test3" ;
: test4  ( -- )  cr ." test4" ;

\ Limit the range
char a to first-key    char e to last-key

#keys cells allocate
  [if]    cr .( allocate for &jumptable-keys failed.) quit
  [else]  to &jumptable-keys
  [then]

\ Set all keys to unknown
all-keys-to-unknown

' test1 char a assign-key
' test2 char b assign-key
' test3 char c assign-key
' test4 char d assign-key

on-key
[THEN]
