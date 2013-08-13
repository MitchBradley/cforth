: [else]  ( -- )
   1  begin						( level )
      begin  parse-word dup  while			( level adr len )
         $canonical               			( level adr len )
         2dup s" [if]"     compare 0= >r
         2dup s" [ifdef]"  compare 0= r> or >r
         2dup s" [ifndef]" compare 0= r> or  if		( level adr len )
	    2drop 1+					( level' )
         else						( level adr len )
	    2dup  s" [else]"  compare 0=  if		( level adr len )
	       2drop 1- dup  if  1+  then		( level' )
	    else					( level adr len )
	       s" [then]"  compare 0=  if  1-  then	( level')
            then					( level' )
	    ?dup 0=  if  exit  then			( level' )
         then						( level' )
      repeat						( level adr len )
      2drop						( level' )
   refill 0= until					( level' )
   drop
; immediate

: [if]  ( flag -- )  0=  if  postpone [else]  then  ; immediate

: [then]  ( -- )  ;  immediate

: [ifdef]  ( "name" -- )
   $defined nip dup 0=  if  nip  then  [compile] [if]
; immediate

: [ifndef]  ( "name" -- )
   $defined nip 0= dup  if  nip  then  [compile] [if]
; immediate
