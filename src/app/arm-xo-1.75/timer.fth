: +!@     ( value offset base -- )  + tuck l! l@ drop  ;
: timer!  ( value offset -- )  timer-pa +!@  ;
: init-timers  ( -- )
   h# 13  h# 24 clock-unit-pa + l!
   0  h# 84 timer-pa + l!      \ TMR_CER  - count enable
   begin  h# 84 timer-pa + l@  7 and  0=  until
   h# 24  h# 00 timer-pa +!@   \ TMR_CCR  - clock control
   h# 200 0 do loop
   0  h# 88 timer!       \ count mode - periodic
   0  h# 4c timer!       \ preload value timer 0
   0  h# 50 timer!       \ preload value timer 1
   0  h# 54 timer!       \ preload value timer 2
   0  h# 58 timer!       \ free run timer 0
   0  h# 5c timer!       \ free run timer 1
   0  h# 60 timer!       \ free run timer 2
   7  h# 74 timer!       \ interrupt clear timer 0
   h# 100  h# 4 timer!   \ Force match
   h# 100  h# 8 timer!   \ Force match
   h# 100  h# c timer!   \ Force match
   h# 200 0 do loop
   7 h# 84 timer!
;

[ifdef] arm-assembler
code timer0@  ( -- n )  \ 6.5 MHz
   psh  tos,sp
   set  r1,0xD4014000
   mov  r0,#1
   str  r0,[r1,#0xa4]
   mov  r0,r0
   ldr  tos,[r1,#0x28]
c;

code timer1@  ( -- n )  \ 32.768 kHz
   psh  tos,sp
   set  r1,0xD4014000
   mov  r0,#1
   str  r0,[r1,#0xa8]
   mov  r0,r0
   ldr  tos,[r1,#0x2c]
c;

code timer2@  ( -- n )  \ 1 kHz
   psh  tos,sp
   set  r1,0xD4014000
   mov  r0,#1
   str  r0,[r1,#0xac]
   mov  r0,r0
   ldr  tos,[r1,#0x30]
c;
[else]
: timer0@  ( -- n )  1 h# d40140a4 l!  h# d4014028 l@  ;
: timer1@  ( -- n )  1 h# d40140a8 l!  h# d401402c l@  ;
: timer2@  ( -- n )  1 h# d40140ac l!  h# d4014030 l@  ;
[then]

: timer0-status@  ( -- n )  h# d4014034 l@  ;
: timer1-status@  ( -- n )  h# d4014038 l@  ;
: timer2-status@  ( -- n )  h# d401403c l@  ;

: timer0-ier@  ( -- n )  h# d4014040 l@  ;
: timer1-ier@  ( -- n )  h# d4014044 l@  ;
: timer2-ier@  ( -- n )  h# d4014048 l@  ;

: timer0-icr!  ( n -- )  h# d4014074 l!  ;
: timer1-icr!  ( n -- )  h# d4014078 l!  ;
: timer2-icr!  ( n -- )  h# d401407c l!  ;

: timer0-ier!  ( n -- )  h# d4014040 l!  ;
: timer1-ier!  ( n -- )  h# d4014044 l!  ;
: timer2-ier!  ( n -- )  h# d4014048 l!  ;

: timer0-match0!  ( n -- )  h# d4014004 l!  ;  : timer0-match0@  ( -- n )  h# d4014004 l@  ;
: timer0-match1!  ( n -- )  h# d4014008 l!  ;  : timer0-match1@  ( -- n )  h# d4014008 l@  ;
: timer0-match2!  ( n -- )  h# d401400c l!  ;  : timer0-match2@  ( -- n )  h# d401400c l@  ;

: timer1-match0!  ( n -- )  h# d4014010 l!  ;  : timer1-match0@  ( -- n )  h# d4014010 l@  ;
: timer1-match1!  ( n -- )  h# d4014014 l!  ;  : timer1-match1@  ( -- n )  h# d4014014 l@  ;
: timer1-match2!  ( n -- )  h# d4014018 l!  ;  : timer1-match2@  ( -- n )  h# d4014018 l@  ;

: timer2-match0!  ( n -- )  h# d401401c l!  ;  : timer2-match0@  ( -- n )  h# d401401c l@  ;
: timer2-match1!  ( n -- )  h# d4014020 l!  ;  : timer2-match1@  ( -- n )  h# d4014020 l@  ;
: timer2-match2!  ( n -- )  h# d4014024 l!  ;  : timer2-match2@  ( -- n )  h# d4014024 l@  ;

' timer2@ to get-msecs
: (ms)  ( delay-ms -- )
   get-msecs +  begin     ( limit )
      pause               ( limit )
      dup get-msecs -     ( limit delta )
   0< until               ( limit )
   drop
;
' (ms) to ms

: us  ( delay-us -- )
   d# 13 2 */  timer0@ +  ( limit )
   begin                  ( limit )
      dup timer0@ -       ( limit delta )
   0< until               ( limit )
   drop
;

\ Timing tools
variable timestamp
: t-update ;
: t(  ( -- )  timer0@ timestamp ! ;
: ))t  ( -- ticks )  timer0@  timestamp @  -  ;
: ))t-usecs  ( -- usecs )  ))t 2 d# 13 */  ;
: )t  ( -- )
   ))t-usecs  ( microseconds )
   push-decimal
   <#  u# u# u#  [char] , hold  u# u#s u#>  type  ."  us "
   pop-base
;
: t-msec(  ( -- )  timer2@ timestamp ! ;
: ))t-msec  ( -- msecs )  timer2@  timestamp @  -  ;
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
