\ Implementation factors
: <resolve  ( mark -- )  here -  here branch! /branch allot  ;
: >mark     ( -- mark )  here  dup <resolve  ;
: >resolve  ( mark -- )  here over -  swap branch!  ;
: <mark     ( -- mark )  here  ;

\ Primitive control flow words
: if     ( -- >mark )  +level  compile ?branch  >mark  ; immediate
: ahead  ( -- >mark )  +level  compile  branch  >mark  ; immediate
: begin  ( -- <mark )  +level                   <mark  ; immediate
: then   ( >mark -- )                   >resolve  -level  ; immediate
: until  ( <mark -- )  compile ?branch  <resolve  -level  ; immediate
: again  ( <mark -- )  compile  branch  <resolve  -level  ; immediate

\ Control flow stack manipulation
: cs-roll  ( markn .. mark0 n -- markn-1 .. mark0 markn )  roll  ;
: cs-pick  ( markn .. mark0 n -- markn   .. mark0 markn )  pick  ;

: but  ( mark1 mark2 -- mark2 mark1 )  1 cs-roll  ; immediate
: yet  ( mark -- mark mark )  0 cs-pick  ; immediate

\ Loops

: do   ( -- >mark )  +level  compile  (do)   >mark  ; immediate
: ?do  ( -- >mark )  +level  compile (?do)   >mark  ; immediate

: loop  ( >mark -- )
   compile (loop)    [compile] yet  /branch + <resolve >resolve  -level
; immediate

: +loop ( >mark -- )
   compile (+loop)   [compile] yet  /branch + <resolve >resolve  -level
; immediate

\ Derived control flow words
: while   ( -- )  [compile] if     [compile] but                  ; immediate
: else    ( -- )  [compile] ahead  [compile] but  [compile] then  ; immediate
: repeat  ( -- )  [compile] again                 [compile] then  ; immediate
