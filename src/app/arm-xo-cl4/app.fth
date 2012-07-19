create cl4  \ OLPC XO-CL4

fl ../arm-xo-cl4/gpiopins.fth
fl ../arm-mmp2/mfprbits.fth
fl ../arm-xo-cl4/mfprtable.fth

fl ../arm-mmp2/mmp2drivers.fth
fl ../arm-xo-1.75/boardgpio.fth
fl ../arm-xo-cl4/clockset.fth
fl ../arm-xo-cl4/initdram.fth
fl ../arm-xo-1.75/olpcbasics.fth
fl ../arm-xo-1.75/memtest.fth

: board-config  ( -- )
   \ Add board-revision-specific setup as necessary
;

: late-init
   ?startup-problem

   set-clock-frequency

   init-dram
;

: release-main-cpu  ( -- )
\   h# 18 h# 282988 +io bitset   \ TIMER_CLKEN + TIMER_SW_RST(_N)
   h# 02 h# 050020 +io bitclr   \ Release reset for PJ4 (MPCORE 1)
\   h# 0200.0000 h# 282950 +io bitset  \ PMUA_CC2_PJ - MPCRE2_SW_RSTN (MPCORE 2)
\   h# 0400.0000 h# 282950 +io bitset  \ PMUA_CC2_PJ - MMCRE_SW_RSTN  (MMCORE)
;

fl ../arm-xo-1.75/ofw.fth

\ Run this at startup
: app  ( -- )
   init-drivers
   board-config
   early-activate-cforth?  0=  if  ofw  then
   ." Skipping OFW" cr
   hex protect-fw quit
;

" app.dic" save
