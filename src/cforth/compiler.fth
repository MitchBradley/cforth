: \  source >in !  drop  ; immediate

\ Debugging tools
\ : x'  parse-word $find drop  ; immediate
\ : @. dup @ x. cell+ ;
\ : [.] 99 emit 32 emit dup x. cr ; immediate
\ : dx. dup x. cr ;

\ : prim  ['] ['] execute  ['] compile, compile,  ; immediate

: char    parse-word drop c@  ;
: [char]  char compile (char) ,  ;  immediate

: (   [char] ) parse  2drop  ; immediate
: .(  [char] ) parse type  ; immediate

: safe-parse-word  ( -- adr len )  parse-word  dup 0= throw  ;
: $defined  ( "name" -- adr len 0 | xt +-1 )  safe-parse-word $find  ;

: '    ( "name" -- xt )  parse-word $find  0= throw  ;
: [']  ( "name" -- )  ( later: -- xt )  '  xtliteral  ; immediate

: [compile]   ( "name" -- )  ' compile,  ; immediate

: does>  ( -- )  compile (does)  ; immediate

/token constant #align
: aligned  ( adr -- aligned-adr )
   #align 1 - +  #align negate and
;
: align  ( -- )  here here aligned swap - allot  ;

: place  ( adr len to-adr -- )  2dup c!  2dup + 1+  0 swap c!  1+ swap cmove  ;
: pack  ( adr len to-adr -- to-adr )  dup >r place r>  ;

\ The following two words define the format of in-line strings
: extract-str  ( ip -- ip' adr len )  count 2dup + 1+ aligned -rot  ;
: ",  ( adr len -- )  tuck  here place  ( len )  2+ allot  align  ;

: skipstr  ( -- adr len )
   r> ip@              ( return-adr ip )
   extract-str         ( return-adr ip' adr len )
   rot ip!             ( return-adr adr len )
   rot >r              ( adr len )
;

: (.")  ( -- )  skipstr type  ;

: ,"  ( "string" -- )  [char] " parse ",  ;
