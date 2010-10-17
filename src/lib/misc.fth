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
   >r  r@ c@ 8 lshift  r@ 1+ c@ or 8 lshift  r@ 2+ c@ or 8 lshift  r> 3 + c@ or
;
: be-w!   ( w adr -- )   2dup 1+ c!  swap 8 rshift swap c!  ;
[then]

[ifndef] lbflip
: lbflip  ( l -- l )  lbsplit  swap 2swap swap bljoin  ;
[then]

[ifndef] comp
: comp  ( adr1 adr2 len -- diff )  tuck compare  ;
[then]

[ifndef] d=
: d=  ( d1 d2 -- flag )  d- d0=  ;
[then]
