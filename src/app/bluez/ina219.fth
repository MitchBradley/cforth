\ Interface to INA219 high-side voltage/current monitor chip

\needs read-i2c  fload i2c.fth

$40 value ina-i2c-slave
: select-ina  ( 0..3 -- )  " "(40 41 44 45)" drop + c@  to ina-i2c-slave  ;

\needs be-w@  : be-w@  ( adr -- w )  dup 1+ c@  swap c@  bwjoin  ;
\needs be-w!  : be-w!  ( w adr -- )  >r  wbsplit  r@ c!  r> 1+ c!  ;
4 buffer: ina-buf
: ina-setup  ( reg# -- )  ina-i2c-slave set-i2c-slave  ina-buf c!  ;
: ina@  ( reg# -- w )  ina-setup  ina-buf 1 write-i2c  ina-buf 2 read-i2c  ina-buf be-w@  ;
: ina!  ( w reg# -- )  ina-setup  ina-buf 1+ be-w!  ina-buf 3 write-i2c  ;
: ina-config@  ( -- w )  0 ina@  ;
: ina-config!  ( w -- )  0 ina!  ;
: ina-reset  ( -- )  $8000 ina-config!  ;
: ina-calibration!  ( w -- )  5 ina!  ;
: ina-shunt-voltage@  ( -- w )  1 ina@  w->n  ;
: ina-bus-voltage@  ( -- w )  2 ina@  ;
: ina-power@  ( -- w )  3 ina@  ;
: ina-current@  ( -- w )  4 ina@  w->n  ;

: +fsr16v  ( n -- n' )  ;
: +fsr32v  ( n -- n' )  $2000 or  ;
: +gain/1  ( n -- n' )  ;
: +gain/2  ( n -- n' )  $800 or  ;
: +gain/4  ( n -- n' )  $1000 or  ;
: +gain/8  ( n -- n' )  $1800 or  ;
: +bus-resolution    ( n res -- n' )  7 lshift or  ;
: +shunt-resolution  ( n res -- n' )  3 lshift or  ;
: +triggered  ( n -- n' )  ;
: +continuous  ( n -- n' )  4 or  ;
: +shunt  ( n -- n' )  1 or  ;
: +bus  ( n -- n' )  2 or  ;

: ina-base-mode  ( -- n )
   0
   +fsr16v                \ Minimum bus voltage range
   +gain/1                \ Max gain
   #15 +bus-resolution    \ 12 bits, long average
   #15 +shunt-resolution  \ 12 bits, long average
   +triggered
;
: ina-wait  ( -- bus-reg )
   0  begin  drop ina-bus-voltage@  dup  2 and  until  ( bus-reg )
;
: ina-get-v&i  ( -- mV uA )
   ina-base-mode +bus +shunt ina-config!
   ina-wait  7 invert and  2/  ( mV )
   ina-shunt-voltage@ #100 *   ( mV uA )
;
: ina-get-v  ( -- mV )
   ina-base-mode +bus ina-config!
   ina-wait  7 invert and  2/  ( mV )
;
: ina-get-i  ( -- uA )
   ina-base-mode +shunt ina-config!
   ina-wait  drop               ( )
   ina-shunt-voltage@ #100 *    ( uA )
;

: .ina  ( -- )
   ina-get-v&i  ." Bus " swap  .d  ." mV  "
   ." Shunt "  .d ." uA"  cr
;
: .current    ( -- )   begin  ina-get-i  .d (cr  key?  until  ;
