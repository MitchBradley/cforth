fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth

fl ../arm-mmp2/hwaddrs.fth

: +io  ( offset -- adr )  h# d4000000 +  ;
: io!  ( l offset -- )  +io l!  ;
: io@  ( offset l -- )  +io l@  ;
: io!@  ( l offset -- )  tuck io! io@ drop  ;
: +io!@  ( l offset base -- )  + io!@  ;

: bitclr   ( and-val regadr -- )  tuck l@ swap invert and swap l!  ;
: bitset   ( or-val regadr -- )  tuck l@ or  swap l!  ;
: bitfld   ( set-val clr-mask regadr -- )
   tuck l@  swap invert and      ( set-val regadr regval )
   rot or  swap l!
;
: +mpmu h# 050000 +  ; 
: mpmu! +mpmu io! ; : mpmu@ +mpmu io@ ;

: mpmu-set  ( or-val regadr -- )  +mpmu +io bitset  ;
: mpmu-clr  ( and-val regadr -- )  +mpmu +io bitclr  ;

: +pmua h# 282800 +  ; 
: pmua! +pmua io! ; : pmua@ +pmua io@ ;

: pmua-set  ( or-val regadr -- )  +pmua +io bitset  ;
: pmua-clr  ( and-val regadr -- )  +pmua +io bitclr  ;


defer ms  defer get-msecs
fl ../arm-mmp2/timer.fth
fl ../arm-mmp2/watchdog.fth
fl ../arm-mmp2/timer2.fth
fl ../arm-mmp2/gpio.fth
fl ../arm-mmp2/mfpr.fth
fl ../arm-mmp2/fuse.fth
fl ../arm-mmp2/thermal.fth
