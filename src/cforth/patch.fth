\  Patch utility.  Allows you to make patches to already-defined words.
\   Usage:
\     PATCH new-word old-word word-to-patch
\         In the definition of "word-to-patch", replaces the first
\         occurence of "old-word" with "new-word".
\
\     n-new  n-old  NPATCH  word-to-patch
\         In the definition of "word-to-patch", replaces the first
\         compiled instance of the number "n-old" with the number
\         "n-new".
\
\     n-new  n-old  start-adr  end-adr  (NPATCH
\         replaces the first occurrence of "n-old" between start-adr
\         and end-adr with "n-new"
\
\     acf-new  acf-old  start-adr  end-adr  (PATCH
\         replaces the first occurrence of "acf-old" between start-adr
\         and end-adr with "acf-new"
\
\     n  start-adr end-adr   NSEARCH
\         searches for an occurrence of "n" between start-adr and
\         end-adr.  Leaves the adress where found and a success flag.
\
\     c  start-adr end-adr   CSEARCH
\         searches for a byte between start-adr and end-adr
\
\     w  start-adr end-adr   WSEARCH
\         searches for a 16-bit word between start-adr and end-adr
\
\     acf  start-adr end-adr TSEARCH
\         searches for a compiled adress between start-adr and end-adr

: csearch ( c start end -- loc true | false )
   swap ( n end start )
   begin ( n end curr )
      2dup u<=
      if  2drop drop  false exit  then    \ if curr=end exit with false
      dup c@ 3 pick  ( n end curr curr@ n )
      <>
   while
      ca1+ 
   repeat
   nip nip true  ( loc true )
;
: wsearch  ( w start end -- loc true | false )
   rot n->w -rot    \ strip off any high bits
   swap ( n end start )
   begin ( n end curr )
      2dup u<=
      if  2drop drop  false exit  then     \ if curr=end exit with false
      dup w@ 3 pick  ( n end curr curr@ n )
      <>
   while
      wa1+ 
   repeat
   nip nip true ( loc true )
;
: tsearch  ( adr start end -- loc true | false )
   swap    ( n end start )
   begin   ( n end curr )
      2dup u<=
      if  2drop drop  false exit  then    \ if curr=end exit with false
      dup token@ 3 pick  ( n end curr curr@ n )
      <>
   while
      1+ aligned
   repeat
   nip nip true ( loc true )
;
: nsearch  ( n start end -- loc true | false )
   swap   ( n end start )
   begin  ( n end curr )
      2dup u<=
      if  2drop drop  false exit  then    \ if curr=end exit with false
      dup @ 3 pick  ( n end curr curr@ n )
      <>
   while
      1+ aligned
   repeat
   nip nip true  ( loc true )
;
: word-bounds  ( acf -- apf end )
   >body
   ['] unnest over  here   ( apf end-token apf here )
   tsearch                 ( apf [ loc ] f )
   0= if  here  then
;
\t16 : fits16?  ( n -- )  d# 15 >>a -1 0 between  ;
\t16 : npatch-t16  ( newn oldn xt -- )
\t16    word-bounds swap   ( newn oldn end start )
\t16    begin  ( newn oldn end curr )
\t16       2dup u<= abort" Can't find it"    \ if curr=end exit
\t16       dup @ 3 pick                  ( newn oldn end curr curr@ oldn )
\t16       =  if                         ( newn oldn end curr )
\t16          nip nip ! exit             ( -- )
\t16       then                          ( newn oldn end curr )
\t16       dup token@ ['] (wlit) =  if   ( newn oldn end curr )
\t16          ta1+                       ( newn oldn end curr' )
\t16          dup <w@                    ( newn oldn end curr curr@ )
\t16          3 pick =  if               ( newn oldn end curr )
\t16             nip nip                 ( newn curr )
\t16             over fits16?  if        ( newn curr )
\t16                w! exit              ( -- )
\t16             then                    ( newn curr )
\t16             drop .  ." does not fit in the available space" abort
\t16          then                       ( newn oldn end curr )
\t16       then                          ( newn oldn end curr )
\t16       1+ aligned                    ( newn oldn end curr' )
\t16    again
\t16 ;
: (npatch  ( newn oldn acf -- )
\t16   npatch-t16
\t32   word-bounds   nsearch
\t32   if  !  else  ." Couldn't find it" drop  then
;
: (wpatch  ( new old acf -- )
   word-bounds   wsearch
   if  w!  else  ." Couldn't find it" drop  then
;
: (patch  ( new-acf old-acf acf -- )
   word-bounds  tsearch
   if  token!  else  ." Couldn't find it" drop  then
;

\ substitute new for first occurrence of old in word "name"
: npatch  \ name  ( new old -- )
   '  ( new old acf )  (npatch
;
\ substitute new for first occurrence of old in word "name"
: wpatch  \ name  ( new old -- ) 
   '  ( new old acf )  (wpatch
;
: patch  \ newword oldword wordtopatch  ( -- )
   ' ' ' (patch
;
