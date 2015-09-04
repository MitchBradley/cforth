\ Fix input stream
\ Fix multiplication and division  */mod um/mod fm/mod m* sm/mod um*
\ Write >NUMBER
\ Control flow
\ upper case
\ Search order
\ Marker
\ Need CONVERT  (obsolescent)
\ missing: get-date
\ MS
\ PARSE
\ REFILL
\ START:

: invert   ( n -- ~n )  not  ;
: compile,  ( acf -- )  token,  ;
: postpone  \ name  ( -- )
   ?comp
   bl word find   ( pstr false | acf +-1 )
   ?dup  if
      drop where  compile lose
   else
      0<  if  compile (compile)  then  compile,
   then
; immediate
: accept  ( c-addr +n1 -- +n2 )
   span @ >r  expect span @  r> span !
;
variable blk  0 blk !
: cell+  ( addr1 -- addr2 )  na1+  ;
: cells  ( n1 -- n2 )   /n*  ;
: char  \ word  ( -- n )
   bl word 1+ c@
;
: [char]  \ word
   char [compile] literal
; immediate
: char+  ( addr1 -- addr2 )  ca1+  ;
: chars  ( n1 -- n2 )  /c*  ;
d# 32 buffer: namebuf
: search-wordlist  ( c-addr u wid -- 0 | acf +-1 )
   >r namebuf pack vfind  dup 0=  if  nip  then
;
vocabulary environment  environment definitions

#align constant /align
1 chars constant /char
td 255 constant /counted-string
\32  h# 20000
\16  d# 45000
constant /data-space
d# 100 constant /hold
: /pad  origin /data-space +  pad -  ;
d# 132 constant /tib
8 constant address-unit-bits
\ true constant block
\ false constant block-ext
true constant core
true constant core-ext
true constant double
true constant double-ext
true constant file
true constant file-ext
true constant floating
true constant floating-ext
d# 20 constant floating-stack
true constant full
true constant locals
true constant locals-ext ???
?? constant max-float
\32 h# 7fffffff
\16 h#     7fff
constant max-n
\32 h# ffffffff
\16 h#     ffff
constant max-u
max-u max-n constant max-d
max-u max-u constant max-ud
true constant memory-alloc
false constant memory-alloc-ext ???
d# 100 constant return-stack-cells
true constant search-order
true constant search-order-ext
d# 100 constant stack-cells
true constant string
true constant string-ext
?? constant wordlists

forth definitions

: environment?  ( c-addr u -- false | value true )
   ['] environment?  search-wordlist  if  execute true  else  false  then
;


: evaluate  ( addr len -- )  eval  ;   ???

: s"  \ string"  ( -- addr len )
   [compile] "
; immediate

: unloop  ( -- )
   r>  r> drop r> drop  r> drop  >r
;

: 2>r  ( w1 w2 -- )  r> -rot  swap >r >r  >r  ;
: 2r>  ( -- w1 w2 )  r>  r> r> swap  rot >r  ;
: 2r@  ( -- w1 w2 )  r>  r> r> 2dup >r >r swap  rot >r  ;

missing: at-xy

: blank  ( c-addr u -- )  bl fill  ;
: c"  \ string   ( -- pstr )
   [compile] p"
; immediate
\needs page : page  ( -- )  control L emit  ;

nameless
: limit  ( -- adr )
   origin  [ also environment ]  /data-space  [ previous ]  +
;
: unused  ( -- n )  limit here -  ;
: value  \ name  ( n -- )
   constant
;
: (to)  ( n acf -- )  >body !  ;
: to  \ name ( n -- )
   state @  if
      compile (')  ' compile,  compile (to)
   else
      ' >body !
   then
; immediate

: start:  ( -- acf )
   align here  d# 301 ,
;
