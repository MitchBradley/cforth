purpose: Program Armada610 Fuses
0 value block#
: fuse-ena!  ( n -- )  h# d4282868 l!  ;
: fuse-ctl!  ( n -- )  block# d# 18 lshift or  h# d4292804 l!  d# 100 ms  ;
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
   h# d4292838 l!  ( v3 v2 v1 )
   h# d429283c l!  ( v3 v2 )
   h# d4292840 l!  ( v3 )
   h# d4292844 l!  ( )
   h# 0203.4000 fuse-ctl!   \ ClkDiv +         HiV + Burn + SOFT
   begin  h# d4292984 l@ h# 100 and  until  \ Wait for complete
   h# 0202.4000 fuse-ctl!   \ ClkDiv +         HiV +      + SOFT
   h# 0200.4000 fuse-ctl!   \ ClkDiv +                    + SOFT
   h# 0240.4000 fuse-ctl!   \ ClkDiv + SetRst             + SOFT
   h# 0200.4000 fuse-ctl!   \ ClkDiv +                    + SOFT
;
: read-fuses  ( -- )
   ena-fuse-module
   otp-setup
   h# d4292904 h# 10 ldump
;
: new-fuses  ( -- )
   h# 00000000
   h# 88028416
   h# c10d9720
   h# 00000080
   0 pgm-fuses
;
: fix-fuses  ( -- )
   ena-fuse-module
   otp-setup
   h# d429290c l@ h# 88028416 <> if
      ." Old fuse value is " h# d429290c l@ u. cr
      ." Fixing fuses" cr
      new-fuses
      otp-setup
      h# d429290c l@ h# 88028416 <>  if
         ." FUSE DID NOT REPROGRAM CORRECTLY!!!" cr
      else
         ." Fuse reprogramming succeeded" cr
      then
   else
      ." Fuses already fixed" cr
   then
   otp-teardown
;
