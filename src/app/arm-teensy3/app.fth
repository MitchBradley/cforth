\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

1 [if]
fl gpio.fth
fl adcpins.fth

2 constant valve-gpio
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

fl ph.fth    \ pH probe via ADC
fl pump.fth  \ Pump controller via GPIOs and motor driver

: init-i2c  ( -- )  #10 9 i2c-setup  ;

\ I2C devices
fl ina219.fth
fl mcp23008.fth
fl mcp23017.fth
fl fixture.fth
fl ../bluez/colors.fth
fl ../bluez/rgblcd.fth
fl ../esp8266/pca9685.fth
fl ../esp8266/ms5803.fth
fl ../esp8266/bme280.fth
fl ../esp8266/vl6180x.fth
fl ../esp8266/ads1115.fth \ Possibly unnecessary since Teensy3 has good ADCs
fl sht21.fth

fl ../esp8266/ds18x20.fth  \ Onewire temperature probe
#23 to ds18x20-pin  \ Needs 4.7K pullup

: pump-setup  ( -- )
   valve-gpio #gpios  bounds  do  0 i gpio-pin!  i gpio-is-output  loop
;

fl ../../cforth/printf.fth
fl esp8266_at.fth
fl ec.fth
fl pump-ctl.fth


\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  ." CForth" cr decimal  pump-setup  init-i2c quit  ;
[else]
: app ." CForth" cr decimal  quit  ;
[then]
" app.dic" save
