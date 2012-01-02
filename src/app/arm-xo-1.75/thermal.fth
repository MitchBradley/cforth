h# 01.3200 constant thermal-base
: thermal  ( -- )
   \ power off if this reset was caused by thermal watchdog
   main-pmu-pa h# 0028 + l@  h# 10 and  if
       ." thermal power-off" cr
       open-ec  4c ec-cmd  close-ec
       begin wfi again
   then

   \ report but otherwise ignore a watchdog restart
   h# d4080070 io@  1 and  if
       ." watchdog restart" cr
   then

   7 h# 015090 io!             \ reset thermal sensor
   3 h# 015090 io!             \ enable clocks to thermal sensor
   h# 10000 thermal-base io!   \ enable sensing

   \ set thermal watchdog threshold to 85 degrees C
   d# 696 thermal-base 4 + io!

   \ clear thermal watchdog reset status
   \ set thermal watchdog reset enable
   h# 88 thermal-base h# 10 +  io!

   \ set thermal watchdog reset enable (bit 7)
   \ (bits 31:8, and 5 are reserved, sw must always write 0)
   main-pmu-pa h# 200 +  l@
   b# 1101.1111 and
   b# 1000.0000 or
   main-pmu-pa h# 200 +  l!
;
