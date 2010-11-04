\ Load file for application-specific Forth extensions

alias purpose: \

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth

fl hwaddrs.fth

defer ms  defer get-msecs
fl timer.fth
\ fl timer2.fth
fl gpio.fth
fl mfpr.fth
fl boardgpio.fth

: alloc-mem  drop 0  ;  : free-mem 2drop  ;
\ fl flashif.fth
\ fl spiif.fth
\ fl spiflash.fth
\ fl sspspi.fth
fl clockset.fth
fl initdram.fth
fl fuse.fth

: short-delay ;

0 ccall: spi-send        { a.adr i.len -- }
1 ccall: spi-send-only   { a.adr i.len -- }
2 ccall: spi-read-slow   { a.adr i.len i.offset -- }
3 ccall: spi-read-status { -- i.status }
4 ccall: spi-send-page   { a.adr i.len i.offset -- }
5 ccall: spi-read        { a.adr i.len i.offset -- }
6 ccall: lfill           { a.adr i.len i.value -- }
7 ccall: lcheck          { a.adr i.len i.value -- i.erraddr }
8 ccall: inc-fill          { a.adr i.len -- }
9 ccall: inc-check         { a.adr i.len -- i.erraddr }
d# 10 ccall: random-fill   { a.adr i.len -- }
d# 11 ccall: random-check  { a.adr i.len -- i.erraddr }
d# 12 ccall: (inflate)     { a.compadr a.expadr i.nohdr a.workadr -- i.expsize }
d# 13 ccall: control@      { -- i.value }
d# 14 ccall: control!      { i.value -- }
d# 15 ccall: tcm-size@     { -- i.value }
d# 16 ccall: inflate-adr   { -- a.value }

fl hackspi.fth
fl dropin.fth

0 value memtest-start
h# 1000.0000 value memtest-length
: memtest  ( adr len -- )
   ." Random pattern test from " memtest-start u.
   ." to " memtest-start memtest-length + 1- u. cr
   ." Filling ..." cr
   memtest-start memtest-length random-fill
   ." Checking ..." cr
   memtest-start memtest-length random-check
   dup -1 =  if
      drop
      ." Good" cr
   else
      ." ERROR at address " u. cr
   then
;

: cforth-wait  ( -- )
   begin  d# 50 ms  d# 20 gpio-pin@ 0=  until  \ Wait until KEY_5 GPIO pressed
   ." Resuming CForth on Security Processor" cr
;
: ofw-go  ( -- )
   ." releasing" cr
   h# ea000000 h# 0 l!  \ b 8
   h# 1fa00000 h# 4 l!  \ OFW load address
   h# e51f000c h# 8 l!  \ ldr r0,[pc,#-0xc]
   h# e1a0f000 h# c l!  \ mov pc,r0

   d# 20 ms
   0 h# d4050020 l!  \ Release reset for PJ4
;

: ofw-old  ( -- )
\   0 h# e0000 h# 20000 spi-read
\   spi-go
   d# 20 gpio-pin@  0=  if  ." Skipping OFW" cr  exit  then

   init-spi
   .spi-id

   h# 2fa0.0000 h# c0000 h# 20000 spi-read

   ofw-go
   cforth-wait
;

: ofw  ( -- )
\   0 h# e0000 h# 20000 spi-read
\   spi-go
   d# 20 gpio-pin@  0=  if  ." Skipping OFW" cr  exit  then

   init-spi
   .spi-id

   h# 2fa0.0000 " firmware" load-drop-in

   ofw-go
   cforth-wait
;

: init
   init-timers
   set-gpio-directions
   init-mfprs
   clk-fast
   init-dram
   fix-fuses
   init-spi
   ofw
;

0 [if]
: t
   0 h# 0 l!
\  h# 2000.0000 dup l!
   h# 1000.0000 dup l!
   h#  800.0000 dup l!
   h#  400.0000 dup l!
   h#  200.0000 dup l!
   0 l@ .
;

: what  init-dram  t  ;
[then]

\ Run this at startup
: app  init  hex quit  ;
\ " ../objs/tester" $chdir drop

" app.dic" save
