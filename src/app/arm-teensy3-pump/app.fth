\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

1 [if]
fl gpio.fth
fl adcpins.fth

2 constant water-gpio
3 constant spritz-gpio
4 constant recirc-gpio
5 constant nutrient-gpio
6 constant pH-up-gpio
7 constant pH-down-gpio
6 constant #gpios

[ifdef] float
\ Test for analogWrite to DAC0
decimal
3.1415926535E0 fconstant pi
pi 2E f* fconstant 2pi
2E-2 fvalue phaseinc

: sinewave  ( -- )
   ." Sine wave on DAC0 pin; type a key to stop" cr
   #12 analogWriteRes
   2pi
   begin        ( phase )
      fdup fsin 2000E0 f*  2050E0 f+
      int pinA14 analogWrite 
      phaseinc f-  fdup f0<  if  2pi f+  then
   key? until
   fdrop
;
[then]

: init-i2c  ( -- )  #10 9 i2c-setup  ;

fl ../../sensors/bme280.fth
fl ../../sensors/vl6180x.fth
fl ../../sensors/ads1115.fth \ Possibly unnecessary since Teensy3 has good ADCs

fl ../../sensors/ds18x20.fth  \ Onewire temperature probe
#23 to ds18x20-pin  \ Needs 4.7K pullup

: pump-setup  ( -- )
   water-gpio #gpios  bounds  do  0 i gpio-pin!  i gpio-is-output  loop
;

fl ph.fth    \ pH probe via ADC
fl pump.fth  \ Pump controller via GPIOs and motor driver
fl ../../cforth/printf.fth
fl esp8266_at.fth \ esp8266 HTTP server
fl ec.fth \ electrical conductivity sensor
fl pump-ctl.fth \ pump control state machine

: init-all
   pump-setup
   init-i2c
   init-vl6180x
   init-pump-ctl
   init-bme
   start-server
;

: main-loop
   1
   begin
     handle-request
     \ blah
     1- dup 0= if
       drop #500
       pump-ctl
       .pump-ctl
     then
     #1 ms
     key?
   until
   drop
   init-pump-ctl \ resets pumps
;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  ." CForth" cr decimal  pump-setup  init-i2c quit  ;
[else]
: app ." CForth" cr decimal  quit  ;
[then]
" app.dic" save
