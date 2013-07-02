\ Machine/implementation-dependent definitions
decimal

: >data  ( acf -- data-adr )
   dup word-type               ( n acf code-field-word )
   dup ['] #user word-type  =  if  useradr exit  then
   dup ['] defxx word-type  =  if  useradr exit  then
   dup ['] forth word-type  =  if  useradr exit  then
   drop >body
;

\ >target depends on the way that branches are compiled
: >target ( ip-of-branch-instruction -- target )
   ta1+  dup branch@  ca+
;

\ Since ;code is not implemented yet, (does always introduces a
\ does> clause.
: does-ip?   (s ip -- ip' f )
   ta1+ true
;

\ Given an ip, scan backwards until you find the cfa.  This assumes
\ that the ip is within a colon definition, and it is not absolutely
\ guaranteed to work, but in practice it nearly always does.
\ This is dependent on the alignment requirements of the machine.
: find-cfa ( ip -- cfa)
   begin
      #align - dup token@    ( ip' token )
      ['] does-ip? token@ =  ( look for the cfa of a : defn )
   until  ( ip)
;

: code ;
: primitive ;

: definer ( cfa-of-child -- cfa-of-defining-word )
\t16  dup w@             ( cfa code-field )
\t32  dup  @             ( cfa code-field )
  dup maxprimitive <  if  2drop ['] primitive  exit  then
  dup (code) <=  if      ( cfa code-field )
    nip case 
      (:)          of ['] :          endof
      (constant)   of ['] constant   endof
      (variable)   of ['] variable   endof
      (create)     of ['] create     endof
      (user)       of ['] user       endof
      (defer)      of ['] defer      endof
      (vocabulary) of ['] vocabulary endof
      (code)       of ['] code       endof
    endcase
  else                   ( cfa code-field )
      drop token@ find-cfa
  then
;

\ We define these so that the decompiler can find them, but they aren't used
: (;code) ;
: (;uses) ;
: (does>) ;
: >code  ;
: (compile) ;
\ The decompiler can't quite handle the case statement in C Forth, because
\ it is defined in high level and the branching structure is too hard
\ to distinguish from IF ... THEN (In assembly language versions of Forth,
\ the case statement compiles special run time words (OF) (ENDOF) (ENDCASE) )
\ C Forth will decompile a case statement as a nested IF ... ELSE ... THEN
\ structure, which is logically correct but not as easy to read.
: (of) ;
: (endof) ;
: (endcase) ;
