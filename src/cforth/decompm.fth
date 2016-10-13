\ Machine/implementation-dependent definitions
decimal

[ifdef] (;code)
\ Since ;code is not implemented yet, (does always introduces a
\ does> clause.
: does-ip?   (s ip -- ip' f )
   ta1+ true
;
[then]

\ Given an ip, scan backwards until you find the cfa.  This assumes
\ that the ip is within a colon definition, and it is not absolutely
\ guaranteed to work, but in practice it nearly always does.
\ This is dependent on the alignment requirements of the machine.
: find-cfa ( ip -- cfa)
   begin
       #align - dup cf@  (:)  =  ( ip' token )
\      #align - dup token@    ( ip' token )
\      ['] does-ip? token@ =  ( look for the cfa of a : defn )
   until  ( ip)
;

defer isdefer ' noop to isdefer
nuser isuser
0 constant isconstant
variable isvariable

\ >target depends on the way that branches are compiled
: >target ( ip-of-branch-instruction -- target )
   ta1+  dup branch@  ca+
;

: code ;
: primitive ;

: definer ( cfa-of-child -- cfa-of-defining-word )
  dup cf@             ( cfa code-field )
  dup maxprimitive <  if  2drop ['] primitive  exit  then
  dup (value) <=  if  ( cfa code-field )
    nip case 
      (:)          of ['] :          endof
      (constant)   of ['] constant   endof
      (variable)   of ['] variable   endof
      (create)     of ['] create     endof
      (user)       of ['] user       endof
      (defer)      of ['] defer      endof
      (vocabulary) of ['] vocabulary endof
      (code)       of ['] code       endof
      (value)      of ['] value      endof
    endcase
  else                   ( cfa code-field )
     drop token@ find-cfa
     dup ['] setalias =  if  drop ['] alias  then
  then
;

: >code  ( xt -- data-adr )  >body  ;
: >data  ( xt -- data-adr )
   dup >body        ( xt 'body )
   swap cf@  case   ( 'body [cf] )
      (variable)   of  >user  endof
      (user)       of  >user  endof
      (defer)      of  >user  endof
      (vocabulary) of  >user  endof
      (value)      of  >user  endof
   endcase
;

\ The decompiler can't quite handle the case statement in C Forth, because
\ it is defined in high level and the branching structure is too hard
\ to distinguish from IF ... THEN (In assembly language versions of Forth,
\ the case statement compiles special run time words (OF) (ENDOF) (ENDCASE) )
\ C Forth will decompile a case statement as a nested IF ... ELSE ... THEN
\ structure, which is logically correct but not as easy to read.
: (of) ;
: (endof) ;
: (endcase) ;

: in-dictionary?  ( adr -- flag )  origin here within  ;
: loop-end?  drop false  ;
defer indirect-call?
: no-icall  drop false  ;
' no-icall to indirect-call?

alias rslist 2drop
: unbug 0 <ip !  ;

: unaligned-w@  dup c@ swap 1+ c@ bwjoin   ;
: unaligned-w!  ( w adr -- )  >r wbsplit  r@ 1+ c!  r> c!  ;
: unaligned-l@  >r r@ c@  r@ 1+ c@  r@ 2+ c@  r> 3 + c@  bljoin ;
: unaligned-l!  ( l adr -- )  >r lwsplit  r@ 2+ unaligned-w!  r> unaligned-w! ;
: unaligned-@  unaligned-l@  ;
: d@ 2@ ;
[ifdef] notdef
: (dlit) ; : (llit) ;
: (n") ; : ($of) ; : ($endof) ; : ($endcase) ;
: ncount  ( adr -- adr' len )  dup wa1+ swap w@  ;
: +nstr ncount + 1+ taligned  ;
[then]
\ : d0<  ( l h -- flag )  nip 0<  ;
\ : dabs  2dup d0< if dnegate then  ;
\ : (d.)   tuck dabs <# #s rot sign #>  ;
alias taligned aligned
: +str count + 1+ taligned  ;
: n. . ;
: emit.
   d# 127 and dup printable? 0= if
      drop d# 46
   then
   emit
;
: emit.ln  bounds ?do i c@ emit. loop  ;
