\ : false  0  ;
\ : true  -1  ;
 0 constant false
-1 constant true
false
: [ false state !  ; immediate
: ] true state !  ;
: literal  ( n -- )
   dup  here branch!  here branch@   ( n n' )
   over =  if
      compile (lit16)  here branch!  /branch allot
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

: where1  ( -- )
   source                 ( adr len )
   ." Error at: "
   over >in @ type        ( adr len )
   ."  |  "               ( adr len )
   >in @ /string type cr  ( )
;
: .not-found  ( name$ -- )  cr  type ."  ?"  cr  where1  ;

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
         2swap 2drop  drop
	 \ XXX handle double numbers
         state @  if  [compile] literal  then
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
         ." read error in refill"  abort             ( cnt more? )
      then                                           ( cnt more? )
      over /tib =  if                                ( cnt more? )
         ." line too long in input file"  abort      ( cnt more? )
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
: prompt  ( -- )
   interactive?  if	\ Suppress prompt if input is redirected to a file
      state @  if  ."  ] "  else  ." ok "  then
   then
;
: clear  ( ?? -- )  sp0 @ sp!  ;
defer .error
: quit  ( -- )
   \ XXX We really should clean up any open input files here...
   0 complevel !
   rp0 @ rp!
   tib /tib 0 set-input
   [compile] [
   begin
      depth 0<  if  ." Stack Underflow" cr  clear  then
      prompt
   refill  while
      ['] (interpret catch  ??cr  ?dup if  .error  clear  then
   repeat
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

   /tib rot set-input

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
