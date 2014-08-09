\ a non-volatile buffer for source code
: .d%          ( n -- )  push-decimal  (.) type [char] % emit  pop-base  ;
: .usage       ( -- )    nv-length d# 100 * /nv / .d%  ;
: nv$          ( -- $ )  nv-base nv-length  ;
: .nv          ( -- )    nv$ type  ;
: nv-dump      ( -- )    nv$ 1+ cdump  ;
: nv-dump-all  ( -- )    nv-base /nv dump  ;
: nv-evaluate  ( -- )    nv$  ['] evaluate  catch  ?dup  if  3drop  then  ;

\ add a line to non-volatile buffer
: nv  ( text ( )
   nv-length            ( pos )
   eol parse            ( pos adr len )
   dup 0=               ( pos adr len empty )
   if  3drop exit  then ( pos adr len )
   bounds do            ( pos )
      i c@ over         ( pos char pos )
      nv!               ( pos )
      1+                ( pos+1 )
   loop                 ( pos+len )
   h# a over nv!        ( pos+len+1 )
   1+ 0 swap nv!        ( )
;

\ scan backwards for a line break
: strrnl  ( a.begin a.end -- a.match )
   swap  do  i c@ h# a =  if  i leave  then  -1 +loop
;

\ forget last line
: nv-undo  ( -- )
   nv$ 2-               ( adr len )
   dup 0< if  2drop ." no more"  exit  then  ( adr len )
   bounds               ( adr adr )
   strrnl               ( adr )
   nv-base - 1+         ( pos ) \ of first char in line to remove
   0 swap nv!
;

\ wip entire non-volatile buffer
: nv-wipe      ( -- )    0 0 nv!  ;
