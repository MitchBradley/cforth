\ Mostly-trivial definitions for compatibility with the OFW Forth system

\needs purpose: alias purpose: \
\needs copyright: alias copyright: \

: init ;
: 5drop  ( x x x x x -- )  2drop 3drop  ;
\needs 3dup  : 3dup  ( -- )  2 pick 2 pick 2 pick  ;


: (confirmed?)  ( adr len -- char )
   type  ."  [y/n]? "  key dup emit cr  upc
;
\ Default value is yes
: confirmed?  ( adr len -- yes? )  (confirmed?) [char] N  <>  ;
\ Default value is no
: confirmedn?  ( adr len -- yes? )  (confirmed?) [char] Y  =  ;

defer edit-file  ( adr maxlen -- actual-len )  : no-edit  true abort" edit-file is not implemented"  ;
defer ?permitted
defer deny-history?
: beep  ( -- )   7 emit  ;
: 8*  ( n1 -- n2 )  3 lshift  ;
: third  ( a b c -- a b c a )  2 pick  ;
: cstrlen  ( adr -- len )  cscount drop  ;

: umin  ( u1 u2 -- u3 )  2dup u<  if  drop  else  nip  then  ;

: ($callback)  ( name$ -- err? )  2drop true  ;

#260 buffer: string2

: hold$  ( adr len -- )
   dup  if
      1- bounds swap  do  i c@ hold  -1 +loop
   else
      2drop
   then
;

: bskip  ( adr len byte -- residue )
   -rot 2dup + >r       ( byte adr len  r: endadr )
   bounds ?do           ( byte )
      dup i c@ <>  if   ( byte )
         drop  i unloop r> swap -  exit  ( -- residue )
      then              ( byte )
   loop                 ( byte )
   r> 2drop  0          ( residue )
;
: (.2)  (s u -- a len )  <# u# u# u#>   ;
: (.4)  (s u -- a len )  <# u# u# u# u# u#>   ;

4 constant /fd
: ". count type  ;

defer mac-address

1 constant 1
2 constant 2
3 constant 3
4 constant 4
5 constant 5
6 constant 6
7 constant 7
8 constant 8
9 constant 9

8 constant bs
7 constant bell

variable span
: expect  ( adr len -- )  accept span !  ;

: u/mod  ( u div -- req quot )  u>d um/mod  ;

alias do-is (to)
: cpeek  ( adr -- false | value true )  c@ true  ;
: wpeek  ( adr -- false | value true )  w@ true  ;
: lpeek  ( adr -- false | value true )  l@ true  ;

: cpoke  ( b adr -- okay? )  c! true  ;
: wpoke  ( w adr -- okay? )  w! true  ;
: lpoke  ( l adr -- okay? )  l! true  ;

\needs lex fl ../lib/lex.fth

\ : wbflip  ( w -- w )  wbsplit swap bwjoin  ;
\ : lwflip  ( l -- l )  lwsplit swap wljoin  ;
\ \needs lbflip : lbflip  ( l -- l )  lbsplit swap 2swap swap bljoin  ;

\ : lbflips  ( adr len -- )   bounds  ?do  i l@ lbflip i l!  /l +loop  ;
\ : wbflips  ( adr len -- )   bounds  ?do  i w@ wbflip i w!  /w +loop  ;
\ : lwflips  ( adr len -- )   bounds  ?do  i l@ lwflip i l!  /l +loop  ;

#260 constant /stringbuf
/stringbuf 2* buffer: stringbuf
0 value "temp
: switch-string  ( -- )
   stringbuf  dup "temp =  if  /stringbuf +  then  is "temp
;
\ XXX need to init "temp to stringbuf

\ alias config-flag value

alias \tagvoc noop immediate
alias \nottagvoc \ immediate
alias #acf-align #align
alias note-string noop  immediate

alias start-module noop
alias end-module noop

: nowarn(  ( -- warning )  warning @  warning off  ;
: )nowarn  ( warning -- )  warning !  ;
: $save  ( adr1 len1 adr2 -- adr2 len1 )  pack count  ;
: $cat  ( adr len  pstr -- )  \ Append adr len to the end of pstr
   >r  r@ count +   ( adr len end-adr )  ( r: pstr )
   swap dup >r      ( adr endadr len )  ( r: pstr len )
   cmove  r> r>     ( len pstr )
   dup c@ rot + over c!  ( pstr )
   count +  0 swap c!     \ Always keep a null terminator at the end
;

: lcc  ( char -- char' )  dup 'A' 'Z' between  if  $20 or  then  ;
: lower  ( adr len -- )  bounds  ?do i dup c@ lcc swap c!  loop  ;
: ucc  ( char -- char' )  dup 'a' 'z' between  if  $20 invert and  then ;
: upper  ( adr len -- )  bounds  ?do i dup c@ ucc swap c!  loop  ;

: >voc  ( n -- adr )  context swap ta+  ;
#vocs /token * constant /context
: context-bounds  ( -- end start )  context /context bounds  ;
: clear-context  ( -- )
   context-bounds  ?do  i !null-token  /token +loop
;
: get-order  ( -- vocn .. voc1 n )
   0  0  #vocs 1-  do
      i >voc token@ non-null?  if  swap 1+  then
   -1 +loop
;
: set-order  ( vocn .. voc1 n -- )
   dup #vocs >  abort" Too many vocabularies in requested search order"
   clear-context
   0  ?do  i >voc token!  loop
;
: get-current  ( -- )  current token@  ;
: set-current  ( -- )  current token!  ;

$102 buffer: cstrbuf
\ Convert an unpacked string to a C string
: $cstr  ( adr len -- c-string-adr )
   \ If, as is usually the case, there is already a null byte at the end,
   \ we can avoid the copy.
   2dup +  c@  0=  if  drop exit  then
   >r   cstrbuf r@  cmove  0 cstrbuf r> + c!  cstrbuf
;
: (.8)  (s u -- a len )  <# u# u# u# u# u# u# u# u# u#>   ;
alias link> ta1+


: find-voc ( xt - voc-node|false )
   >r voc-link  			( voc-node )
   begin
      another-link? false = if          ( - | voc-node )
         false true			( false loop-flag )
      else				( voc-node )
	 dup voc> 			( voc-node voc-xt )
	 swap >voc-link swap            ( voc-node' voc-xt )
         r@ execute	     		( voc-node' flag )
      then				( voc-node'|false loop-flag )
   until				( voc-node' )
   r> drop				( voc-node|false )
;

: remove-word  ( new-alf voc-acf -- )
   >threads                                   ( new-alf prev-link )
   swap link> swap link>                      ( new-acf prev-link )
   begin                                      ( acf prev-link )
      >link
      2dup link@ =  if                        ( acf prev-link )
         swap >link link@ swap link!  exit    (  )
      then                                    ( acf prev-link )
      another-link? 0=                  ( acf [ next-link ] end? )
   until
   drop
;
: 2nip  2swap 2drop  ;
: $vfind  ( $ voc -- $ false | xt +-1 )
   >r 2dup                ( $ $ )
   r> search-wordlist     ( $ [ false | xt +-1 ] )
   dup  if  2nip  then    ( $ false | xt +-1 )
;
: $find-word  ( $ voc -- $ false | xt +-1 )
   >r 2dup                ( $ $ )
   r> (search-wordlist)   ( $ [ false | xt +-1 ] )
   dup  if  2nip  then    ( $ false | xt +-1 )
;

alias transient noop
alias resident noop
0 value my-self
\needs struct fl ../lib/struct.fth
\needs $=  : $=  ( $1 $2 -- )  compare 0=  ;
alias headerless? false
alias ascii [char]
alias partial-headers noop
alias external headers
create cforth
\needs standalone?  false value standalone?
alias eval evaluate
defer minimum-search-order
#10 constant newline
: 4drop 2drop 2drop ;
: recursive reveal ; immediate
: (align)  ( size granularity -- )
   1-  begin  dup here and  while  0 c,  repeat  drop
;
: round-down  ( adr granularity -- adr' )  1- invert and  ;

fl ${BP}/forth/kernel/splits.fth
fl ${BP}/forth/lib/split.fth
fl ${BP}/forth/kernel/endian.fth
32\ alias unaligned-! unaligned-l!
64\ alias unaligned-! !
64\ alias rx@ @
64\ alias rx! !
64\ alias x, ,
64\ alias xa1+ cell+

: -leading  ( adr len -- adr' len' )  
   begin  dup  while
      over c@ bl  <>  if  exit  then
      1 /string
   repeat
;

: strip-blanks  ( adr len -- adr' len' )  -leading  -trailing  ;
: optional-arg$  ( -- adr len )  0 parse  strip-blanks  ;

\ : relink-voc  ( voc -- )  drop  ;  \ CForth doesn't support transient so nothing to do

: place-cstr  ( adr len cstr-adr -- cstr-adr )
   >r  tuck r@ swap cmove  ( len ) r@ +  0 swap c!  r>
;

: substring?  ( $1 $2 -- flag )  2swap search nip nip  ;

\ OFW another? returns nfa while CForth returns xt
: >name  ( xt -- xt )  ;
: name>string  ( xt -- adr len )  >name$  ;
: name>  ( xt -- xt )  ;
alias n>link >link
alias null origin

\needs indirect-call?  defer indirect-call?
: (indirect-call?)  ( xt -- flag )  ['] catch =  ;
' (indirect-call?) is indirect-call?

alias tuser nuser
alias (interactive? interactive?
nuser prior
#32 buffer: 'word
alias .id .name

\ Fix these
alias include-buffer evaluate
