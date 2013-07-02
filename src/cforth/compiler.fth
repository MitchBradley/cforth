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
