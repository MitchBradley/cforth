\ VIA video register dump

hex

: reset-attr-addr  ( -- )  h# 3da ( input-status1 )  pc@ drop  ;

: video-mode!  ( b -- )  reset-attr-addr  h# 03c0 pc!  ;
: attr!  ( b index -- )  reset-attr-addr h# 03c0 pc!  h# 03c0 pc!  ;
: attr@  ( index -- b )
   reset-attr-addr  h# 03c0 pc!  h# 03c1 pc@  reset-attr-addr
;
: seq@  ( index -- value )  h# 3c4 pc!  h# 3c5 pc@  ;
: grf@  ( index -- value )  h# 3ce pc!  h# 3cf pc@  ;
: crt@  ( index -- value )  h# 3d4 pc!  h# 3d5 pc@  ;
: seq.  ( adr len -- )  bounds  ?do  i c@ seq@ 3 u.r  loop  ;
: .regular
   ." ATR " h# 15 0 do i attr@ 3 u.r loop  cr
   h# 20 video-mode!
   ." SEQ " 5 0 do i seq@ 3 u.r loop  cr
   ." GRF " 9 0 do i grf@ 3 u.r loop  cr
."       0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f" cr
   ." C00 " h# 10     0 do i crt@ 3 u.r loop  cr
   ." C10 " h# 19 h# 10 do i crt@ 3 u.r loop  cr
;
: .sextended
   ." S10 " h# 1f h# 10 do i seq@ 3 u.r loop cr
   ." S20 " h# 2f h# 20 do i seq@ 3 u.r loop cr
   ." S30 " h# 40 h# 30 do i seq@ 3 u.r loop cr
   ." S40 " h# 50 h# 40 do i seq@ 3 u.r loop cr
   ." S50 " h# 60 h# 50 do i seq@ 3 u.r loop cr
   ." S60 " h# 70 h# 60 do i seq@ 3 u.r loop cr
   ." S70 " h# 80 h# 70 do i seq@ 3 u.r loop cr
   ." SA8 " h# b0 h# a8 do i seq@ 3 u.r loop cr
   ." G20 " h# 23 h# 20 do i grf@ 3 u.r loop cr
;
: .cextended
   ." C30 " h# 40 h# 30 do i crt@ 3 u.r loop cr
   ." C40 " h# 49 h# 40 do i crt@ 3 u.r loop cr
   ." C50 " h# 60 h# 50 do i crt@ 3 u.r loop cr
   ." C60 " h# 70 h# 60 do i crt@ 3 u.r loop cr
   ." C70 " h# 80 h# 70 do i crt@ 3 u.r loop cr
   ." C80 " h# 90 h# 80 do i crt@ 3 u.r loop cr
   ." C90 " h# a0 h# 90 do i crt@ 3 u.r loop cr
   ." CA0 " h# b0 h# a0 do i crt@ 3 u.r loop cr
   ." CD0 " h# e0 h# d0 do i crt@ 3 u.r loop cr
   ." CE0 " h# f0 h# e0 do i crt@ 3 u.r loop cr
   ." CF0 " h# fd h# f0 do i crt@ 3 u.r loop cr
;
: .dpy  .regular .cextended .sextended  ;

\ b0 8b0 config-b@ -> 1   ( VGA in S.L.)
\ b2 8b2 config-b@ -> 40  ( 256 MB memory base 0)

: (.2)  <# u# u# u#>  ;
: (.4)  <# u# u# u# u# u#>  ;
: (.8)  <# u# u# u# u# u# u# u# u# u#>  ;

hex
0 value config-base
: cl.  dup (.2) type ." : " config-base + config-l@ (.8) type  cr ;
: cw.  dup (.2) type ." : " config-base + config-w@ (.4) type  cr ;
: cb.  dup (.2) type ." : " config-base + config-b@ (.2) type cr ;
: ch.  config-base h# 40 bounds do i config-l@ u. 4 +loop cr ;
: dump-d0f0
   0 to config-base
   ." == D0F0 Host Control ==" cr
   ch.
   4f cb. cr
   c0 cb. \ ." mem/io access ctl"
   c6 cb. \ ." legacy access ctl"
   c8 cl. \ ." GFX mem base 0 for S.L."
   cc cl. \ ." GFX mem base 1 for MMIO"
   d4 cb. \ ." MMIO/SL enable"
   e0 cb. \ ." GFX power state"
   fe cb. \ ." VGA no alias"
   cr
;
: dump-d0f1
   h# 100 to config-base
   ." == D0F1 Error Reporting ==" cr
   cr
;

0 [if]
D0F2

   50 51 52 53 54 55 56 57 59          5c 5d 5e 5f
   60 61    63 64    66    68 69 6a 6b 6c 6d 6e 6f
   70 71 72 73       76          7a
   90    92 93       96 97 98 99
   a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 aa ab ac ad ae af 
   b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 ba bb bc bd be
   c0 c1 c2 c3 c4 c5 c6 c7 c8 c9
   d0 d1 d2 d3 d4 d5 d6 d7 d8 d9
[then]

: dump-d0f2
   h# 200 to config-base
   ." == D0F2 Host Bus Control ==" cr
   ch.
   50 cb. \ ." Request phase control"
   51 cb. \ ." CPU Interface Control - Basic Option"
   52 cb. \ ." CPU Interface Control - Advanced Option"
   53 cb. \ ." Arbitration"
   54 cb. \ ." Misc ctl 1"
   55 cb. \ ." Misc ctl 2"
   56 cb. \ ." Write policy 1"
   57 cb. \ ." Calibration"
   59 cb. \ ." CPU Misc Ctl 1"
   5c cb. \ ." CPU Misc Ctl 2"
   5d cb. \ ." Write policy 2"
   5e cb. \ ." Bandwidth Timers"
   5f cb. \ ." CPU Misc Ctl 3"
   60 cb.
   61 cb.
   63 cb.
   64 cb.
   66 cb.
   68 cb.
   69 cb.
   6a cb.
   6b cb.
   6c cb.
   6d cb.
   6e cb.
   6f cb.
   70 cb.
   71 cb.
   72 cb.
   73 cb.
   76 cb.
   7a cb.
   90 cb.
   92 cb.
   93 cb.
   96 cb.
   97 cb.
   98 cb.
   99 cb.
   a0 cb.
   a1 cb.
   a2 cb.
   a3 cb.
   a4 cb.
   a5 cb.
   a6 cb.
   a7 cb.
   a8 cb.
   a9 cb.
   aa cb.
   ab cb.
   ac cb.
   ad cb.
   ae cb.
   af cb.
   b0 cb.
   b1 cb.
   b2 cb.
   b3 cb.
   b4 cb.
   b5 cb.
   b6 cb.
   b7 cb.
   b8 cb.
   b9 cb.
   ba cb.
   bb cb.
   bc cb.
   bd cb.
   be cb.
   c0 cb.
   c1 cb.
   c2 cb.
   c3 cb.
   c4 cb.
   c5 cb.
   c6 cb.
   c7 cb.
   c8 cb.
   c9 cb.
   d0 cb.
   d1 cb.
   d2 cb.
   d3 cb.
   d4 cb.
   d5 cb.
   d6 cb.
   d7 cb.
   d8 cb.
   d9 cb.
   cr
;

: dump-d0f3
   h# 300 to config-base
   ." == D0F3 DRAM Bus Control ==" cr
   ch.
   40 cb.
   41 cb.
   42 cb.
   43 cb.
   48 cb.
   49 cb.
   4a cb.
   4b cb.
   50 cw.
   52 cb.
   53 cb.
   55 cb.
   58 cb.
   59 cb.
   5a cb.
   5b cb.
   60 cb.
   61 cb.
   62 cb.
   63 cb.
   65 cb.
   66 cb.
   67 cb.
   68 cb.
   69 cb.
   6a cb.
   6b cb.
   6c cb.
   6d cb.
   6e cb.
   6f cb.
   70 cb.
   71 cb.
   74 cb.
   75 cb.
   76 cb.
   77 cb.
   78 cb.
   7b cb.
   7c cb.
   80 cb.
   81 cb.
   82 cb.
   83 cb.
   84 cb.
   85 cb.
   86 cb.
   88 cw.
\  8a cb.  \ RO
   8c cb.
   90 cb.
   91 cb.
   92 cb.
   93 cb.
   95 cb.
   96 cb.
   97 cb.
   98 cb.
   99 cb.
   9c cb.
   9e cb.
   9f cb.
   a0 cw.
   a2 cb.
   a3 cb.
   a4 cw.
   a6 cb.
   a7 cb.
   b3 cb.
   d0 cb.
\  d1 cb. \ RO
\  d2 cb. \ RO
   d3 cb.
   d4 cb.
   d5 cb.
   d6 cb.
   d7 cb.
   db cb.
   dc cb.
   dd cb.
   de cb.
   df cb.
   e0 cb.
   e1 cb.
   e2 cb.
   e3 cb.
   e4 cb.
   e5 cb.
   e6 cb.
   e7 cb.
   e8 cb.
   d9 cb.
   ec cb.
   ed cb.
   ee cb.
   ef cb.
   f0 cl.
   f8 cw.
   fb cb.
   fd cb.
   fe cb.
   ff cb.
   cr
;

: dump-d0f4
   h# 400 to config-base
   ." == D0F4 Power Management" cr
   ch.
   84 cb.
   85 cb.
   89 cb.
   8b cb.
   8d cb.
   8e cb.
   8f cb.
   90 cb.
   91 cb.
   92 cb.

   a0 cb.
   a1 cb.
   a2 cb.
   a3 cb.
   a8 cb.
   cr
;

: dump-d0f5
   h# 500 to config-base
   ." == D0F5 APIC" cr
   ch.

   50 cl.
   54 cb.
   55 cb.
   58 cb.
   59 cb.
   5e cb.
   5f cb.
   
   60 cb.
   61 cb.
   64 cb.
   
   80 cb.
   82 cb.
   83 cb.
   84 cb.
   85 cb.
   
   a2 cb.
   a3 cb.
   cr
;

\ d0f6 Scratch  some scratch regs  80.l .. 9c.l  shadowers

: dump-d0f7
   h# 700 to config-base
   ." == D0F7 North/South Module Control" cr
   ch.

   40 cb.
   71 cb.
   76 cb.
   \ Channel B DRAM init:  c0.d c8.d d0.d d8.d
   cr
;

: dump-d12f0
   h# 6000 to config-base
   ." == D12F0 SDIO" cr
   ch.

   44 cb.
   84 cl.
   88 cl.
   8c cb.
\  8d cb.  \ RO
   8e cb.
   8f cb.
   98 cb.
   99 cb.
   9a cb.
   cr
;

\ D13F0 is card controller

: dump-d15f0
   h# 7800 to config-base
   ." == D15F0 EIDE" cr
   ch.

   40 cb.
   45 cb.
   4a cb.
   4b cb.
   4c cb.
   4f cb.
   52 cb.
   53 cb.
   
   b0 cw.
   b2 cw.
   b4 cw.
   b9 cb.
   ba cw.
   bc cw.
   be cw.
   c1 cb.
   c2 cb.
   c3 cb.
   c4 cb.
   c6 cb.
   d4 cb.
   d5 cb.
   
   e0 cw.
\  f0 cb.  \ RO
   f1 cb.
   f2 cb.
   
   cr
;

: dump-d16f0
   h# 8000 to config-base
   ." == D16F0 UHCI 0,1" cr
   ch.

   40 cb.
   41 cb.
   42 cb.
   43 cb.
   48 cb.
   49 cb.
   4a cb.
   4b cb.
   4c cb.
   84 cb.
   c0 cw.
   cr
;

: dump-d16f1
   h# 8100 to config-base
   ." == D16F1 UHCI 2,3" cr
   ch.

   40 cb.
   41 cb.
   42 cb.
   43 cb.
   48 cb.
   49 cb.
   4a cb.
   4b cb.
   4c cb.
   84 cb.
   c0 cw.
   cr
;

: dump-d16f2
   h# 8200 to config-base
   ." == D16F2 UHCI 4,5" cr
   ch.

   40 cb.
   41 cb.
   42 cb.
   43 cb.
   48 cb.
   49 cb.
   4a cb.
   4b cb.
   4c cb.
   84 cb.
   c0 cw.
   cr
;

: dump-d16f4
   h# 8400 to config-base
   ." == D16F4 EHCI" cr
   ch.

   40 cb.
   42 cb.
   43 cb.
   48 cb.
   49 cb.
   4a cb.
   4b cb.
   4c cb.
   4d cb.
   4e cb.
   4f cb.
   50 cb.
   51 cb.
   52 cb.
   53 cb.
   54 cb.
   55 cb.
   56 cb.
   57 cb.
   58 cb.
   59 cb.
   5a cw.
   5c cb.
   5d cb.
   5e cb.
   5f cb.
   61 cb.
   
   62 cw.
   64 cb.
   68 cw.
   6c cw.
\  6e cw.  \ Status
   
   84 cw.
   cr
;

: dump-d17f0
   h# 8800 to config-base
   ." == D17F0 Bus Control and Power Management" cr
   ch.

   40 cb.
   41 cb.
   42 cb.
   43 cb.
   44 cb.
   45 cb.
   46 cb.
   47 cb.
   48 cb.
   49 cb.
   4a cb.
   4b cb.
   4c cb.
   4d cb.
   4e cb.
   4f cb.
   
   50 cb.
   51 cb.
   52 cb.
   53 cb.
   54 cb.
   55 cb.
   56 cb.
   57 cb.
   58 cb.
   59 cb.
   5a cb.
   5b cb.
   5c cw.
   5e cw.
   60 cw.
   62 cw.
   64 cw.
   66 cb.
   67 cb.
   68 cb.
   69 cb.
   6a cb.
   6b cb.
   6c cb.
   6d cb.
   6e cb.
   6f cb.
   70 cw.
   72 cw.
   75 cb.
   76 cb.
   77 cb.
   7c cb.
   7d cb.
   7e cb.
   7f cb.
   80 cb.
   81 cb.
   82 cb.
   83 cb.
   
   84 cw.
   86 cw.
   88 cw.
   8a cb.
   8c cb.
   8d cb.
   90 cl.
   94 cb.
   95 cb.
   96 cb.
   97 cb.
   98 cb.
   99 cb.
   9a cb.
   9b cb.
   9c cb.
   9d cb.
   9e cb.
   9f cb.
   b0 cb.
   b2 cb.
   b4 cb.
   b5 cb.
   b7 cb.
   b8 cb.
   b9 cb.
   ba cb.
   bb cb.
   bc cb.
   bd cb.
   be cb.
   c4 cl.
   d0 cw.
   d2 cb.
   d3 cb.
   d4 cb.
   d5 cb.
   d6 cb.
   e0 cb.
   e1 cb.
   e2 cb.
   e3 cb.
   e4 cb.
   e5 cb.
   e6 cb.
   e7 cb.
   
   e8 cl.
   ec cb.
   fc cb.
   cr
;

: dump-d17f7
   h# 8f00 to config-base
   ." == D17F7 South-North Module Interface Control" cr
   ch.

   4f cb.
   50 cb.
   51 cb.
   52 cb.
   53 cb.
   54 cb.
   55 cb.
   56 cb.
   60 cb.
   61 cb.
   62 cb.
   63 cb.
   64 cb.
   70 cb.
   71 cb.
   72 cb.
   73 cb.
   74 cb.
   75 cb.
   76 cb.
   77 cb.
   78 cb.
   79 cb.
   7a cb.
   7b cb.
   7c cb.
   80 cb.
   81 cb.
   82 cb.
   84 cb.
   d1 cb.
   e0 cb.
   e2 cb.
   e3 cb.
   e4 cb.
   e5 cb.
   e6 cb.
   fc cb.
   
   cr
;
: dump-d19f0
   h# 9800 to config-base
   ." == D19F0 PCI-PCI bridge" cr
   ch.


   40 cb.
   cr
;
: dump-d20f0
   h# a000 to config-base
   ." == D20F0 HD Audio" cr
   ch.

   40 cb.
   41 cb.
   44 cb.
   54 cw.
   64 cl.
   68 cl.
   6c cw.
   70 cw.
   cr
;

: dump-config-regs
   dump-d0f0
   dump-d0f1
   dump-d0f2
   dump-d0f3
   dump-d0f4
   dump-d0f5
   dump-d0f7
   dump-d12f0
   dump-d15f0
   dump-d16f0
   dump-d16f1
   dump-d16f2
   dump-d16f4
   dump-d17f0
   dump-d17f7
   dump-d19f0
   dump-d20f0
;

[ifdef] apic-ih
: ap.  ( index -- )
   dup (.4) type ." : "   ( index )
   " apic@" apic-ih $call-method  (.8) type cr
;
: dump-apic
   ." == APIC Registers" cr
   20 ap.
   320 ap.
   340 ap.
   350 ap.
   360 ap.
   380 ap.
   390 ap.
   cr
; 
: ioap.  ( index -- )
   dup (.2) type ." : "   ( index )
   " io-apic@" io-apic-ih $call-method  (.8) type cr
;

: ioapd.  ( index -- )
   dup (.2) type ." : "   ( index )
   dup 1+ " io-apic@" io-apic-ih $call-method  (.8) type  space
   " io-apic@" io-apic-ih $call-method  (.8) type cr
;

: dump-io-apic
   ." == IO-APIC Indexed Registers" cr
   0 ioap.
   1 ioap.
   2 ioap.
   3 ioap.
   40 10 do  i ioapd.  2 +loop
   cr
;
[then]

: udma.  ( index -- )
   dup (.2) type ." : "   ( index )
   88b8 config-w@ +   ( index port )
   pc@ (.2) type cr
;

: dump-uart-dma
   ." == UART DMA Indexed Registers" cr
   88b7 config-b@ 8 and  0=  if  ." <disabled>" cr exit  then
   
   0 udma.
   1 udma.
   2 udma.
   3 udma.
   cr
;

: dumpfun  ( dev func -- )
   ." Device " over .d  ." Function " dup .d cr
   h# 100 *  swap h# 800 * +
   h# 100  bounds  do
      i 8  bounds  do
         i h# ff and (.2) type ." ="
         i config-b@ (.2) type space
      loop
      cr
   h# 10 +loop
;

\ Omitting USB Device registers
\ Omitting Host Controller MMIO registers
\ Omitting SD Card Controller MMIO registers

: dump-all
   dump-config-regs
[ifdef] dump-apic
   dump-apic
   dump-io-apic
[then]
;
