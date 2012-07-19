h# 1000.0000 value memtest-start    \ Boosted address of main memory
h# 0800.0000 value memtest-length
: memtest  ( -- )
   ." Memory addresses are offset by 0x1000.0000 due to SP addressing quirks" cr
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

0 [if]
: fillit
   'compressed h# 48000 h# ff fill
;
: testit
   'compressed h# 48000 bounds do i @ dup -1 <> if i . . cr leave else drop then 4 +loop
;
: app  init0 clk-fast ." To init DRAM, type 'init1'.  To boot, type 'ofw'" cr  hex protect-fw quit ;
[then]
