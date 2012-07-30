\ Load file for application-specific Forth extensions

\ fl ../arm-xo-cl4/gpiopins.fth
fl ../arm-mmp2/mfprbits.fth
fl mfprtable.fth
fl ../arm-mmp2/mmp2drivers.fth
fl boardgpio.fth

fl ../arm-mmp3-thunderstone/basics.fth
fl ../arm-xo-1.75/memtest.fth

: board-config  ( -- )
   \ Add board-revision-specific setup as necessary
;

: late-init
   init-dram    ." DRAM initialized" cr
;

: release-main-cpu  ( -- )
\   0 h# 050020 io!  

\   h# 18 h# 282988 +io bitset   \ TIMER_CLKEN + TIMER_SW_RST(_N)
   h# 02 h# 050020 +io bitclr   \ Release reset for PJ4
\   h# 0200.0000 h# 282950 +io bitset  \ PMUA_CC2_PJ - MPCRE2_SW_RSTN
\   h# 0400.0000 h# 282950 +io bitset  \ PMUA_CC2_PJ - MMCRE_SW_RSTN
;

fl ../arm-mmp3-thunderstone/ofw.fth
: .mfprs   ( -- )
   hex
   d# 172 0 do
      decimal i 3 u.r  hex  i 8 bounds do  i af@ 5 u.r  loop  cr
   8 +loop
;

\ Run this at startup
: app  ( -- )
   init-mfprs
   init-drivers
   board-config
   late-init
\    early-activate-cforth?  0=  if  ofw  then
   ." Skipping OFW" cr
   hex quit
;

" app.dic" save
