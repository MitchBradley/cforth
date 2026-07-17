\ Decompiler, tip of the hat to Perry and Laxen's F83

decimal

only forth also hidden also forth definitions
defer (see)

hidden definitions
d# 300 2* /n* constant /positions
/positions buffer: positions
0 value end-positions
\ 0 value line-after-;

: init-positions  ( -- )  positions is end-positions  ;
: find-position  ( ip -- true | adr false )
   end-positions positions  ?do   ( ip )
      i 2@ nip                    ( ip that-ip )
      over =  if                  ( ip )
         drop i false             ( adr false )
         unloop exit              ( adr false -- )
      then                        ( ip )
   2 /n* +loop                    ( ip )
   drop true                      ( true )
;
0 value decompiler-ip
: add-position  ( ip -- )
   decompiler-ip find-position  if                 ( )
      end-positions  positions /positions +  >=    ( flag )
      abort" Decompiler position table overflow"   ( )
      end-positions  dup 2 na+  is end-positions   ( adr )
   then                                            ( adr )
   #out @ #line @ wljoin  decompiler-ip  rot 2!    ( )
;
: ip>position  ( ip -- true | #out #line false )
   find-position  if    ( )
      true              ( true )
   else                 ( adr )
      2@ drop lwsplit   ( #out #line )
      false             ( #out #line false )
   then                 ( true | #out #line false )
;
: ip-set-cursor  ( ip -- )
   ip>position 0=  if  at-xy  then
;

headers
defer indent
: (indent)  ( -- )  lmargin @ #out @ - 0 max spaces  ;
' (indent) is indent
headerless

: +indent  ( -- )   3 lmargin +!  cr  ;
: -indent  ( -- )  ??cr -3 lmargin +!  ;
\ : <indent  ( -- )  ??cr -3 lmargin +!  indent  3 lmargin +!   ;

headerless
\ Like ." but goes to a new line if needed.
: cr".  ( adr len -- )
   dup ?line  indent            ( adr len )
   add-position                 ( adr len )
   magenta-letters type cancel  ( )
;
: .."   ( -- )  [compile] " compile cr".  ; immediate

\ Positional case defining word
\ Subscripts start from 0
: out   ( # apf -- )  \ report out of range error
   cr  ." subscript out of range on "  dup body> .name
   ."    max is " ?   ."    tried " .  quit
;
: map  ( # apf -- a ) \ convert subscript # to address a
   2dup @  u<  if  na1+ swap na+   else   out  then
;
: maptoken  ( # apf -- a ) \ convert subscript # to address a
   2dup @  u<  if  na1+ swap /token * +   else   out  then
;

forth definitions

\ headers
: case:   (s n --  ) \ define positional case defining word
   create ,  hide    ]
   does>   ( #subscript -- ) \ executes #'th word
      maptoken  token@  execute
;

: tassociative:
   create ,
   does>         (s n -- index )
      dup @              ( n pfa cnt )
      dup >r -rot na1+        ( cnt n table-addr )
      r> 0  do                ( cnt n table-addr )
         2dup token@ =  if    ( cnt n pfa' )
            2drop drop   i 0 0   leave
         then
         \ clear stack and return index that matched
         ta1+
      loop
      2drop
;

hidden definitions
: #entries  ( associative-acf -- n )  >body @  ;

: nulldis  ( apf -- )  drop ." <no disassembler>"  ;
defer disassemble  ' nulldis is disassemble

\ headerless

\ Breaks is a list of places in a colon definition where control
\ is transferred without there being a branch nearby.
\ Each entry has two items: the address and a number which indicates
\ what kind of branch target it is (either a begin, for backward branches,
\ a then, for forward branches, or an exit.

d# 40 2* /n* constant /breaks
/breaks buffer: breaks
variable end-breaks

variable break-type  variable break-addr   variable where-break
: next-break  ( -- break-address break-type )
   -1 break-addr !   ( prime stack)
   end-breaks @  breaks  ?do
      i  2@ over   break-addr @ u<  if
         break-type !  break-addr !  i where-break !
      else
         2drop
      then
   /n 2* +loop
   break-addr @  -1  <>  if  -1 -1 where-break @ 2!  then
;
: forward-branch?  ( ip-of-branch-token -- f )
   dup >target u<
;

\ Bare-if? checks to see if the target address on the stack was
\ produced by an IF with no ELSE.  This is used to decide whether
\ to put a THEN at that target address.  If the conditional branch
\ to this target is part of an IF ELSE THEN, the target address
\ for the THEN is found from the ELSE.  If the conditional branch
\ to this target was produced by a WHILE, there is no THEN.
: bare-if? ( ip-of-branch-target -- f )
   /branch - /token - dup token@  ( ip' possible-branch-acf )
   dup ['] branch  =    \ unconditional branch means else or repeat
   if  drop drop false exit then  ( ip' acf )
   ['] ?branch =        \ cond. forw. branch is for an IF THEN with null body
   if   forward-branch?  else  drop true  then
;

\ While? decides if the conditional branch at the current ip is
\ for a WHILE as opposed to an IF.  It finds out by looking at the
\ target for the conditional branch;  if there is a backward branch
\ just before the target, it is a WHILE.
: while?  ( ip-of-?branch -- f )
  >target  /branch - /token - dup token@  ( ip' possible-branch-acf )
  ['] branch =  if          \ looking for the uncond. branch from the REPEAT
     forward-branch? 0=     \ if the branch is forward, it's an IF .. ELSE
  else
     drop false
  then

;

: .begin  ( -- )  .." begin " +indent  ;
: .then   ( -- )  -indent .." then"  cr  ;

0 value pf-end
\ Extent holds the largest known extent of the current word, as determined
\ by branch targets seen so far.  This is used to decide if an exit should
\ terminate the decompilation, or whether it is "protected" by a conditional.
variable extent  extent off
: +extent  ( possible-new-extent -- )  extent @ umax extent !  ;
: +branch  ( ip-of-branch -- next-ip )  ta1+ /branch +  ;
: .endof  ( ip -- ip' )  .." endof" cr +branch  ;
: .endcase  ( ip -- ip' )  .." endcase" cr ta1+  ;
[ifdef] notdef
: .$endof  ( ip -- ip' )  .." $endof" cr +branch  ;
: .$endcase  ( ip -- ip' )  .." $endcase" cr ta1+  ;
[then]

: add-break  ( break-address break-type -- )
   end-breaks @  breaks /breaks +  >=        ( adr,type full? )
   abort" Decompiler table overflow"         ( adr,type )
   end-breaks @ breaks >  if                 ( adr,type )
      over end-breaks @ /n 2* - >r r@ 2@     ( adr,type  adr prev-adr,type )
      ['] .endof  =  -rot  =  and  if        ( adr,type )
	 r@ 2@  2swap  r> 2!                 ( prev-adr,type )
      else                                   ( adr,type )
	 r> drop                             ( adr,type )
      then                                   ( adr,type )
   then                                      ( adr,type )
   end-breaks @ 2!  /n 2*  end-breaks +!     (  )
;
: ?add-break  ( break-address break-type -- )
   over             ( break-address break-type break-address )
   end-breaks @ breaks  ?do
      dup  i 2@ drop   =  ( found? )  if
         drop 0  leave
      then
   /n 2*  +loop     ( break-address break-type not-found? )

   if  add-break  else  2drop  then
;

: scan-of  ( ip-of-(of -- ip' )
   dup >target dup +extent   ( ip next-of )
   /branch - /token -        ( ip endof-addr )
   dup ['] .endof add-break  ( ip endof-addr )
   ['] .endcase ?add-break
   +branch
;
0 [if]
: scan-$of  ( ip-of-($of -- ip' )
   dup >target dup +extent   ( ip next-$of )
   /branch - /token -        ( ip $endof-addr )
   dup ['] .$endof add-break  ( ip $endof-addr )
   ['] .$endcase ?add-break
   +branch
;
[then]
: scan-branch  ( ip-of-?branch -- ip' )
   dup dup forward-branch?  if
      >target dup +extent   ( branch-target-address)
      dup bare-if?  if  ( ip ) \ is this an IF branch?
         ['] .then add-break
      else
         drop
      then
   else
      >target  ['] .begin add-break
   then
   +branch
;

: skip-char ( ip -- ip' )  ta1+  ta1+  ;
: scan-unnest  ( ip -- ip' | 0 )
   dup extent @ u>=  if  ta1+ to pf-end 0  else  ta1+  then
;
: scan-does> ( ip -- ip' )  ta1+  ;
[ifdef] (;code)
: scan-;code ( ip -- ip' | 0 )  does-ip?  0=  if  to pf-end 0  then  ;
: .;code    (s ip -- ip' )
   does-ip?  if
      ??cr .." does> "
   else
      ??cr 0 lmargin ! .." ;code "  cr disassemble     0
   then
;
[then]
: .branch  ( ip -- ip' )
   dup forward-branch?  if
      -indent .." else" +indent
   else
      -indent .." repeat" cr
   then
   +branch
;
: .?branch  ( ip -- ip' )
  dup forward-branch?  if
     dup while?  if
        -indent .." while" +indent
     else
        .." if"  +indent
     then
  else
     -indent .." until " cr
  then
  +branch
;

: .do     ( ip -- ip' )  .." do    " +indent  +branch  ;
: .?do    ( ip -- ip' )  .." ?do   " +indent  +branch  ;
: .loop   ( ip -- ip' )  -indent .." loop  " cr +branch  ;
: .+loop  ( ip -- ip' )  -indent .." +loop " cr +branch  ;
: .of     ( ip -- ip' )  .." of   " +branch  ;
[ifdef] notdef
: .$of    ( ip -- ip' )  .." $of  " +branch  ;
[then]

\ first check for word being immediate so that it may be preceded
\ by postpone if necessary
: check-postpone  ( acf -- acf )
   dup immediate?  if  .." postpone "  then
;

: put"  (s -- )  [char] " emit  space  ;

: cword-name  (s ip -- ip' $ name$ )
   dup token@          ( ip acf )
   >name$              ( ip name$ )
   swap 1+ swap 2 -    ( ip name$' )  \ Remove parentheses
   rot ta1+ -rot       ( ip' name$ )
   2 pick count        ( ip name$ $ )
   2swap               ( ip $ name$ )
;

: type#  ( $ -- )  \ render control characters as green #
   bounds ?do
      i c@ dup h# 20 < if
	 drop green-letters ." #" red-letters
      else
	 emit
      then
   loop
;

: .string-tail  ( $ name$ -- )
   2 pick over +  3 + ?line    ( $ name$ )  \ Keep word and string on the same line
   cr".  space                 ( $ )
   red-letters type#           ( )
   magenta-letters             ( )
   [char] " emit space         ( )
   cancel                      ( )
;

: pretty-. ( n -- )
   base @ d# 10 =  if  (.)  else  (u.)  then   ( adr len )
   dup 3 + ?line  indent  add-position
   green-letters 
   base @ case
      d# 10 of  ." #"  endof
      d# 16 of  ." $"  endof
      d#  8 of  ." o# "  endof
      d#  2 of  ." %"  endof
   endcase
   type space cancel
;
: pretty-f.  ( adr len -- )
   dup 3 + ?line  indent  add-position
   green-letters  type  ." f "  cancel
;

: .compiled  ( ip -- ip' )
   dup token@ check-postpone    ( ip xt )
   >name$                       ( ip adr len )
   type space                   ( ip )
   ta1+                         ( ip' )
;
: .word         ( ip -- ip' )
   indent
   dup token@ check-postpone    ( ip xt )
   >name$                       ( ip adr len )
   dup ?line  add-position      ( ip adr len )
   type space                   ( ip )
   ta1+                         ( ip' )
;
: skip-word     ( ip -- ip' )  ta1+  ;
: .inline       ( ip -- ip' )  ta1+ dup unaligned-@  pretty-.  na1+   ;
: skip-inline   ( ip -- ip' )  ta1+ na1+  ;
: .wlit         ( ip -- ip' )  ta1+ dup branch@ pretty-. /branch +  ;
: skip-wlit     ( ip -- ip' )  ta1+ wa1+  ;
: .flit         (s ip -- ip' )
   ta1+ >r
float?  ?\  r@ la1+ l@   r@ l@   fpush fstring pretty-f.
   r> la1+ la1+
;
: skip-flit     ( ip -- ip' )  ta1+ la1+ la1+  ;
: .llit         ( ip -- ip' )  ta1+ dup unaligned-l@ pretty-. la1+  ;
: skip-llit     ( ip -- ip' )  ta1+ la1+  ;
[ifdef] notdef
: .dlit         ( ip -- ip' )  ta1+ dup d@ (d.) add-position green-letters type ." . " cancel  2 na+  ;
: skip-dlit     ( ip -- ip' )  ta1+ 2 na+  ;
[then]
: skip-branch   ( ip -- ip' )  +branch  ;
: .compile      ( ip -- ip' )  .." compile " ta1+ .compiled   ;
: skip-compile  ( ip -- ip' )  ta1+ ta1+  ;
: skip-string   ( ip -- ip' )  ta1+ +str  ;
: .[']          ( ip -- ip' )  ta1+  .." ['] " dup token@ .name  ta1+ ;
headers
: skip-[']      ( ip -- ip' )  ta1+ ta1+  ;
headerless
: .to           ( ip -- ip' )  .." to "  ta1+ dup token@ .name  ta1+  ;
: .string       ( ip -- ip' )  cword-name              .string-tail +str   ;
[ifdef] notdef
: skip-nstring  ( ip -- ip' )  ta1+ +nstr  ;
: .nstring      ( ip -- ip' )  ta1+  dup ncount " n""" .string-tail +nstr  ;
[then]

\ Use this version of .branch if the structured conditional code is not used
\ : .branch     ( ip -- ip' )  .word   dup <w@ .   /branch +   ;

: .does>      (s ip -- ip' )  .." does> "  ta1+  ;
: .unnest     ( ip -- ip' )
   dup extent @ u>=  if
      ??cr 0 lmargin ! .." ;" drop   0
   else
      .." exit " ta1+
   then
;
: dummy ;

: .char    ( ip -- ip' )
   .." '"  ta1+  dup @ emit space  na1+
;

\ classify each word in a definition

\  Common constant for sizing the three classes:
d# 23 constant #decomp-classes

#decomp-classes tassociative: execution-class  ( token -- index )
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
#decomp-classes 1+ case: .execution-class  ( ip index -- ip' )
   (  0 )     .inline                (  1 )     .?branch
   (  2 )     .branch                (  3 )     .loop
   (  4 )     .+loop                 (  5 )     .do
   (  6 )     .compile               (  7 )     .string
   (  8 )     .string                (  9 )     dummy
   ( 10 )     .unnest                ( 11 )     .string
   ( 12 )     .?do                   ( 13 )     .does>
   ( 14 )     .char                  ( 15 )     .flit
   ( 16 )     .[']                   ( 17 )     .of
   ( 18 )     .endof                 ( 19 )     .endcase
   ( 20 )     .string                ( 21 )     .wlit
   ( 22 )     dummy                  ( default ) .word
;

\ Determine the control structure implications of a word
\ which has been classified by  execution-class
#decomp-classes 1+ case: do-scan
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

[ifdef] notdef
headers
also forth definitions
: install-decomp  ( literal-acf display-acf skip-acf -- )
   ['] dummy ['] do-scan          (patch
   ['] dummy ['] .execution-class (patch
   ['] dummy ['] execution-class >body na1+
	       dup [ #decomp-classes ] literal ta+ tsearch
   drop token!
;
previous definitions
headerless
[then]

\ Scan the parameter field of a colon definition and determine the
\ places where control is transferred.
: scan-pf   ( apf -- )
   dup extent !                           ( apf )
   breaks end-breaks !                    ( apf )
   begin                                  ( adr )
      dup token@ execution-class do-scan  ( adr' )
      dup 0=                              ( adr' flag )
   until                                  ( adr )
   drop
;

forth definitions
headers
: .token  ( ip -- ip' )  dup token@ execution-class .execution-class  ;
\ Decompile the parameter field of colon definition
: .pf   ( apf -- )
   init-positions                                     ( apf )
   dup scan-pf next-break 3 lmargin ! indent          ( apf )
   begin                                              ( adr )
      dup is decompiler-ip                            ( adr )
      ?cr                                             ( adr )
      break-addr @ over =  if                         ( adr )
	 begin                                        ( adr )
	    break-type @ execute                      ( adr )
	    next-break  break-addr @ over <>          ( adr done? )
	 until                                        ( adr )
      else                                            ( adr )
         .token                                       ( adr' )
      then                                            ( adr' )
      dup 0=  exit?  if  nullstring throw  then       ( adr' )
   until  drop                                        (  )
;
headerless
hidden definitions

: .immediate  ( acf -- )   immediate? if   .." immediate"   then   ;

: .definer    ( acf definer-acf -- acf )
   magenta-letters .name  dup blue-letters  .name  cancel
;

: dump-body  ( pfa -- )
   push-hex
   dup @ pretty-. 2 spaces  8 emit.ln
   pop-base
;
\ Display category of word
: .:           ( acf definer -- )  .definer cr ( space space ) >body  .pf   ;
: debug-see    ( apf -- )
\   page-mode? >r  no-page
   find-cfa ['] :  .:
\   r> is page-mode?
;
: .constant    ( acf definer -- )  over >data @ pretty-.  .definer drop  ;
: .2constant   ( acf definer -- )  over >data dup @ pretty-.  na1+ @ pretty-. .definer drop  ;
: .vocabulary  ( acf definer -- )  .definer drop  ;
: .code        ( acf definer -- )  .definer >code disassemble  ;
: .variable    ( acf definer -- )
   over >data n.   .definer   ." value = " >data @ pretty-.
;
: .create     ( acf definer -- )
   over >body n.   .definer   ." value = " >body dump-body
;
: .user        ( acf definer -- )
   over >body @ n.   .definer   ."  value = "   >data @ pretty-.
;
: .defer       ( acf definer -- )
   .definer  ." is " cr  >data token@ (see)
;
: .alias       ( acf definer -- )
   .definer >body token@ .name
;
: .value      ( acf definer -- )
   swap >data @ pretty-. .definer
;


\ Decompile a word whose type is not one of those listed in
\ definition-class.  These include does> and ;code words which
\ are not explicitly recognized in definition-class.
: .other   ( acf definer -- )
   .definer   >body ."    (Body: " dump-body ."  ) " cr
;

: cf,  \ name  ( -- )  \ Compile name's code field
   ' token,
;
d# 12 constant #definition-classes
#definition-classes tassociative: definition-class
   ( 0 )   cf,  :          ( 1 )   cf,  constant
   ( 2 )   cf,  variable   ( 3 )   cf,  user
   ( 4 )   cf,  defer      ( 5 )   cf,  create
   ( 6 )   cf,  vocabulary ( 7 )   cf,  alias
   ( 8 )   cf,  value      ( 9 )   cf,  2constant
   ( 10)   cf,  code       ( 11 )  cf,  dummy

#definition-classes 1+ case: .definition-class
   ( 0 )   .:              ( 1 )   .constant
   ( 2 )   .variable       ( 3 )   .user
   ( 4 )   .defer          ( 5 )   .create
   ( 6 )   .vocabulary     ( 7 )   .alias
   ( 8 )   .value          ( 9 )   .2constant
   ( 10)   .code           ( 11)   dummy
   ( 12)   .other
;

headers
also forth definitions
: install-decomp-definer  ( definer-acf display-acf -- )
   ['] dummy ['] .definition-class (patch
   ['] dummy ['] definition-class >body na1+
	       dup [ #definition-classes ] literal ta+ tsearch
   drop token!
;
previous definitions
headerless

[ifdef] notdef
: does/;code-xt?  ( xt -- flag )
   dup  ['] (does>) =  swap  ['] (;code) =  or
;
: does/;code-action?  ( action-acf -- flag )
   dup -1 ta+ token@ does/;code-xt?  if  drop true exit  then
   -2 ta+ token@ does/;code-xt?
;
[then]

\ top level of the decompiler SEE
: ((see   ( acf -- )
   d# 48 rmargin !
   dup dup definer dup   definition-class .definition-class
   .immediate
   ??cr
;
headers
' ((see  is (see)

forth definitions

: see  \ name  ( -- )
   '  ['] (see) catch  if  drop  then
;
only forth also definitions
