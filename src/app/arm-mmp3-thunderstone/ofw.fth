
: cforth-wait  ( -- )
   begin  wfi  activate-cforth?  until
;

\ The SP and PJ4's address maps for memory differ, apparently for the purpose
\ of accomodating the "Tightly Coupled Memory" (TCM).
\ DDR/PJ-addr   SP-addr
\ 0x0xxx.xxxx   0x1xxx.xxxx
\ 0x1xxx.xxxx   0x2xxx.xxxx
\ ...
\ 0x6xxx.xxxx   0x7xxx.xxxx
\ 0x7xxx.xxxx   inaccessible?
\
\ When TCM is on,  SP-addr 0x0xxx.xxxx goes to TCM
\ When TCM is off, SP-addr 0x0xxx.xxxx goes to main memory 0x0xxx.xxxx (alias of 0x1xxx.xxxx)

: pj4>sp-adr  ( pj4-adr -- sp-adr )  h# 1000.0000 +  ;
: pj4-l!  ( l pj4-adr -- )  pj4>sp-adr l!  ;

h# 0900.0000 constant 'compressed
0 value reset-offset

: 'compressed-sp  ( -- adr )  'compressed pj4>sp-adr  ;
: di>body  ( adr -- adr' )  h# 20 +  ;
: next-di  ( adr -- adr' )  dup 4 + be-l@ 4 round-up  di>body  +  ;
: obmd?  ( adr -- flag )  l@ h# 444d424f =  ;
: mem-find-reset  ( -- )
   'compressed-sp dup obmd? 0=  if  ( adr )
      h# 20000 +  dup obmd? 0=  abort" Can't find dropins"
   then                             ( adr )

   next-di next-di di>body 'compressed-sp - to reset-offset
;

: ofw-go  ( -- )
   reset-offset 0=  if  mem-find-reset  then

   h# e1a00000 h#  0 pj4-l!  \ nop
   h# e1a00000 h#  4 pj4-l!  \ nop
   h# e1a00000 h#  8 pj4-l!  \ nop
   h# e1a00000 h#  c pj4-l!  \ nop

   h# ea000000 h# 10 pj4-l!  \ b 18
   'compressed reset-offset +  h# 14 pj4-l!  \ reset vector address
   h# e51f000c h# 18 pj4-l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# 1c pj4-l!  \ mov pc,r0

   ." releasing" cr
   release-main-cpu
;

\ h# 10.0000 constant /rom
h# 06.0000 constant /rom
: load-ofw  ( -- )
   ." Send binary ..."
   'compressed-sp  /rom  bounds  ?do
      key i c!
   loop
   cr
;

h# 1fa0.0000 constant ofw-pa

: ofw-go-slow  ( -- )
   h# ea000000 h# 0 pj4-l!  \ b 8
   ofw-pa      h# 4 pj4-l!  \ OFW load address
   h# e51f000c h# 8 pj4-l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c pj4-l!  \ mov pc,r0

   ." releasing" cr
   0 h# 050020 io!  \ Release reset for PJ4
;
