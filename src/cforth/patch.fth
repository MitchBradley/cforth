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
: (npatch  ( newn oldn acf -- )
   word-bounds   nsearch
   if  !  else  ." Couldn't find it" drop  then
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
