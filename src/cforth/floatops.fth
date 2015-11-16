\ Floating point words.

: set-precision  ( n -- )  #places !  ;
: precision  ( -- n )  #places @  ;
3 set-precision

: floatop:  \ name  ( op# -- )
   create ,   does> @ floatop
;
: fintop:  \ name  ( op# -- )
   create ,   does> @ fintop
;

decimal

0 floatop: f+
1 floatop: f-
2 floatop: f*
3 floatop: f/
4 floatop: fmod
5 floatop: fnegate
6 floatop: fsin
7 floatop: fcos
8 floatop: ftan
9 floatop: flog
10 floatop: fln
11 floatop: fatan
12 floatop: fatan2
13 floatop: fasin
14 floatop: facos
15 floatop: fceil
16 floatop: fcosh
17 floatop: fsinh
18 floatop: ftanh
19 floatop: fsqrt
20 floatop: fexp
21 floatop: fabs
22 floatop: floor
23 floatop: f**
24 floatop: fdup
25 floatop: fdrop
26 floatop: fover
27 floatop: fswap
28 floatop: frot
29 floatop: f-rot
30 floatop: fround
31 floatop: facosh
32 floatop: fasinh
33 floatop: fatanh
34 floatop: fexpm1
35 floatop: flnp1

0 fintop: fp0
1 fintop: fdepth
2 fintop: fp!
3 fintop: f!
4 fintop: f@
5 fintop: int
6 fintop: float
7 fintop: fpop
8 fintop: fpush
9 fintop: fstring
10 fintop: estring
11 fintop: f=
12 fintop: f<>
13 fintop: f<
14 fintop: f>
15 fintop: f<=
16 fintop: f>=
17 fintop: f0=
18 fintop: f0<>
19 fintop: f0<
20 fintop: f0>
21 fintop: f0<=
22 fintop: f0>=
23 fintop: fpick
24 fintop: fnumber?
25 fintop: fnumber 
26 fintop: fscale
27 fintop: represent
28 fintop: f~
29 fintop: sf!
30 fintop: sf@

\ Backwards compatibility
alias ffloor floor
alias faln   fexp
alias places set-precision
alias fix    fround

64\ d# 64 constant cell-bits
32\ d# 32 constant cell-bits
16\ d# 16 constant cell-bits

: f>d  ( real -- d )
   fdup f0<  >r r@  if  fabs  then
   floor fdup  cell-bits negate fscale    ( r.n r.high )
   fswap fover floor cell-bits fscale f-  ( r.high r.low )
   int  int
   r>  if  dnegate  then
;
: d>f  ( d -- real )
   dup 0<  if
      dnegate
      float cell-bits fscale  float f+
      fnegate
   else
      float cell-bits fscale  float f+
   then
;

: fsincos  ( real -- sin cos )  fdup fsin fswap fcos  ;

: fclear  ( -- )  fp0 fp!  ;
: f.  ( real -- )  fstring type  space  ;
: fs.  ( real -- )  estring type  space  ;
alias e. fs.
: f.s  ( -- )
   fdepth  0<  dup  if  fclear  then  abort" Floating Point Stack Underflow"
   fdepth  0  ?do  fdepth i - 1- fpick f.  loop
;
: fliteral  ( real -- )
   state @  if  compile (fliteral) fpop  l, l,  then
; immediate
: f#  \ string  ( -- real )
   parse-word fnumber abort" Not a real number"
   [compile] fliteral
; immediate
: >float  ( adr len -- flag )  ( f: -- r | )
   fnumber  if  fdrop false  else  true  then
;
: $fnumber?  ( adr len -- flag )
   2dup fnumber?  if
      fnumber drop  2drop [compile] fliteral  r> drop exit
   then
   $number?
;

patch $fnumber? $number? compile-word

/l 2* constant /f
/f constant #falign	\ This is safe, but perhaps pessimistic.

: floats  ( #floats -- #bytes )  /f *  ;
: float+  ( adr1 -- adr2 )       /f +  ;

: faligned  ( n1 -- n2 )  #falign 1- +  #falign 1- not and  ;
: falign    ( -- )  here faligned  here -  allot  ;

: f,  ( real -- )  here /f allot f!  ;

: fvariable  \ name  ( -- )
   create  0E0 f,
;
: fconstant  \ name  ( real -- )
   create  f,  does> f@
;

: fvalue  \ name  ( real -- )
   create              ( real )
   #user @ /f ,unum    ( real user# )
   up@ + f!            ( )
   does> >user f@
;
0f fvalue isfvalue

warning @ warning off
: (to)  ( n xt -- data-adr )
   dup cf@  ['] isfvalue cf@ =  if  ( real xt )
      >body >user f!
      exit
   then
   (to)
;
: to  ( "name" [ val ] -- )	\ val is present only in interpret state
   state @  if   postpone ['] postpone (to)  else  ' (to)  then
; immediate
warning !

: falog  ( real1 -- real2 )  1E1 fswap f**  ;

: fmax  ( real1 real2 -- real3 )  fover fover  f<  if  fswap  then  fdrop  ;

: fmin  ( real1 real2 -- real3 )  fover fover  f>  if  fswap  then  fdrop  ;


alias df!        f!
alias df@        f@
alias dfalign    falign
alias dfaligned  faligned
alias dfloat+    float+
alias dfloats    floats

/l constant /sf
/sf constant #sfalign	\ This is safe, but perhaps pessimistic.

: sf,  ( f -- )  here /sf allot  sf!  ;

: sfloats  ( #floats -- #bytes )  /sf *  ;
: sfloat+  ( adr1 -- adr2 )       /sf +  ;

: sfaligned  ( n1 -- n2 )  #sfalign 1- +  #sfalign 1- not and  ;
: sfalign    ( -- )  here sfaligned  here -  allot  ;

: f#buf  ( -- adr )  pad d# 32 -  ;
: fe.  ( r -- )
   fdup  f0=  if  fdrop  ." 0.0E0 "  exit  then
   base @ >r decimal
   f#buf  precision represent  if          ( exp neg? )
      f#buf precision +  3  [char] 0 fill  ( exp neg? ) \ In case precision < 3
      if  ." -"  then                      ( exp )
      dup s>d  3  fm/mod drop              ( exp exp-mod-3 )
      ?dup 0=  if  3  then                 ( exp pre-decimal )
      f#buf over type ." ."                ( exp pre-decimal )
      precision over -  0 max              ( exp pre post )
      f#buf 2 pick +  swap type            ( exp pre )
      ." E" - .                            ( )
   else                                    ( x x )
      2drop  f#buf  precision  type        ( )
   then
   r> base !
;

: f>r  ( f: real -- r: real )  r>  fpop 2>r  >r  ;
: fr>  ( r: real -- f: real )  r> 2r> fpush  >r  ;
: fr@  ( r: real -- f: real r: real )  r>  2r@ fpush  >r  ;
