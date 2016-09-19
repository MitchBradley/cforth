\ Interface definitions to splice xmodem into Open Firmware

alias m-key  rem-key
alias m-emit rem-emit

\ : m-init  ( -- )  rem-init  ;
: m-init  ;  \ No need to do anything; it's already on by the time we get here

8 constant bs

\ : panel-button?  ( -- flag )  key?  ;
: panel-button?  ( -- flag )  false  ;  \ We don't want to abort
: panel-d.  ( n -- )
   #out @ >r
   push-decimal
   <#  u# u# u#  bs hold bs hold bs hold  u#> type
   pop-base
   r> #out !
;

: panel-msg:  create ",  does> count type  ;

" Abort"   panel-msg: abrt-msg     \ Abrt
" Cancel"  panel-msg: can-msg      \ CAn
: crc-msg ;  \ " Xmodem-CRC" panel-msg: crc-msg      \ crc
: done-msg ; \ " Done"    panel-msg: done-msg     \ donE
" Timeout" panel-msg: timeout-msg  \ tout
" r0" panel-msg: r0-msg       \ r0
" r1" panel-msg: r1-msg       \ r1
" r2" panel-msg: r2-msg       \ r2
" r3" panel-msg: r3-msg       \ r3
" r4" panel-msg: r4-msg       \ r4
" r5" panel-msg: r5-msg       \ r5
" r6" panel-msg: r6-msg       \ r6
" r7" panel-msg: r7-msg       \ r7
0 [if]
" t0" panel-msg: t0-msg       \ t0
" t1" panel-msg: t1-msg       \ t1
" t2" panel-msg: t2-msg       \ t2
" t3" panel-msg: t3-msg       \ t3
" t4" panel-msg: t4-msg       \ t4
" t5" panel-msg: t5-msg       \ t5
" t6" panel-msg: t6-msg       \ t6
" t7" panel-msg: t7-msg       \ t7
[then]
" Error"  panel-msg: giveup-msg   \ Err
" Loading diags    " panel-msg: upld-msg    \ UPLd
" OF"   panel-msg: of-msg         \ OF
" Cancel" panel-msg: can-msg

: bogus-char  ( c -- )  ." Bogus: " .x  ;
: ignore-char  ( c -- )  ." Ignoring: " .x  ;

\ : ms>ticks  ( ms -- ticks )   ;

variable timer-init

: timed-in  ( -- true | char false ) \ get a character unless timeout
   get-ticks  timer-init @ +   ( time-limit )
   begin
      rem-avail?  if  nip false  exit   then
   dup get-ticks - 0<  until
   drop true
;

alias purpose: \
alias copyright: \

[ifndef] 3dup  : 3dup  ( -- )  2 pick 2 pick 2 pick  ;  [then]
