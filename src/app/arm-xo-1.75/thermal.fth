: thermal?  ( -- ? )
   \ was this reset caused by thermal watchdog?
   main-pmu-pa h# 0028 + io@  h# 10 and
;

: setup-thermal  ( -- )
   7 h# 015090 io!             \ reset thermal sensor
   3 h# 015090 io!             \ enable clocks to thermal sensor
   h# 10000 thermal-pa io!     \ enable sensing

   \ set thermal watchdog threshold to 85 degrees C
   d# 696 thermal-pa 4 + io!

   \ clear thermal watchdog reset status
   \ set thermal watchdog reset enable
   h# 88 thermal-pa h# 10 +  io!

   \ set thermal watchdog reset enable (bit 7)
   \ (bits 31:8, and 5 are reserved, sw must always write 0)
   main-pmu-pa h# 200 +  io@
   b# 1101.1111 and
   b# 1000.0000 or
   main-pmu-pa h# 200 +  io!
;
