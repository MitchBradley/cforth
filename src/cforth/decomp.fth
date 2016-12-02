\ The decompiler.
\ This program is based on the F83 decompiler by Perry and Laxen,
\ but it has been heavily modified:
\   Structured decompilation of conditionals
\   Largely machine independent
\   Prints the name of the definer for child words instead of the
\     definer's DOES> clause.
\   "Smart" decompilation of literals.

\ A Forth decompiler is a utility program that translates
\ executable forth code back into source code.  For many compiled languages,
\ decompilation is very hard or impossible.  Decompilation of threaded
\ code is relatively easy.
\ It was written with modifiability in mind, so if you add your
\ own special compiling words, it will be easy to change the
\ decompiler to include them.  This code is implementation
\ dependant, and will not necessarily work on other Forth system.
\ However, most of the  machine dependencies have been isolated into a
\ separate file "decompiler.m.f".
\ To invoke the decompiler, use the word SEE <name> where <name> is the
\ name of a Forth word.  Alternatively,  (SEE) will decompile the word
\ whose cfa is on the stack.

decimal

only forth also hidden also forth definitions
defer (see)

hidden definitions
\ Like ." but goes to a new line if needed.
: cr." ( -- ) skipstr dup ?line type ;
: .."  ( -- ) compile cr." ," ; immediate

\ Positional case defining word
\ Subscripts start from 0
: out   ( # apf -- ) \ report out of range error
   cr  ." subscript out of range on "  dup body>
   .name  ."    max is " ?   ."    tried " .  quit   ;
: map  ( # apf -- a ) \ convert subscript # to address a
   2dup @  u< if   na1+ swap na+   else   out  then   ;
: maptoken  ( # apf -- a ) \ convert subscript # to address a
   2dup @  u< if   na1+ swap /token * +   else   out  then   ;

forth definitions

: case:   (s n --  ) \ define positional case defining word
   constant  hide    ]
   does>   ( #subscript -- ) \ executes #'th word
     maptoken  token@  execute   ;

: tassociative:
   constant
   does>         (s n -- index )
      dup @              ( n pfa cnt )
      dup >r -rot na1+        ( cnt n table-addr )
      r> 0                    ( cnt n table-addr cnt 0 )
      do   2dup token@ =          ( cnt n pfa' bool )
         if 2drop drop   i 0 0   leave   then
            ( clear stack and return index that matched )
         ta1+
      loop   2drop
;

hidden definitions

: nulldis ( apf -- )  drop ." <no disassembler>" ;
defer disassemble  ' nulldis is disassemble

\ Breaks is a list of places in a colon definition where control
\ is transferred without there being a branch nearby.
\ Each entry has two items: the address and a number which indicates
\ what kind of branch target it is (either a begin, for backward branches,
\ a then, for forward branches, or an exit.

40 /n* buffer: breaks
variable end-breaks

: add-break ( break-address break-type -- )
  end-breaks @  breaks 40 /n* +  >=
  abort" Decompiler internal table overlow"
  end-breaks @ 2!  /n 2*  end-breaks +!
;
: ?add-break ( break-address break-type -- )
  over       ( break-address break-type break-address )
  end-breaks @ breaks
  ?do   dup  i 2@ drop   =  ( found? )
        if   drop 0  leave  then
  /n 2* +loop ( break-address break-type not-found? )
  if add-break else 2drop then
;
variable break-type  variable break-addr   variable where-break
: next-break ( -- break-address break-type )
   -1 break-addr !   ( prime stack)
   end-breaks @  breaks
   ?do  i  2@ over   break-addr @ u<
        if  break-type !  break-addr n!  i where-break n!
        else 2drop
        then
   /n 2* +loop
   break-addr @  -1  <>  if -1 -1 where-break @ 2! then
;
: forward-branch? ( ip-of-branch-token -- f )
   dup >target u<
;

\ Bare-if? checks to see if the target address on the stack was
\ produced by an IF with no ELSE.  This is used to decide whether
\ to put a THEN at that target address.  If the conditional branch
\ to this target is part of an IF ELSE THEN, the target address
\ for the THEN is found from the ELSE.  If the conditional branch
\ to this target was produced by a WHILE, there is no THEN.
: bare-if? ( ip-of-branch-target -- f )
   /branch - /token - dup token@  ( ip' possible-branch-cfa )
   dup ['] branch  =    \ unconditional branch means else or repeat
   if  drop drop false exit then  ( ip' cfa )
   ['] ?branch =        \ cond. forw. branch is for an IF THEN with null body
   if   forward-branch?
   else drop true
   then
;

\ While? decides if the conditional branch at the current ip is
\ for a WHILE as opposed to an IF.  It finds out by looking at the
\ target for the conditional branch;  if there is a backward branch
\ just before the target, it is a WHILE.
: while? ( ip-of-?branch -- f )
  >target
  /branch - /token - dup token@  ( ip' possible-branch-cfa )
  ['] branch =           \ looking for the uncond. branch from the REPEAT
  if  forward-branch? 0= \ if the branch is forward, it's an IF .. ELSE
  else drop false
  then
;
: indent ( -- )
  #out @ lmargin @ > if cr then
  lmargin @ #out @ - spaces
;
: +indent ( -- )  3 lmargin +!  indent  ;
: -indent ( -- ) -3 lmargin +!  indent  ;
: <indent ( -- ) -3 lmargin +!  indent  3 lmargin +!   ;

: .begin ( -- ) .." begin " +indent ;
: .then  ( -- ) -indent .." then  " ;

\ Extent holds the largest known extent of the current word, as determined
\ by branch targets seen so far.  This is used to decide if an exit should
\ terminate the decompilation, or whether it is "protected" by a conditional.
variable extent  extent off
: +extent ( possible-new-extent -- )
  extent @ umax extent n!
;
: +branch ( ip-of-branch -- next-ip )  ta1+ /branch + ;
: .endof ( ip -- ip' ) .." endof" indent +branch ;
: .endcase ( ip -- ip' ) indent .." endcase" indent ta1+ ;
: scan-of ( ip-of-(of -- ip' )
  dup >target dup +extent  ( ip next-of )
  /branch - /token -       ( ip endof-addr )
  dup ['] .endof add-break ( ip endof-addr )
  ['] .endcase ?add-break
  +branch
;
: scan-branch ( ip-of-?branch -- ip' )
  dup dup forward-branch?
  if    >target dup +extent   ( branch-target-address)
        dup bare-if? ( ip flag ) \ flag is true if this is an IF branch
        if   ['] .then add-break
        else drop
        then
  else >target ['] .begin add-break
  then
  +branch
;

: skip-char ( ip -- ip' )  ta1+  ta1+  ;
: scan-unnest ( ip -- ip' | 0 )  drop 0  ;
[ifdef] (;code)
: scan-;code ( ip -- ip' | 0 )
  does-ip?  0=  if  drop 0  then
;
: .;code    (s ip -- ip' )
   does-ip?
   if    .." does> "
   else  0 lmargin ! indent .." ;code "  cr disassemble     0
   then
;
[then]
: .branch ( ip -- ip' )
  dup forward-branch?
  if   <indent .." else  " indent
  else -indent .." repeat "
  then
  +branch
;
: .?branch ( ip -- ip' )
  dup forward-branch?
  if  dup while?
      if   <indent .." while " indent
      else .." if    " +indent 
      then
  else -indent .." until " then
  +branch
;

: .do    ( ip -- ip' )  +indent .." do    " +branch ;
: .?do   ( ip -- ip' )  +indent .." ?do   " +branch ;
: .loop  ( ip -- ip' )  -indent .." loop  " +branch ;
: .+loop ( ip -- ip' )  -indent .." +loop " +branch ;
: .of    ( ip -- ip' )  .." of   " +branch ;

\ Guess what kind of constant n is
: classify-literal ( n -- )
  dup printable?
  if   .." [char] " dup emit .."  ( " . .." ) "
  else . then
;

\ first check for word being immediate so that it may be preceded
\ by postpone if necessary
: check-postpone ( cfa -- cfa )
  dup immediate? if .." postpone " then
;

: .word         (s ip -- ip' )  dup token@ check-postpone ?cr .name   ta1+  ;
: skip-word     (s ip -- ip' )  ta1+ ;
: .inline       (s ip -- ip' )  ta1+ dup @  .  na1+   ;
: .wlit         (s ip -- ip' )  ta1+ dup branch@  .  /branch +   ;
: skip-inline   (s ip -- ip' )  ta1+ na1+ ;
: .flit         (s ip -- ip' )
   ta1+ >r
float?  ?\  r@ la1+ l@   r@ l@   fpush e.
   r> la1+ la1+
;
: skip-llit     (s ip -- ip' )  ta1+ la1+ ;
: skip-flit     (s ip -- ip' )  ta1+ la1+ la1+ ;
: skip-branch   (s ip -- ip' )  +branch ;
: .quote        (s ip -- ip' )  .word   .word   ;
: skip-quote    (s ip -- ip' )  ta1+ ta1+ ;
: .compile      (s ip -- ip' )  ." postpone " ta1+ .word   ;
: skip-compile  (s ip -- ip' )  ta1+ ta1+ ;
: skip-string   (s ip -- ip' )  ta1+ extract-str 2drop ;
: .[']          (s ip -- ip' )  ta1+  .." ['] " dup token@ .name  ta1+ ;
: skip-[']      (s ip -- ip' )  ta1+ ta1+ ;
: .finish       (s ip -- ip' )  .word   drop   0  ;
: .string       (s ip -- ip' )
  .word   extract-str  type  [char] " emit  space
;
: .quoted   (s ip -- ip' )
   extract-str  [char] " emit  space  type  [char] " emit  space
;
: .(")      (s ip -- ip' )   skip-word  .quoted ;
: .(.")     (s ip -- ip' )   skip-word  ." ." .quoted ;
: .abort"   (s ip -- ip' )   skip-word  ." abort" .quoted ;
: .(c")     (s ip -- ip' )
   skip-word
   extract-str
   [char] c emit  [char] " emit  space  type  [char] " emit  space
;

\ Use this version of .branch if the structured conditional code is not used
\ : .branch     (s ip -- ip' )  .word   dup <w@ .   /branch +   ;

: .char       (s ip -- ip' )
   .." [char] " ta1+  dup @ emit space  na1+
;
: .does>      (s ip -- ip' )  .." does> "  ta1+  ;
: .unnest     (s ip -- 0 )
   0 lmargin ! indent .." ; " drop   0
;

\ classify each word in a definition
23 tassociative: execution-class  ( token -- index )
   (  0 ) [compile]  (lit)           (  1 ) [compile]  ?branch
   (  2 ) [compile]  branch          (  3 ) [compile]  (loop)
   (  4 ) [compile]  (+loop)         (  5 ) [compile]  (do)
   (  6 ) [compile]  compile         (  7 ) [compile]  (.")
   (  8 ) [compile]  (abort")        (  9 ) [compile]  dummy
   ( 10 ) [compile]  unnest          ( 11 ) [compile]  (")
   ( 12 ) [compile]  (?do)           ( 13 ) [compile]  (does)
   ( 14 ) [compile]  (char)          ( 15 ) [compile]  (fliteral)
   ( 16 ) [compile]  (')             ( 17 ) [compile]  (of)
   ( 18 ) [compile]  (endof)         ( 19 ) [compile]  (endcase)
   ( 20 ) [compile]  (c")            ( 21 ) [compile]  (wlit)
   ( 22 ) [compile]  dummy

\ Print a word which has been classified by  execution-class
24 case: .execution-class  ( ip index -- ip' )
   (  0 )     .inline                (  1 )     .?branch
   (  2 )     .branch                (  3 )     .loop
   (  4 )     .+loop                 (  5 )     .do
   (  6 )     .compile               (  7 )     .(.")
   (  8 )     .abort"                (  9 )     dummy
   ( 10 )     .unnest                ( 11 )     .(")
   ( 12 )     .?do                   ( 13 )     .does>
   ( 14 )     .char                  ( 15 )     .flit
   ( 16 )     .[']                   ( 17 )     .of
   ( 18 )     .endof                 ( 19 )     .endcase
   ( 20 )     .(c")                  ( 21 )     .wlit
   ( 22 )     dummy                  ( default ) .word
;

\ Determine the control structure implications of a word
\ which has been classified by  execution-class
24 case: do-scan
   (  0 )     skip-inline            (  1 )     scan-branch
   (  2 )     scan-branch            (  3 )     skip-branch
   (  4 )     skip-branch            (  6 )     skip-branch
   (  6 )     skip-compile           (  7 )     skip-string
   (  8 )     skip-string            (  9 )     dummy
   ( 10 )     scan-unnest            ( 11 )     skip-string
   ( 12 )     skip-branch            ( 13 )     scan-does>
   ( 14 )     skip-char              ( 15 )     skip-flit
   ( 16 )     skip-[']               ( 17 )     scan-of
   ( 18 )     skip-branch            ( 19 )     skip-word
   ( 20 )     skip-string            ( 21 )     skip-branch
   ( 22 )     dummy                  ( default ) skip-word
;

\ Scan the parameter field of a colon definition and determine the
\ places where control is transferred.
: scan-pfa   (s cfa -- )
   dup extent n!
   breaks end-breaks n!
   >body
   begin
      dup token@ execution-class do-scan
      dup 0= exit? or
   until   drop
;
\ Decompile the parameter field of colon definition
: .pfa   (s cfa -- )
  dup scan-pfa next-break 3 lmargin ! indent
   >body
   begin
      ?cr   break-addr @ over =
         if    break-type @ execute  next-break
         else  dup token@ execution-class .execution-class
         then
      dup 0= exit? or
   until   
   drop
;
: .immediate   (s cfa -- )   immediate? if   .." immediate"   then   ;

: .definer (s cfa definer-cfa -- cfa )  .name dup .name ;

\ Display category of word
: .:          (s cfa definer -- )  .definer space space  .pfa   ;
: .constant   (s cfa definer -- )  over >body ?   .definer drop  ;
: .vocabulary (s cfa definer -- )  .definer drop ;
: .code       (s cfa definer -- )  .definer >code disassemble ;
: .variable   (s cfa definer -- )
   over >body .   .definer   .." value = " >body ?
;
: .user       (s cfa definer -- ) 
   over >body ?   .definer   .."  value = "   >data  ?
;
: .defer      (s cfa definer -- )
  .definer  .." is " cr  >data token@ (see)
;
: .alias      (s cfa definer -- )
   .definer >body token@ .name
;


\ Decompile a word whose type is not one of those listed in
\ definition-class.  These include does> and ;code words which
\ are not explicitly recognized in definition-class.
: .other   (s cfa definer -- )
    .definer   >body @ ."    ( Parameter field: " . ." ) "
;

\ Classify a word based on its cfa
: cf, ( --name ) ( find the next word and compile its code field value )
  ' token,
;
8 tassociative: definition-class
   ( 0 )   cf,  :          ( 1 )   cf,  constant
   ( 2 )   cf,  variable   ( 3 )   cf,  user
   ( 4 )   cf,  defer      ( 5 )   cf,  code
   ( 6 )   cf,  vocabulary ( 7 )   cf,  alias

9 case:   .definition-class
   ( 0 )   .:              ( 1 )   .constant
   ( 2 )   .variable       ( 3 )   .user
   ( 4 )   .defer          ( 5 )   .code
   ( 6 )   .vocabulary     ( 7 )   .alias
   ( 8 )   .other
;

\ top level of the decompiler SEE
: ((see   (s cfa -- )
   td 64 rmargin !
   dup dup definer dup   definition-class .definition-class
   .immediate
;
' ((see  is (see)

forth definitions
: see  \ name  (s -- )
   '  (see)
;
