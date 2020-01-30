\ Ariel (Dell Wyse 3020) board support
\
\ Copyright (C) 2020 Lubomir Rintel <lkundrak@v3.sk>
\
\ Based on src/app/arm-xo-cl4/app.fth and
\ src/app/arm-xo-1.75/olpcbasics.fth

create mmp3

h#   10.0000 constant /rom
h# 08fe.0000 constant dlofw-base

fl ../arm-ariel/gpiopins.fth
fl ../arm-mmp2/mfprbits.fth
fl ../arm-ariel/mfprtable.fth
fl ../arm-mmp2/mmp2drivers.fth
fl ../arm-ariel/boardgpio.fth
fl ../arm-xo-cl4/clockset.fth
fl ../arm-ariel/initdram.fth
fl ../arm-xo-1.75/smbus.fth
fl ../arm-xo-1.75/addrs.fth
fl ../arm-mmp2/lcd.fth
fl ../arm-ariel/panel.fth
fl ../arm-xo-1.75/banner.fth
fl ../arm-xo-1.75/controls.fth
fl ../arm-xo-1.75/showfb.fth
fl ../arm-xo-1.75/hackspi.fth
fl ../arm-xo-1.75/dropin.fth
fl ../arm-xo-1.75/showlog.fth
fl ../arm-xo-1.75/showpmu.fth  \ Power management debugging words
fl ../arm-xo-1.75/showicu.fth  \ Interrupt controller debugging words
fl ../arm-xo-1.75/memtest.fth

: ariel-ec-pulse  ( -- )
   \ We're supposed to signal readiness to power off to the EC with a
   \ 10 MHz pulse. Delays of 48ms - 68ms seem to create a wave that's
   \ good enough for the EC. Choose the middle value
   begin
      ec-off-pulse-gpio# gpio-clr  d# 58 ms
      ec-off-pulse-gpio# gpio-set  d# 58 ms
   again
;

: power-off  ( -- )
   ec-off-type-gpio# gpio-set
   ariel-ec-pulse
;

: reboot  ( -- )
   ec-off-type-gpio# gpio-clr
   ariel-ec-pulse
;

: ?startup-problem  ( -- )
   thermal?  if  ." thermal power-off" cr  power-off  then
   watchdog?  if  ." watchdog restart" cr  epitaph  bye  then
   setup-thermal
;

: late-init
   ?startup-problem
   set-frequency-1.2g
   init-dram
;

: release-main-cpu  ( -- )
   h# 02 h# 050020 +io bitclr   \ Release reset for PJ4 (MPCORE 1)
;

fl ../arm-xo-1.75/ofw.fth

\ Run this at startup
: app  ( -- )
   h# 20 mpmu@ 2 and  0=  if
      ." CForth unexpected restart! - freezing PJ4" cr
      2  h# 20 mpmu-set
      quit
   then
   banner
   basic-setup
   init-timers
   enable-wdt-clock
   set-gpio-directions
   init-mfprs
   early-activate-cforth?  0=  if
      ['] ofw catch .error
   then
   ." Skipping OFW" cr
   hex quit
;

" app.dic" save
