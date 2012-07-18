alias purpose: \

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

defer ms  defer get-msecs
fl ../arm-mmp2/timer.fth
fl ../arm-mmp2/watchdog.fth
fl ../arm-mmp2/timer2.fth
fl ../arm-mmp2/gpio.fth
fl ../arm-mmp2/mfpr.fth
fl ../arm-mmp2/fuse.fth
fl ../arm-mmp2/thermal.fth
