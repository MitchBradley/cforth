: ok ;
: trigger  0 0 2>r 2r>  drop drop  ; immediate
\ : [cr] cr ; immediate
\ : rep  [char] A emit cr foo hex 40 dump decimal cr  trigger  ; immediate
\ : repb [char] B emit cr foo hex 40 dump decimal cr  trigger  ; immediate
: x. dup . cr ;

decimal

: /n  1 cells  ;
: na1+  cell+  ;
: na+  cells +  ;

/token constant #align

\ : again  ( sys -- )  postpone branch <resolve  ;  immediate

: 1-  ( n1 -- n2 )  1 -  ;
: 2*  ( n1 -- n2 )  2 *  ;

\ : 2dup  ( n1 n2 -- n1 n2 n1 n2 )  over over  ;
\ : 2drop  ( n1 n2 -- )  drop drop  ;
\ : 2swap  ( n1 n2 n3 n4 -- n3 n4 n1 n2 )  rot >r rot r>  ;
: 2over  ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 )  3 pick  3 pick  ;
: 2@  ( adr -- n1 n2 )  dup /n + @ swap @  ;
: 2!  ( n1 n2 adr -- )  swap over ! /n + !  ;
\ : -rot  ( n1 n2 n3 -- n3 n1 n2 )  rot rot  ;
: >=  ( n1 n2 -- flag )  < 0=  ;
: u<= ( u1 u2 -- flag )  2dup u< -rot = or  ;
: u>  ( u1 u2 -- flag )  u<= 0=  ;
: u>= ( u1 u2 -- flag )  u<  0=  ;
: <=  ( n1 n2 -- f )  > 0=  ;
\ : <>  ( n1 n2 -- flag )  = 0=  ;
: 0<> ( n -- flag )  0= 0=  ;
: 0<= ( n -- flag )  dup 0=  swap 0<  or  ;
: 0>= ( n -- flag )  0< 0=  ;
: (s  ( -- )  postpone (  ; immediate
: pad  ( -- adr )  here 100 +  ;
: space  ( -- )  bl emit  ;
: spaces  ( n -- )  0 ?do space loop  ;
\ : c,  ( char -- )   here  1 allot  c!  ;

: fm/mod  ( d.dividend n.divisor -- n.rem n.quot )
   2dup xor 0<  if	    \ Fixup only if operands have opposite signs
      dup >r  sm/rem                                ( rem' quot' r: divisor )
      over  if  1- swap r> + swap  else  r> drop  then
      exit
   then
   \ In the usual case of similar signs (i.e. positive quotient),
   \ sm/rem gives the correct answer
   sm/rem   ( n.rem' n.quot' )
;
: */mod  ( n n.num n.denom -- n.rem n.quot )  >r m* r> fm/mod  ;
: */  ( n n.num n.denom -- n.quot )  */mod nip  ;

: noop  ( -- )  ;

: aligned  ( adr -- aligned-adr )
   [ #align 1- ] literal +  [ #align negate ] literal and
;
: align  ( -- )  here here aligned swap - allot  ;

: laligned  ( adr -- aligned-adr )  3 +  -4 and  ;
: lalign  ( -- )  here here laligned swap - allot  ;

: erase  ( adr count -- )  0 fill  ;
: off  ( adr -- )  false swap !  ;
: on  ( adr -- )  true swap !  ;
: umax  ( u1 u2 -- umax )  2dup u<  if  swap  then  drop  ;
: within  ( n1 min max+1 -- f )  over - >r - r> u<  ;
: between  ( n min max -- f )  1+ within  ;
: primitive?  ( acf | prim -- flag )  1 maxprimitive within  ;

: octal   ( -- )  8 base !  ;
: binary   ( -- )  2 base !  ;

: ta1+  ( adr -- adr' )  /token +  ;
: ta+  ( adr index -- adr' )  /token * +  ;

\ Words to follow dictionary links
/token constant /link

hex
: >link  ( acf -- lfa )  /token -  ;
: >flags  ( acf -- aff )  >link 1-  ;
: immediate?  ( acf -- f )  >flags c@ 80 and  ;
: >name$  ( acf -- adr len )
   >flags         ( len_byte_adr )
   dup c@ 3f and  ( len_byte_adr len )
   tuck - swap    ( adr len )
;
: .name  ( acf -- )  >name$ type space  ;
: lastacf  ( -- acf )  last token@  ;
: body>  ( apf -- acf )  /token -  ;
decimal

: lshift  ( n count -- n' )  shift  ;
: rshift  ( n count -- n' )  negate shift  ;
: <<  ( n count -- n' )  shift  ;
: >>  ( n count -- n' )  negate shift  ;

: unum@  ( apf -- user# )
\t16 w@
\t32  @
;
: >user#  ( acf -- user# )  >body unum@  ;
: >user  ( apf -- user-adr )  unum@ up@ +  ;
: 'user#  ( "name" -- user# )  '  ( cfa-of-user-variable )  >user#  ;

decimal
: word-type  ( acf -- word-type )
   dup primitive?  if  drop -1 ( code word ) exit  then
\t16 w@
\t32  @
   dup primitive?  if  drop -1 ( code word )  then
;
: ualloc  ( size -- user-number )  #user @  swap #user +!  ;
: nuser  \ name  ( -- )
   /n ualloc user
;

\ : token@  ( adr -- acf)
\    @  ( acf| prim )  dup primitive?  if  origin swap na+ @  then
\ ;
: crash  ( -- )  \ unitialized execution vector routine
  r@ /token - token@         ( use the return stack to see who called us )
   dup ['] execute =  if
      \ XXX display the location in the input buffer
   else   .name   then
\   ." <--deferred word not initialized " abort
;
\ : (set-relocation-bit)  ( adr -- adr )
\   dup  origin here between  over  up@ dup user-size + between  or  if
\      dup >relbit over c@ or swap c!
\   then
\ ;
: defer  ( -- )
   create
   (defer) here body>
\t16 w!
\t32  !
   here /n ualloc ,

   >user ['] crash token!
;
defer defxx
\ defer set-relocation-bit

\ Note: It might be possible to define:
\ : token!  ( acf adr -- )
\   swap dup  ['] invert  ['] #user  between  if  @ swap !  exit  then
\   over !  set-relocation-bit drop
\ ;
\ : link!  ( link alf -- )  tuck !  set-relocation-bit drop  ;

\ : token!  ( acf adr -- )
\    swap dup  ['] invert  ['] #user  between  if
\       dup @  primitive?  if  @ swap ! exit  then
\    then
\    over !  set-relocation-bit drop
\ ;
: token,  ( acf -- )  here  /token allot  token!  ;

: n! !  ;
\ : !  ( n adr -- )
\    over  origin here  between  if
\       ." ! should be token! "
\       state @  if  ." compiling "  else  ." after "  then
\       lastacf .name cr
\    then
\    !
\ ;
: link@  ( adr -- link )  token@  ;
: link!  ( link adr -- )  token!  ;
: link,  ( link -- )  token,  ;

: non-null?  ( link -- false | link true )  dup origin <>  dup 0=  if  nip  then  ;

: ,unum  ( #bytes -- )  #user @  here branch!  /branch allot  #user +!  ;

: value  ( "name" n -- )
   create             ( n )
   #user @  /n ,unum  ( n user# )
   up@ + !            ( )
   does> >user @
;
0 value myval

: useradr  ( acf type -- data-adr )  drop >body >user  ;
: (to)  ( n acf -- data-adr )
   dup word-type               ( n acf code-field-word )
   dup ['] myval word-type  =  if  useradr !      exit  then
   dup ['] defxx word-type  =  if  useradr token! exit  then
   dup ['] #user word-type  =  if  useradr !      exit  then
   dup ['] forth word-type  =  if  useradr token! exit  then
   drop >body !
;
: to  ( "name" [ val ] -- )	\ val is present only in interpret state
   state @  if   postpone ['] postpone (to)  else  ' (to)  then
; immediate

: header  ( "name" -- )  safe-parse-word $header  ;

\ ' (set-relocation-bit) to set-relocation-bit

\ The following definitions are implementation-independent

decimal
: definitions  ( -- )  context token@ current token!  ;

\ Determine if the user wants to abort a listing or something.

defer exit?  ( -- flag )
' key? to exit?

: bounds  ( adr len -- endadr startadr )  over + swap  ;

\ A convenient word for stepping through and displaying a range of locations
: ..  ( adr -- adr' )  dup @ . na1+  ;

: do-defined  ( acf [ -1 | 0 | 1 ] -- ?? )
   state @  if
      0>  if  execute  else  token,  then
   else
      drop execute
   then
;

\ True if n is a printable character.
: printable?  ( n -- flag )  bl 127 within  ;
: control  \ name  ( -- n )
   safe-parse-word drop c@  bl 1- and  state @  if  postpone literal  then
; immediate

: move  ( from to len -- )
   -rot  2dup u< if  rot cmove>   else  rot  cmove then
;
: place  ( adr len to-adr -- )  2dup c!  2dup + 1+  0 swap c!  1+ swap move  ;
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
: ("s)  ( -- str-adr )  skipstr drop 1-  ;
: (")  ( -- adr len )  skipstr  ;

: sliteral  ( adr len -- )  postpone (")  ",  ; immediate
: s"  \ string  ( -- adr len )
   [char] " parse
   state @  if  postpone sliteral  then
; immediate

: (c")  ( -- adr )  skipstr drop  ;
: csliteral  ( adr len -- )  postpone (c")  ",  ; immediate
: c"  \ string  ( -- adr )
   [char] " parse  2dup + 0 swap c!   ( adr len )
   state @  if  postpone csliteral  else  drop  then
; immediate

: ,"  ( "string" -- )  [char] " parse ",  ;

: ."  ( "string" -- )  postpone (.") ,"  ; immediate

nuser 'abort$
: (abort")  ( flag -- )
   if
      skipstr drop 1- 'abort$ !  -2 throw
   else
      skipstr 2drop
   then
;

: abort"  ( "string" -- )  postpone (abort") ,"  ; immediate

32\ : l0=  ( l -- flag )  0=  ;
16\ : l0=  ( l -- flag )  0= swap 0= and  ;
defer error-output  ( -- )
' noop to error-output  \ XXX Should select standard error

defer restore-output  ( -- )
' noop to restore-output  \ XXX Should reselect standard output

: (where  ( -- )
   interactive?  if
      state @  if  ." Compiling "  else  ." Latest word was "   then
      lastacf .name  cr
   then
;

defer where
' (where to where

: ?stack  ( -- )
   sp@  sp0 @  swap   u<  if
      error-output ." Stack Underflow " where restore-output
      sp0 @ sp!  abort
   then
   sp@  sp0 @ 400 -  u<  abort" Stack Overflow "
;

nuser csp
: !csp  ( -- )  sp@ csp !  ;
: ?csp  ( -- )
   sp@ csp @ <>
   if error-output ." Stack Changed " where restore-output abort then
;

\ Alias makes a new word which behaves exactly like an existing
\ word.  This works whether the new word is encountered during
\ compilation or interpretation, and does the right thing even
\ if the old word is immediate.

: 'i  ( "name" -- acf )
   $defined  dup 0=  if  drop .not-found abort  then
;
: setalias  ( xt +-1 -- )
   swap token, ,  immediate          ( )
   does>  dup token@ swap ta1+ @     ( xt +-1 )
   do-defined
;
: alias  \ new-name old-name  ( -- )
   create hide  'i  reveal  setalias
;

32\ : 32-bit ; immediate
32\ : 16-bit 1 abort" Not a 16 bit forth" ; immediate
32\ alias ldrop drop   ( l -- )
32\ alias ldup  dup    ( l -- l l )
32\ alias l+ +         ( l1 l2 -- l3 )
32\ alias ul* *        ( ul1 ul2 -- ul3 )
32\ alias l+! +!       ( l adr -- )
32\ alias lnover over  ( l n -- l n l )
32\ alias nlover over  ( n l -- n l n )
32\ alias nlswap swap  ( n l -- l n )
32\ alias lnswap swap  ( l n -- n l )
32\ alias lswap swap   ( l1 l2 -- l2 l1 )
32\ alias l= =         ( l1 l2 -- flag )
32\ alias l< <         ( l1 l2 -- flag )
32\ alias l>= >=       ( l1 l2 -- flag )
32\ alias lliteral literal  ( l -- )
32\ alias land and          ( l1 l2 -- l3 )
32\ alias lnegate negate    ( l1 -- l2 )
\ 32\ alias l@ @         ( adr -- l )
\ 32\ alias l! !         ( l adr -- )     
32\ alias l, ,         ( l -- )
32\ alias lr> r>       ( -- l )
32\ alias l>r >r       ( l -- )
32\ : l->n ; immediate ( l -- n )
32\ : w->l ; immediate ( w -- l )
32\ hex
32\ : s->l  ( w -- l )
32\   dup  00008000 and
32\   if   ffff0000 or
32\   else 0000ffff and
32\   then
32\  ;
32\ alias lvariable variable
32\ alias lconstant constant
32\ : n->w  ( n -- w )  ffff and  ;

16\ : 16-bit ; immediate
16\ : 32-bit 1 abort" Not a 32 bit forth" ; immediate
16\ alias ldrop 2drop
16\ alias ldup  2dup
16\ alias l+ d+
16\ alias ul* um*
16\ : lnover 2 pick 2 pick  ;
16\ : nlover 2 pick  ;
16\ alias nlswap rot
16\ alias lnswap -rot
16\ alias lswap 2swap
16\ : l=  rot = >r  = r>  and  ;
16\ : l<  ( l1 l2 -- flag )
16\    2 pick over <  if   ( l1 l2 )
16\      2drop 2drop true  ( true )
16\    else
16\    2 pick over >  if   ( l1 l2 )
16\      2drop 2drop false ( false )
16\    else
16\      drop nip <        ( flag )
16\    then then
16\  ;
16\ : l>= l< 0=  ;
16\ : lliteral  ( l -- )
16\   state @
16\   if   swap postpone (lit) , postpone (lit) ,  then
16\  ;
16\ : land  ( l1 l2 -- l3 )  rot and >r and r>  ;
16\ alias lnegate dnegate
16\ : labs  ( l1 -- l2 )  dup 0<  if  lnegate  then  ;
\ 16\ alias l@ 2@
\ 16\ alias l! 2!
16\ : l+!  ( l adr -- )  dup >r l@  l+  r> l!  ;
16\ : l, , ,  ;
16\ : lr> r> r>  ;
16\ : l>r >r >r  ;
16\ alias l->n drop
16\ : w->l 0  ;
16\ hex
16\ : s->l  ( w -- l )  dup  8000 and 0<>  ;
16\ : lvariable variable /n allot  ;
16\ : lconstant  create l,  does> l@  ;
16\ : n->w ; immediate
alias n->l w->l
decimal

: s>d  ( n -- d )  dup 0<  ;
: u>d  ( u -- d )  0  ;

alias ca+ +  ( adr1 n -- adr2 )
: wa+  ( adr1 n -- adr2 )  /w* +  ;
: la+  ( adr1 n -- adr2 )  /l* +  ;

: w,  ( w -- )  here /w allot w!  ;
: <w@  ( adr -- signed.w )  w@ s->l  ;

alias is to

nuser hld
: hold  ( char -- )  -1 hld +!   hld @ c!  ;
: <#    ( -- )  pad  hld  !  ;
: #>  ( d# -- adr len )  2drop  hld  @  pad  over  -  ;
: sign  ( d# n1 -- d# )  0< if  [char] -  hold  then  ;
: mu/mod  (s d# n1 -- rem d#quot )
   >r  0  r@  um/mod  r>  swap  >r  um/mod  r>
;
: #  ( n1 d# -- n1 d# )
   base @ mu/mod           ( n1 nrem d# )
   rot                     ( n1 d# nrem )
   dup 9 >  if  10 - [char] a +  else  [char] 0 +  then  ( n1 d# nrem' )
   hold
;
: d0=  ( d -- flag )  or 0=  ;
: #s  ( n1 d# -- n1 d#' )  begin  #  2dup d0=  until  ;

: (u.)  ( u -- a len )  u>d  <# #s #>  ;
warning off
: u.  ( u -- )  (u.)  type space  ;
warning on
: u.r  ( u len -- )  >r   (u.)   r> over - spaces  type  ;
: (.)  ( n -- a len )  dup abs u>d   <# #s  rot sign   #>  ;
: s.  ( n -- )  (.)   type space  ;
: .  ( n -- ) base @ 10 =  if  s.  else  u.  then  ;
: .r  ( n l -- )  >r  (.)  r> over - spaces  type  ;
16\ : l.  ( l -- )  tuck labs  <# #s nlswap sign #> type space  ;
16\ : ul.  ( l -- )  <# #s #> type space  ;
32\ alias l. .         ( l -- )
: (.s  ( -- )  depth 0 ?do  depth i - 1- pick .  loop  ;
: .s  ( -- )  ?stack  depth  if  (.s  else  ." Empty "  then  ;

: ?  ( adr -- )  @ .  ;

: .x  base @ swap hex . base !  ;

\ A much better dump utility is loaded in a later file.  However, in the
\ porting stage, it is often nice to have a very simple dump which may
\ work even if some things are broken
: ndump  ( adr count -- )  bounds  ?do  i @ .  /n +loop  ;
: wdump  ( adr count -- )  bounds  ?do  i w@ .  2 +loop  ;
: cdump  ( adr count -- )  bounds  ?do  i c@ .  loop  ;

16 constant #vocs	\ Must agree with NVOCS in forth.h
1 constant #threads

: vocabulary  \ name  ( -- )
   create
   here body>    #user @                 ( my-acf user# )
   \ This is wasteful - should be /token * - but it keeps #user cell aligned
   #threads cells   ,unum                ( my-acf user# )
   up@ +                                 ( my-acf ua-adr )
   #threads 0  do  origin over token!  ta1+  loop  drop   ( my-acf )
   voc-link link@ link,  voc-link link!
   does>  body> context token!
;

\ The also/only vocabulary search order scheme
: another-link?  ( link -- false | link' true )  link@ non-null?  ;
: >threads  ( acf -- threads-adr )  >body >user  ;
: >voc-link  ( acf -- link )  >body /branch +  ;
: voc>  ( voc-link-target-adr -- acf )  ;

context dup token@ swap ta1+ token!  \ make forth also
vocabulary root  root definitions
: also  ( -- )
   context dup ta1+ #vocs 2- /token * cmove>
;
: only  ( -- )
   #vocs 0  do
      origin  context i ta+  token!
   loop
   ['] root  context #vocs 1- ta+  token!
   root
;
\ XXX This implementation is not in accordance with the standard.
\ It should not require an argument.
: seal  \ vocabulary-name  ( -- )
   ' >body   context #vocs /n * erase   context token!
;
: previous  ( -- )
   context dup ta1+ swap #vocs 2- /token * cmove
   context #vocs 2- /token * +  origin swap token!
;

: forth  ( -- )  forth  ;
: definitions  ( -- )  definitions   ;
: order  ( -- )
   ." context: " context
   #vocs 0
   do   dup token@ non-null?  if  .name  then  ta1+  loop drop
   4 spaces ." current: " current token@  .name
;
: vocs  ( -- )
   voc-link
   begin  another-link?  while   dup .name  >voc-link  repeat
;
variable largest
: follow  ( voc -- )  >threads link@  largest link!  ;
: another?  ( -- false | acf true )
   largest link@  non-null?  if       ( acf )
      dup >link link@  largest link!  ( acf )
      true                            ( acf true )
   else                               ( )
      false                           ( false )
   then
;

only forth also definitions
vocabulary hidden
: dp!  ( adr -- )  here - allot  ;
nuser fence
: trim  ( fadr voc-adr -- )
   #threads 0  do
      2dup  begin  link@  2dup u>  until  ( fadr thread  fadr link' )
      nip over link!                      ( fadr thread )
      /link +
   loop
   2drop
;
\ It is a bad idea to do a forget that will result in the forgetting of
\ vocabularies that are presently in the search order.
: (forget   ( acf -- )
   >link
   dup fence link@ u< abort" below fence"  ( adr )
   \ first forget any vocabularies defined since the word to forget

   dup voc-link
   begin   link@ 2dup  u>=  until      ( adr voc-link-adr )
   dup voc-link link! nip              ( adr voc-link-adr )

   \ now, for all remaining vocabularies, forget words defined
   \ since the word to forget )
   begin
      dup origin  <>  ( any more vocabularies? )
   while
      2dup  >threads  ( adr voc-link-adr adr voc-threads-adr )
      trim            ( adr voc-link-adr )
      link@           ( adr new-voc-link-adr )
   repeat
   drop   dp!
;
: forget   ( -- )
   safe-parse-word current @ search-wordlist
   0= abort" Can't find word to forget"
   (forget
;

only forth also definitions
: ?comp  ( -- )  state @  0= abort" Compilation Only "  ;
: ?exec  ( -- )  state @     abort" Execution Only "  ;
: ?pairs  ( -- )  - abort" Conditionals not paired "  ;

32\ : /n*  ( n1 -- n2 )  2 <<  ;
16\ : /n*  ( n1 -- n2 )  dup +  ;
\ : ??cr  ( -- )  #out @  if  cr  then  ;

\ Modes for opening files
0 constant read
1 constant write
2 constant modify

: recurse  ( -- )  lastacf compile,  ; immediate
alias not invert   ( x -- x' )
: chars  ( -- )  ;
: char+  ( adr -- adr' )  1+  ;
: unloop  ( -- )  r>  r> drop r> drop  r> drop  >r  ;
: blank  ( c-addr u -- )  bl fill  ;

alias " s"

defer pause
' noop to pause		\ No multitasking for now

: 3drop  ( n1 n2 n3 -- )  2drop drop  ;

: push-hex  ( -- )  r>  base @ >r  >r  hex  ;
: push-decimal  ( -- )  r>  base @ >r  >r  decimal  ;
: pop-base  ( -- )  r>  r> base !  >r  ;
: .d  push-decimal . pop-base  ;
: .h  push-hex u. pop-base  ;

: .abort  ( -- )  'abort$ @ count type  ;
: (.error)  ( throw-code -- )
   dup -2 =  if
      .abort
   else
      dup -1 =  if  drop ." Aborted"  else  ." Error " .d  then
   then
   cr
;
' (.error) to .error

decimal
: (cr  ( -- )  13 emit  ;
: u#   ( u1 -- u2 )  0 # drop  ;
: u#s  ( u1 -- u2 )  0 #s drop  ;
: u#> ( u -- )  0 #>  ;

create nullstring 0 c,

: $number  ( adr len -- n false | true )
   $number?  if  drop false  else  true  then
;

: u2/  ( n1 -- n2 )  1 rshift  ;

: round-up  ( n boundary -- n' )  1- tuck + swap invert and  ;
