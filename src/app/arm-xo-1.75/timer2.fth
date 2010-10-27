: +!@     ( value offset base -- )  + tuck l! l@ drop  ;
: timer-2@  ( offset -- value )  timer-2-pa + l@  ;
: timer-2!  ( value offset -- )  timer-2-pa +!@  ;
: init-timer-2s  ( -- )
   main-pmu-pa h# 1020 +  dup l@  h# 10 or  swap l!  \ enable wdt 2 clock  PMUM_PRR_PJ
   h# 13  h# 24 clock-unit-pa + l!

   h# 7 h# 200 main-pmu-pa + l!
   h# 3 h# 200 main-pmu-pa + l!
   0  h# 84 timer-2-pa + l!      \ TMR_CER  - count enable
   begin  h# 84 timer-2-pa + l@  7 and  0=  until
   h# 24  h# 00 timer-2-pa +!@   \ TMR_CCR  - clock control
   h# 200 0 do loop
   0  h# 88 timer-2!       \ count mode - periodic
   0  h# 4c timer-2!       \ preload value timer-2 0
   0  h# 50 timer-2!       \ preload value timer-2 1
   0  h# 54 timer-2!       \ preload value timer-2 2
   0  h# 58 timer-2!       \ free run timer-2 0
   0  h# 5c timer-2!       \ free run timer-2 1
   0  h# 60 timer-2!       \ free run timer-2 2
   7  h# 74 timer-2!       \ interrupt clear timer-2 0
   h# 100  h# 4 timer-2!   \ Force match
   h# 100  h# 8 timer-2!   \ Force match
   h# 100  h# c timer-2!   \ Force match
   h# 200 0 do loop
   7 h# 84 timer-2!
;

[ifdef] arm-assembler
code timer-20@  ( -- n )  \ 6.5 MHz
   psh  tos,sp
   set  r1,0xD4080000
   mov  r0,#1
   str  r0,[r1,#0xa4]
   mov  r0,r0
   ldr  tos,[r1,#0x28]
c;

code timer-21@  ( -- n )  \ 32.768 kHz
   psh  tos,sp
   set  r1,0xD4080000
   mov  r0,#1
   str  r0,[r1,#0xa8]
   mov  r0,r0
   ldr  tos,[r1,#0x2c]
c;

code timer-22@  ( -- n )  \ 1 kHz
   psh  tos,sp
   set  r1,0xD4080000
   mov  r0,#1
   str  r0,[r1,#0xac]
   mov  r0,r0
   ldr  tos,[r1,#0x30]
c;
[else]
: timer-20@  ( -- n )  1 h# a4 timer-2!  h# 28 timer-2@  ;
: timer-21@  ( -- n )  1 h# a8 timer-2!  h# 2c timer-2@  ;
: timer-22@  ( -- n )  1 h# ac timer-2!  h# 30 timer-2@  ;
[then]

: timer-20-status@  ( -- n )  h# 34 timer-2@  ;
: timer-21-status@  ( -- n )  h# 38 timer-2@  ;
: timer-22-status@  ( -- n )  h# 3c timer-2@  ;

: timer-20-ier@  ( -- n )  h# 40 timer-2@  ;
: timer-21-ier@  ( -- n )  h# 44 timer-2@  ;
: timer-22-ier@  ( -- n )  h# 48 timer-2@  ;

: timer-20-icr!  ( n -- )  h# 74 timer-2!  ;
: timer-21-icr!  ( n -- )  h# 78 timer-2!  ;
: timer-22-icr!  ( n -- )  h# 7c timer-2!  ;

: timer-20-ier!  ( n -- )  h# 40 timer-2!  ;
: timer-21-ier!  ( n -- )  h# 44 timer-2!  ;
: timer-22-ier!  ( n -- )  h# 48 timer-2!  ;

: timer-20-match0!  ( n -- )  h# 04 timer-2!  ;  : timer-20-match0@  ( -- n )  h# 04 timer-2@  ;
: timer-20-match1!  ( n -- )  h# 08 timer-2!  ;  : timer-20-match1@  ( -- n )  h# 08 timer-2@  ;
: timer-20-match2!  ( n -- )  h# 0c timer-2!  ;  : timer-20-match2@  ( -- n )  h# 0c timer-2@  ;

: timer-21-match0!  ( n -- )  h# 10 timer-2!  ;  : timer-21-match0@  ( -- n )  h# 10 timer-2@  ;
: timer-21-match1!  ( n -- )  h# 14 timer-2!  ;  : timer-21-match1@  ( -- n )  h# 14 timer-2@  ;
: timer-21-match2!  ( n -- )  h# 18 timer-2!  ;  : timer-21-match2@  ( -- n )  h# 18 timer-2@  ;

: timer-22-match0!  ( n -- )  h# 1c timer-2!  ;  : timer-22-match0@  ( -- n )  h# 1c timer-2@  ;
: timer-22-match1!  ( n -- )  h# 20 timer-2!  ;  : timer-22-match1@  ( -- n )  h# 20 timer-2@  ;
: timer-22-match2!  ( n -- )  h# 24 timer-2!  ;  : timer-22-match2@  ( -- n )  h# 24 timer-2@  ;

0 [if]
' timer-22@ to get-msecs
: (ms)  ( delay-ms -- )
   get-msecs +  begin     ( limit )
      pause               ( limit )
      dup get-msecs -     ( limit delta )
   0< until               ( limit )
   drop
;
' (ms) to ms

: us  ( delay-us -- )
   d# 13 2 */  timer-20@ +  ( limit )
   begin                  ( limit )
      dup timer-20@ -       ( limit delta )
   0< until               ( limit )
   drop
;

\ Timing tools
variable timestamp
: t-update ;
: t(  ( -- )  timer-20@ timestamp ! ;
: ))t  ( -- ticks )  timer-20@  timestamp @  -  ;
: ))t-usecs  ( -- usecs )  ))t 2 d# 13 */  ;
: )t  ( -- )
   ))t-usecs  ( microseconds )
   push-decimal
   <#  u# u# u#  [char] , hold  u# u#s u#>  type  ."  us "
   pop-base
;
: t-msec(  ( -- )  timer-22@ timestamp ! ;
: ))t-msec  ( -- msecs )  timer-22@  timestamp @  -  ;
: )t-msec  ( -- )
   ))t-msec
   push-decimal
   <# u# u#s u#>  type  ." ms "
   pop-base
;

: t-sec(  ( -- )  t-msec(  ;
: ))t-sec  ( -- secs )  ))t-msec d# 1000 /  ;
: )t-sec  ( -- )
   ))t-sec
   push-decimal
   <# u# u#s u#>  type  ." s "
   pop-base
;

: .hms  ( seconds -- )
   d# 60 /mod   d# 60 /mod    ( sec min hrs )
   push-decimal
   <# u# u#s u#> type ." :" <# u# u# u#> type ." :" <# u# u# u#>  type
   pop-base
;
: t-hms(  ( -- )  t-sec(  ;
: )t-hms
   ))t-sec  ( seconds )
   .hms
;
[then]
