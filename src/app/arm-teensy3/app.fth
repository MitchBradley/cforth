\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth

#0 ccall: spins       { i.nspins -- }
#1 ccall: wfi         { -- }
#2 ccall: get-msecs   { -- n }
#3 ccall: a@          { i.pin -- n }
#4 ccall: p!          { i.val i.pin -- }
#5 ccall: p@          { i.pin -- n }
#6 ccall: m!          { i.mode i.pin -- }
#7 ccall: get-usecs   { -- n }
#8 ccall: delay       { n -- }
#9 ccall: bye         { -- }
#10 ccall: /nv        { -- n }
#11 ccall: nv-base    { -- n }
#12 ccall: nv-length  { -- n }
#13 ccall: nv@        { i.adr -- i.val }
#14 ccall: nv!        { i.val i.adr -- }

fl ../../platform/arm-teensy3/watchdog.fth
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

\ to prevent execution of non-volatile buffer, tie pin 13 to ground.
: confirm?  ( -- flag )
   $0 $d m!  $1 $d p!  $2 ms    \ mode input, pullup on, stabilise
   $d p@                        \ read pin
   $1 $d m!  $0 $d p!           \ mode output, force low
;

: app
   confirm?  if  go  nv-evaluate  then
   ." CForth" cr hex quit
;

" app.dic" save
