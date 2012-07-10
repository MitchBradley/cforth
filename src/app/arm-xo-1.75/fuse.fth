purpose: Program Armada610 Fuses
0 value block#
: fuse-ena!  ( n -- )  h# 282868 io!  ;
: fuse-ctl!  ( n -- )  block# d# 18 lshift or  h# 292804 io!  d# 100 ms  ;
: ena-fuse-module  ( -- )
   h# 08 fuse-ena!
   h# 09 fuse-ena!
   h# 19 fuse-ena!
   h# 1b fuse-ena!
;

: otp-setup  ( -- )
   h# 0002.0000 fuse-ctl!   \ HiV
   h# 0042.0000 fuse-ctl!   \ Reset + HiV
   h# 0002.0000 fuse-ctl!   \ HiV
;
: otp-teardown  ( -- )
   h# 0200.4000 fuse-ctl!   \ ClkDiv                      + SOFT
   h# 0240.4000 fuse-ctl!   \ ClkDiv + SetRst             + SOFT
   h# 0200.4000 fuse-ctl!   \ ClkDiv                      + SOFT
;
: +block  ( n -- n' )  d# 18 lshift or  ;
: pgm-fuses  ( v3 v2 v1 v0 block# -- )
   to block#       ( v3 v2 v1 v0 )
   ena-fuse-module ( v3 v2 v1 v0 )
   otp-setup       ( v3 v2 v1 v0 )
   h# 292838 io!  ( v3 v2 v1 )
   h# 29283c io!  ( v3 v2 )
   h# 292840 io!  ( v3 )
   h# 292844 io!  ( )
   h# 0203.4000 fuse-ctl!   \ ClkDiv +         HiV + Burn + SOFT
   begin  h# 292984 io@ h# 100 and  until  \ Wait for complete
   h# 0202.4000 fuse-ctl!   \ ClkDiv +         HiV +      + SOFT
   h# 0200.4000 fuse-ctl!   \ ClkDiv +                    + SOFT
   h# 0240.4000 fuse-ctl!   \ ClkDiv + SetRst             + SOFT
   h# 0200.4000 fuse-ctl!   \ ClkDiv +                    + SOFT
;
: read-fuses  ( -- )
   ena-fuse-module
   otp-setup
   h# 292904 +io h# 10 ldump
;
[ifdef] wanted-fuses
: new-fuses  ( -- )
   h# 00000000
   wanted-fuses
   h# c10d9720
   h# 00000080
   0 pgm-fuses
;
: fix-fuses  ( -- )
   ena-fuse-module
   otp-setup
   h# 29290c io@ wanted-fuses <>  if
      ." Old fuse value is " h# 29290c io@ u. cr
      ." Fixing fuses" cr
      new-fuses
      otp-setup
      h# 29290c io@ wanted-fuses <>  if
         ." FUSE DID NOT REPROGRAM CORRECTLY!!!" cr
      else
         ." Fuse reprogramming succeeded" cr
      then
   else
      ." Fuses already fixed" cr
   then
   otp-teardown
;
[then]

\ Speed codes are in fuse block 3 bits 239:238.  0:800MHz, 1:910MHz, 2:1001MHz, 3:reserved
: rated-speed  ( -- n )  ena-fuse-module  h# 2928a4 io@ d# 14 rshift 3 and  ;
