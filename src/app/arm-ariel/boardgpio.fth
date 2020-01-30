purpose: Board-specific setup details - pin assigments, etc.

: gpio-out-clr  ( gpio# -- )  dup gpio-clr  gpio-dir-out  ;
: gpio-out-set  ( gpio# -- )  dup gpio-set  gpio-dir-out  ;

: set-gpio-directions  ( -- )
   3  h# 38 clock-unit-pa +  io!  \ Enable clocks in GPIO clock reset register

   spi-flash-cs-gpio#   gpio-dir-out
   ec-off-pulse-gpio#   gpio-dir-out
   ec-off-type-gpio#    gpio-dir-out
;
