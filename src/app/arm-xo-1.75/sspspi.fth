h# 035000 value ssp-base  \ SSP1
: ssp-sscr0  ( -- adr )  ssp-base  ;
: ssp-sscr1  ( -- adr )  ssp-base  la1+  ;
: ssp-sssr   ( -- adr )  ssp-base  2 la+  ;
: ssp-ssdr   ( -- adr )  ssp-base  4 la+  ;

: ssp-spi-cs-on   ( -- )  h# 87 ssp-sscr0 io!  short-delay  ;
: ssp-spi-cs-off  ( -- )  h# 07 ssp-sscr0 io! ;

: ssp-spi-out-in  ( bo -- bi )
   begin  ssp-sssr io@ 4 and  until  \ Tx not full
   ssp-ssdr io!
   begin  ssp-sssr io@ 8 and  until  \ Rx not empty
   ssp-ssdr io@
;

: ssp-spi-out  ( b -- )  ssp-spi-out-in drop  ;
: ssp-spi-in  ( -- b )  0 ssp-spi-out-in  ;

: ssp1-clk-on  7 h# 015050 io!   3 h# 015050 io!  ;
: select-ssp1-pins  ( -- )
   h# 5003 h# 01e100 io!
   h# 5003 h# 01e104 io!
   h# 5003 h# 01e108 io!
   h# 5003 h# 01e10c io!
;

: ssp-spi-start  ( -- )
   select-ssp1-pins
   ssp1-clk-on
   0 ssp-sscr1 io!
;
: ssp-spi-reprogrammed  ( -- )
;

: use-ssp-spi  ( -- )
   ['] ssp-spi-start  to spi-start
   ['] ssp-spi-in     to spi-in
   ['] ssp-spi-out    to spi-out
   ['] ssp-spi-cs-on  to spi-cs-on
   ['] ssp-spi-cs-off to spi-cs-off
   ['] ssp-spi-reprogrammed to spi-reprogrammed
   use-spi-flash-read
;
use-ssp-spi
