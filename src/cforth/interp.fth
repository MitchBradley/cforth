defer (emit
defer cr
defer type

\ : false  0  ;
\ : true  -1  ;
 0 constant false
-1 constant true
: [ false  state !  ; immediate
: ] true state !  ;
: literal  ( n -- )
   dup  here branch!  here branch@   ( n n' )
   over =  if
      compile (wlit)  here branch!  /branch allot
   else
      compile (lit) ,
   then
; immediate
: 2dup  over over  ;
: 2swap rot >r rot r> ;
: 2drop drop drop ;

: source      ( -- adr len )  'source @  #source @  ;
: set-source  ( adr len -- )  #source !  'source !  ;

nuser 'source-id
: source-id  ( -- fid )  'source-id @  ;

: save-input  ( -- source-adr source-len source-id >in blk 5 )
   source  source-id  >in @  blk @  5
;
: restore-input  ( source-adr source-len source-id >in blk 5 -- flag )
   drop 
   blk !  >in !  'source-id !  set-source
   false
;
: set-input  ( source-adr source-len source-id -- )
   0 0 5 restore-input drop
;

: /string  ( c-addr1 u1 n -- c-addr2 u2 )  tuck -  -rot +  swap  ;

defer where1
defer where
defer .not-found

: $do-undefined   ( name$ -- )
   .not-found
   state @  if  compile lose  else  cr abort  then
;
: dep depth dup. drop cr ;
: compile-word  ( adr len -- )
   $find  dup  if              ( cfa +-1 )
      0<  state @  and  if  compile,  else  execute  then    (   )
   else                        ( name$ 0 )
      drop  2dup $number?  if  ( name$ d )
         2swap 2drop           ( d )
	 dpl @  if
	    drop  state @  if  [compile] literal  then
	 else
	    state @  if  swap [compile] literal [compile] literal  then
	 then
      else                     ( str )
         $do-undefined         ( )
      then
   then
;
: (interpret  ( -- )
   begin
      parse-word  dup  ( adr len )
   while
      compile-word
   repeat
   2drop
;
: ?block-valid  ( -- flag )  false  ;		\ XXX Implement me
: refill  ( -- more? )
   blk @  if  1 blk +!  ?block-valid  exit  then

   source-id  -1 =  if  false exit  then
   source drop					     ( adr )
   source-id  if                                     ( adr )
      /tib source-id read-line  if                   ( cnt more? )
         -98 throw                                   ( -- )
      then                                           ( cnt more? )
      over /tib =  if                                ( cnt more? )
         -97 throw                                   ( cnt more? )
      then                                           ( cnt more? )
   else                                              ( adr )
      /tib accept                                    ( cnt )
      \ The ANS Forth standard does not mention the possibility
      \ that accept might not be able to deliver any more input,
      \ but in C Forth 93, the `keyboard' can be redirected to a
      \ file via the command line, so it is indeed possible for
      \ accept to have no more characters to deliver.
      dup  if  true  else  more-input?  then         ( cnt more? )
   then                                              ( cnt more? )
   swap  #source !  0 >in !                          ( more? )
;
: ??cr  ( -- )  #out @  if  cr  then  ;
: catch  ( acf -- error# | 0 )
                        ( cfa )  \ Return address is already on the stack
   sp@ >r               ( cfa )  \ Save data stack pointer
   handler @ >r         ( cfa )  \ Previous handler
   rp@ handler !        ( cfa )  \ Set current handler to this one
   execute              ( )      \ Execute the word passed in on the stack
   0                    ( 0 )    \ Signify normal completion
   r> handler !         ( 0 )    \ Restore previous handler
   r> drop              ( 0 )    \ Don't need saved stack pointer
;
defer to-hook
defer status
defer prompt
defer header

: clear  ( ?? -- )  sp0 @ sp!  ;
defer .error
defer .underflow
nuser 'exit-interact?
: interact  ( -- )
   tib /tib 0 set-input
   [compile] [
   begin
      depth 0<  if  .underflow  clear  then
      interactive?  if	\ Suppress prompt if input is redirected to a file
         status
	 prompt
      then
   refill  while
      ['] (interpret catch  ??cr  ?dup if  [compile] [  .error  ( clear ) then
   'exit-interact? @ until then
   false 'exit-interact? !
;
: quit  ( -- )
   \ XXX We really should clean up any open input files here...
   0 complevel !
   rp0 @ rp!
   interact
   bye
;

: interpret-lines  ( -- )  begin  refill  while  (interpret  repeat  ;

: evaluate  ( adr len -- )
   save-input  2>r 2>r 2>r   ( adr len )

   -1 set-input

   ['] (interpret catch      ( error# )

   2r> 2r> 2r> restore-input throw

   throw
;

: include-file  ( fid -- )
   /tib allocate throw		( fid adr )

   save-input 2>r 2>r 2>r       ( fid adr )

   over mark-input              ( fid adr )
   /tib rot set-input           ( )

   ['] interpret-lines catch    ( error# )

   dup  if  where1  then        ( error# )

   source-id close-file drop    ( error# )

   source drop  free drop       ( error# )

   2r> 2r> 2r> restore-input throw  ( error# )

   throw
;

: included  ( adr len -- )   r/o open-file  throw  include-file  ;
: including  ( -- )  parse-word included  ;
: fl  including ;
: fload  including ;

w
