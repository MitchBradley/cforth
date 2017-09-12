[ifndef] carret    d# 13 constant carret    [then]
[ifndef] linefeed  d# 10 constant linefeed  [then]

[ifndef] log2
: log2  ( n -- log2-of-n )
   0  begin        ( n log )
      swap  2/     ( log n' )
   ?dup  while     ( log n' )
      swap 1+      ( n' log' )
   repeat          ( log )
;
[then]

\ Find the next occurence of delim after adr, returning the
\ string up to but not including that delimiter
: scan-to  ( adr delim -- adr len )
   over  begin  2dup c@ <>  while  1+  repeat  ( adr delim adr' )
   nip  over -
;

[ifndef] cscount
: cscount  ( adr -- adr len )  0 scan-to  ;
[then]
[ifndef] .cstr
: .cstr  ( adr -- )  cscount type  ;
[then]

[ifndef] be-l@
: be-l@   ( adr -- l )
   >r  r@ 3 + c@  r@ 2+ c@   r@ 1+ c@   r> c@  bljoin
;
[then]

[ifndef] be-l!
: be-l!   ( l adr -- l )
   >r  lbsplit  r@ c!  r@ 1+ c!  r@ 2+ c!  r> 3 + c!
;
[then]

[ifndef] be-w@
: be-w@   ( adr -- w )  dup 1+ c@  swap c@  bwjoin  ;
[then]

[ifndef] be-w!
: be-w!   ( w adr -- )  >r  wbsplit  r@ c!  r> 1+ c!  ;
[then]


[ifndef] le-l@
: le-l@   ( adr -- l )
   >r  r@ c@  r@ 1+ c@   r@ 2+ c@   r> 3 + c@  bljoin
;
[then]

[ifndef] le-l!
: le-l!   ( l adr -- l )
   >r  lbsplit  r@ 3 + c!  r@ 2+ c!  r@ 1+ c!  r@ c!
;
[then]

[ifndef] le-w@
: le-w@   ( adr -- w )  dup c@  swap 1+ c@  bwjoin  ;
[then]

[ifndef] le-w!
: le-w!   ( w adr -- )  >r  wbsplit  r@ 1+ c!  r> c!  ;
[then]


[ifndef] comp
: comp  ( adr1 adr2 len -- diff )  tuck compare  ;
[then]

[ifndef] d=
: d=  ( d1 d2 -- flag )  d- d0=  ;
[then]
