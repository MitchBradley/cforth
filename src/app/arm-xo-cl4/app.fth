create mmp3  \ MMP3-based OLPC XO-CL4

h#   10.0000 constant /rom
h# 08fe.0000 constant dlofw-base

fl ../arm-xo-cl4/gpiopins.fth
fl ../arm-mmp2/mfprbits.fth
fl ../arm-xo-cl4/mfprtable.fth

fl ../arm-mmp2/mmp2drivers.fth
fl ../arm-xo-1.75/boardgpio.fth
fl ../arm-xo-cl4/clockset.fth
fl ../arm-xo-cl4/initdram.fth
fl ../arm-xo-1.75/olpcbasics.fth
fl ../arm-xo-1.75/showpmu.fth  \ Power management debugging words
fl ../arm-xo-1.75/showicu.fth  \ Interrupt controller debugging words
fl ../arm-xo-1.75/memtest.fth

: isolate-mmc3-pins   ( gpio# #gpios -- )
   bounds  ?do  i gpio-dir-out  i gpio-clr  loop
;

\ The MMC3 functional unit back-drives the eMMC power through the
\ signal lines when the eMMC power switch is off, leading to intermittent
\ failures to turn on the eMMC.  The workaround is to set the MMC3 pins
\ to GPIOs driving 0 when the eMMC is not in use.
: isolate-emmc  ( -- )
   d# 108 4 isolate-mmc3-pins
   d# 161 4 isolate-mmc3-pins
   d# 145 2 isolate-mmc3-pins
;

: board-config  ( -- )
   isolate-emmc

   \ Add board-revision-specific setup as necessary
   vid2-gpio# gpio-set
;

: late-init
   ?startup-problem
   set-frequency-1.2g
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
   early-activate-cforth?  0=  if
      ['] ofw catch .error
   then
   ." Skipping OFW" cr
   hex protect-fw quit
;

" app.dic" save
