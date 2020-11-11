: move  ( from to len -- )
   -rot  2dup u< if  rot cmove>   else  rot  cmove then
;
: ."  ( "string" -- )
   state @  if
      compile (.") ,"
   else
      [char] " parse type
   then
; immediate

: off  ( adr -- )  false swap !  ;
: on  ( adr -- )  true swap !  ;

: s(  [char] ) parse  ;
warning off
: .(  s( type  ;
warning on

: ok ;

decimal

: /n  1 cells  ;
: na1+  cell+  ;
: na+  cells +  ;

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
: pad  ( -- adr )  here 140 +  ;  \ Enough for 128 bits of binary plus a few

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

: laligned  ( adr -- aligned-adr )  3 +  -4 and  ;
: lalign  ( -- )  here here laligned swap - allot  ;

: erase  ( adr count -- )  0 fill  ;
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
: >header  ( acf -- adr )  >name$ drop  ;
: lastacf  ( -- acf )  last token@  ;
: body>  ( apf -- acf )  /token -  ;
decimal

: lshift  ( n count -- n' )  shift  ;
: rshift  ( n count -- n' )  negate shift  ;
: <<  ( n count -- n' )  shift  ;
: >>  ( n count -- n' )  negate shift  ;

: cf@  ( acf -- n )  
\t16 w@
\t32  @
\t64  @
;
: cf!  ( n acf -- )
\t16 w!
\t32  !
\t64  !
;
: unum@  ( apf -- user# )
\t16 w@
\t32  @
\t64  @
;
: >user#  ( acf -- user# )  >body unum@  ;
: >user  ( apf -- user-adr )  unum@ up@ +  ;
: 'user#  ( "name" -- user# )  '  ( cfa-of-user-variable )  >user#  ;

decimal
: word-type  ( acf -- word-type )
   dup primitive?  if  drop -1 ( code word ) exit  then
   cf@ dup primitive?  if  drop -1 ( code word )  then
;
: ualloc  ( size -- user-number )  #user @  swap #user +!  ;
: nuser  \ name  ( -- )
   /n ualloc user
;

\ : token@  ( adr -- acf)
\    @  ( acf| prim )  dup primitive?  if  origin swap na+ @  then
\ ;
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

: !null-token  ( adr -- )  origin swap token!  ;
: non-null?  ( link -- false | link true )  dup origin <>  dup 0=  if  nip  then  ;
: get-token?  ( adr -- false | token true )  token@ non-null?  ;

: ,unum  ( #bytes -- )  #user @  here branch!  /branch allot  #user +!  ;

: value  ( "name" n -- )
   create             ( n )
   (value) here body> cf!

   #user @  /n ,unum  ( n user# )
   up@ + !            ( )
;
0 value isvalue

: (to)  ( n xt -- )
   dup >body  swap cf@         ( n 'body cf )
   dup (value)      =  if  drop >user !      exit  then
   dup (defer)      =  if  drop >user token! exit  then
   dup (user)       =  if  drop >user !      exit  then
   dup (vocabulary) =  if  drop >user token! exit  then
\   drop !
   drop body> to-hook
;
: to  ( "name" [ val ] -- )	\ val is present only in interpret state
   state @  if   postpone ['] postpone (to)  else  ' (to)  then
; immediate

' noop to status
' sys-emit to (emit
' sys-cr to cr

: emit  ( c -- )  1 #out +!  (emit   ;
: bounds  ( adr len -- endadr startadr )  over + swap  ;
\ Does not affect #out
: (type  ( adr len -- )  bounds  ?do  i c@ (emit  loop  ;
: do-type  ( adr len -- )  bounds  ?do  i c@ emit  loop  ;
' do-type to type

: space  ( -- )  bl emit  ;
: spaces  ( n -- )  0 max 0 ?do space loop  ;
: .name  ( acf -- )  >name$ type space  ;
: to-error  ( data acf -- )  ." Can't use to with " .name cr ( -32 ) abort  ;
' to-error to to-hook
: crash  ( -- )  \ unitialized execution vector routine
\   ." Uninitialized defer word "
   ip@ /token - token@         ( use the return stack to see who called us )
   dup ['] execute =  if
      where1
      \ XXX display the location in the input buffer
   else   .name  ." -- "  then
   ." deferred word not initialized " abort
;
\ : (set-relocation-bit)  ( adr -- adr )
\   dup  origin here between  over  up@ dup user-size + between  or  if
\      dup >relbit over c@ or swap c!
\   then
\ ;

: (where1)  ( -- )
   source                 ( adr len )
   ." Error at: "
   over >in @ type        ( adr len )
   ."  |  "               ( adr len )
   >in @ /string type cr  ( )
;
' (where1) to where1

: (.not-found)  ( name$ -- )  cr  type ."  ?"  cr  where1  ;
' (.not-found) to .not-found

: (.underflow)  ( -- )  ." Stack Underflow" cr  ;
' (.underflow) to .underflow
: (prompt)  ( -- )
   state @  if  ."  ] "  else  ." ok "  then
;
' (prompt) to prompt

: (header)  ( "name" -- )  safe-parse-word $header  ;
' (header) to header

: defer  ( -- )
   header defer-cf
   here /n ualloc ,

   >user ['] crash swap token!
;
defer defxx

\ ' (set-relocation-bit) to set-relocation-bit

\ The following definitions are implementation-independent

decimal
: definitions  ( -- )  context token@ current token!  ;

\ Determine if the user wants to abort a listing or something.

defer exit?  ( -- flag )
' key? to exit?


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

: (")  ( -- adr len )  skipstr  ;
: sliteral  ( adr len -- )  postpone (")  ",  ; immediate
: s"  \ string  ( -- adr len )
   [char] " parse
   state @  if  postpone sliteral  then
; immediate

: (c")  ( -- str-adr )  skipstr drop 1-  ;
: csliteral  ( adr len -- )  postpone (c")  ",  ; immediate
: c"  \ string  ( -- adr )
   [char] " parse  2dup + 0 swap c!   ( adr len )
   state @  if  postpone csliteral  else  drop  then
; immediate

nuser 'abort$
: (abort")  ( flag -- )
   if
      skipstr drop 1- 'abort$ !  -2 throw
   else
      skipstr 2drop
   then
;

: abort"  ( "string" -- )  postpone (abort") ,"  ; immediate

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

64\ #64 constant bits/cell
64\ : 64-bit ; immediate
64\ : 32-bit 1 abort" Not a 32 bit forth" ; immediate
64\ : 16-bit 1 abort" Not a 16 bit forth" ; immediate
64\ : l,  ( l -- )  here  /l allot  l!  ;
64\ : w->n  ( w -- l )  #48 << #48 >>a  ;
64\ : n->w  ( n -- w )  $ffff and ;
64\ : l->n  ( l -- n )  #32 << #32 >>a  ;
64\ : n->l  ( n -- w )  $ffffffff and ;
64\ alias x@ @
64\ alias x! !
64\ alias xa+ na+
64\ alias /x* cells

32\ #32 constant bits/cell
32\ : 64-bit 1 abort" Not a 64 bit forth" ; immediate
32\ : 32-bit ; immediate
32\ : 16-bit 1 abort" Not a 16 bit forth" ; immediate
32\ alias l, ,         ( l -- )
32\ : w->n  ( w -- l )  #16 << #16 >>a  ;
32\ : n->w  ( n -- w )  $ffff and ;
32\ : l->n ; immediate ( l -- n )
32\ : n->l ; immediate ( n -- l )

16\ #16 constant bits/cell
16\ : 16-bit ; immediate
16\ : 32-bit 1 abort" Not a 32 bit forth" ; immediate
16\ : l, , ,  ;
16\ : w->n ; immediate
16\ : n->w ; immediate
16\ : n->l  ( w -- l )  dup 0<  ;
16\ alias l->n drop
decimal

: s>d  ( n -- d )  dup 0<  ;
: u>d  ( u -- d )  0  ;

alias ca+ +  ( adr1 n -- adr2 )
: wa+  ( adr1 n -- adr2 )  /w* +  ;
: la+  ( adr1 n -- adr2 )  /l* +  ;

: w,  ( w -- )  here /w allot w!  ;
: <w@  ( adr -- signed.w )  w@ w->n  ;

: <l@  ( adr -- signed.l )  l@ l->n  ;

alias is to

nuser hld
: hold  ( char -- )  -1 hld +!   hld @ c!  ;
: <#    ( -- )  pad  hld  !  ;
: #>  ( d# -- adr len )  2drop  hld  @  pad  over  -  ;
: sign  ( d# n1 -- d# )  0< if  [char] -  hold  then  ;
: mu/mod  (s d# n1 -- rem d#quot )
   >r  0  r@  um/mod  r>  swap  >r  um/mod  r>
;
: u*  ( u1 u2 -- u3 )  um* drop  ;
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
\ 16\ : l.  ( l -- )  tuck labs  <# #s nlswap sign #> type space  ;
\ 16\ : ul.  ( l -- )  <# #s #> type space  ;
\ 32\ alias l. .         ( l -- )
\ 64\ alias l. .         ( l -- )
: (.s  ( -- )  depth 0 ?do  depth i - 1- pick .  loop  ;
: .s  ( -- )  ?stack  depth  if  (.s  else  ." Empty "  then  ;
: showstack  ( -- )  ['] (.s to status  ;
: noshowstack  ( -- )  ['] noop to status  ;

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

: vocabulary-noname  ( -- )
   vocabulary-cf                         ( )
   here body>    #user @                 ( my-acf user# )
   \ This is wasteful - should be /token * - but it keeps #user cell aligned
   #threads cells   ,unum                ( my-acf user# )
   up@ +                                 ( my-acf ua-adr )
   #threads 0  do  dup !null-token  ta1+  loop  drop   ( my-acf )
   voc-link link@ link,  voc-link link!
;
: $vocabulary  ( name$ -- )  $header vocabulary-noname  ;
: vocabulary  \ name  ( -- )
   safe-parse-word $vocabulary
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
      context i ta+  !null-token
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
   context #vocs 2- /token * +  !null-token
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

\ If the dictionary is split into ROM and RAM segments, the RAM could
\ be above the ROM, so comparing xts directly will not work.

\ Instead, we compare compilation tokens, which always increase as new
\ words are added.

: trim  ( fadr voc-adr -- )
   #threads 0  do          ( fadr thread-adr )
      2dup  begin          ( fadr thread-adr  fadr link-adr )
         link@             ( fadr thread-adr  fadr word-adr )
         over xt>ct        ( fadr thread-adr  fadr word-adr  fadr-ct )
         over xt>ct  u<=   ( fadr thread-adr  fadr word-adr  flag )
      while                ( fadr thread-adr  fadr word-adr )
         >link             ( fadr thread-adr  fadr link-adr )
      repeat               ( fadr thread-adr  fadr link' )
      nip over link!       ( fadr thread-adr )
      /link +              ( fadr thread-adr' )
   loop                    ( fadr thread-adr' )
   2drop                   ( )
;
\ It is a bad idea to do a forget that will result in the forgetting of
\ vocabularies that are presently in the search order.

: (forget   ( acf -- )
   >header
   \ first forget any vocabularies defined since the word to forget

   dup voc-link
   begin   link@  over xt>ct  over xt>ct u>=  until   ( adr voc-link-adr )
   dup voc-link link! nip              ( adr voc-link-adr )

   \ now, for all remaining vocabularies, forget words defined
   \ since the word to forget )
   begin
      dup origin  <>  ( any more vocabularies? )
   while
      2dup  >threads  ( adr voc-link-adr adr voc-threads-adr )
      trim            ( adr voc-link-adr )
      >voc-link link@ ( adr new-voc-link-adr )
   repeat
   drop   dp!
;
: forget   ( -- )
   safe-parse-word current token@ search-wordlist
   0= abort" Can't find word to forget"
   (forget
;

only forth also definitions
: ?comp  ( -- )  state @  0= abort" Compilation Only "  ;
: ?exec  ( -- )  state @     abort" Execution Only "  ;
: ?pairs  ( -- )  - abort" Conditionals not paired "  ;

64\ : /n*  ( n1 -- n2 )  3 <<  ;
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

\ alias " s"
\ fload stresc.fth

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
   ?dup  if
      dup -2 =  if
         drop .abort
      else
         dup -1 =  if  drop ." Aborted"  else  ." Error " .d  then
      then
      cr
   then
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

: alloc-mem  ( len -- adr )  allocate throw  ;
: free-mem  ( adr len -- adr )  drop free throw  ;

alias purpose: \
alias headerless noop
alias headers noop
: upc  ( char -- char' )  dup 'a' 'z' between  if  $20 invert and  then  ;
alias #-buf pad

warning off
: fl
   parse-word 2dup             ( adr len )
   ['] included catch ?dup if  ( adr len x x error-code )
      nip nip                  ( adr len error-code )
      dup -11 =  if            ( adr len error-code )
         ." Can't open file " -rot type cr  ( error-code )
      then                     ( [ adr len ] error-code )
      throw
   then                        ( adr len )
   2drop
;
alias fload fl
warning on
