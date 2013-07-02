purpose: Start OFW on a main CPU

: ofw-up?  ( -- flag )  h# 190 lcd@  0<>  ;
: ?ofw-up  ( -- )
   d# 80 0 do
      ofw-up?  if  leave  then
      ?visible
      d# 100 ms
   loop

   \ Check to see if OFW took over the display
   ofw-up?  0=  if
      show-fb
      ." CForth says: OFW seems not to have booted all the way" cr
   then
;

: cforth-wait  ( -- )
   begin  wfi  activate-cforth?  until
   ." Resuming CForth on Security Processor, second UART" cr
   1 'one-uart !
;
: stall-cforth  ( -- )
   ?ofw-up
   'one-uart @  0=  if
      wfi-loop
      ." CForth: wfi-loop returned unexpectedly" cr
\     d# 4000 ms  cforth-wait
   then
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

: load-ofw  ( -- )
   init-spi .spi-id
   " reset" drop-in-location abort" Can't find reset dropin"  ( adr len )
   swap h# 20000 - dup to reset-offset      ( len offset )
   +                                        ( size-to-read )
   'compressed swap h# 2.0000 spi-read      ( )
;

: ofw  ( -- )
   dram-on?  0=  if  late-init  then
   blank-display-lowres
   h# 00 puthex  ?visible
   load-ofw
   h# 01 puthex  ?visible
   [ifdef] enable-ps2  enable-ps2  [then]
   ofw-go
   stall-cforth
;

: dbg  ( -- )  
   ." CForth stays active on second serial port" cr
   'one-uart on
;

0 [if]
\ Start of alternative boot code.  This is used only for recovery/debugging purposes.
\ It is slower than the normal boot code.  This code performs the decompression
\ of the OFW image on the SP, whereas the normal boot code lets the PJ4 processor
\ do the decompression.

h# 1fa0.0000 constant ofw-pa

: ofw-go-slow  ( -- )
   h# ea000000 h# 0 pj4-l!  \ b 8
   ofw-pa      h# 4 pj4-l!  \ OFW load address
   h# e51f000c h# 8 pj4-l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c pj4-l!  \ mov pc,r0

   ." releasing" cr
   0 h# 050020 io!  \ Release reset for PJ4
;

: load-ofw-slow  ( -- )
   init-spi
   .spi-id

   ofw-pa pj4>sp-adr " firmware" load-drop-in
;
: ofw-slow  ( -- )
\   0 h# e0000 h# 20000 spi-read
\   spi-go
   activate-cforth?  if  ." Skipping OFW" cr  exit  then

   blank-display-lowres
   load-ofw-slow
   ofw-go-slow
[ifdef] enable-ps2
   enable-ps2
[then]
   cforth-wait
\   begin wfi again
;

\ Run OFW on the security processor
\ This won't work on OFW builds that use virtual != physical addressing,
\ because the SP has no MMU.
: sp-ofw  ( -- )  load-ofw-slow  " " drop  ofw-pa pj4>sp-adr acall  ;

\ End of alternative boot code.
[then]
