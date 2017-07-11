\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth

fl ../../platform/arm-teensy3/timer.fth
fl ../../platform/arm-teensy3/pcr.fth
fl ../../platform/arm-teensy3/i2c.fth
fl ../../platform/arm-teensy3/gpio.fth
fl ../../platform/arm-teensy3/nv.fth

: be-in      0 swap m!  ;
: be-out     1 swap m!  ;
: be-pullup  2 swap m!  ;

: go-on      1 swap p!  ;
: go-off     0 swap p!  ;

: wait  ( ms -- )
   get-msecs +
   begin
      dup get-msecs - 0<  key?  or
   until
   drop
;

: lb
   d be-out  e be-out
   begin
      d go-on  d# 125 wait  d go-off
      e go-on  d# 125 wait  e go-off
      key?
   until
;

\ tsl2561 luminosity sensor
: .tsl
   h# 39 i2c-open
   3 80 i2c-reg! \ power up sensor
   d# 402 ms \ nominal integration time
   h# 8c i2c-reg@ h# 8d i2c-reg@ bwjoin . \ ADC channel 0
   h# 8e i2c-reg@ h# 8f i2c-reg@ bwjoin . \ ADC channel 1
   0 80 i2c-reg! \ power down sensor
   i2c-close
;

\ blink the led
: go
   $1 $d m!  $1 $d p!   \ mode output, drive on
   #10 ms		\ pause
   $0 $d p!  $0 $d m!   \ drive off, mode input
;

\ to prevent execution of non-volatile buffer, tie pin 13 to pin 14.
: confirm?  ( -- flag )
   $0 $e m!                     \ set pin 14 to input
   $1 $d m!  $1 $d p!  $2 ms    \ force pin 13 high
   $e p@                        \ read pin
   $0 $d p!  $2 ms              \ force low
   $e p@ 0=                     \ read pin and invert
   and 0=
;

: .commit  ( -- )  'version cscount type  ;

: .built  ( -- )  'build-date cscount type  ;

: banner  ( -- )
   cr ." CForth built " .built
   ."  from " .commit
   cr
;

: app
   confirm?  if  go  nv-evaluate  then
   banner
   hex quit
;

" app.dic" save
