\ Load file for application-specific Forth extensions

fl ../esp32/common.fth

fl ../../sensors/hx711.fth
#18 to hx711-dout-pin
#19 to hx711-sck-pin

5 constant liquid-solenoid-pin
4 constant gas-solenoid-pin
2 constant stepper-enable-pin
#17 constant lift-step-pin
#16 constant lift-dir-pin
#27 constant gas-step-pin
#25 constant gas-dir-pin

0 value step-pin
0 value dir-pin
: select-lift  ( -- )
   lift-step-pin to step-pin
   lift-dir-pin to dir-pin
;
: select-gas  ( -- )
   gas-step-pin to step-pin
   gas-dir-pin to dir-pin
;

fl stepper.fth
#23 to limit-pin

#34 constant pressure-sensor-pin
pressure-sensor-pin #32 - constant pressure-sensor-adc-channel

\ typedef enum {
\     ADC_0db = 0,  ADC_2_5db = 1,  ADC_6db = 2,  ADC_11db = 3
\ } adc_attenuation_t;

: pin-high  ( pin# -- )  1 swap gpio-pin!  ;
: pin-low   ( pin# -- )  0 swap gpio-pin!  ;

: liquid-on  ( -- )  liquid-solenoid-pin pin-high  ;
: liquid-off ( -- )  liquid-solenoid-pin pin-low  ;
: gas-on     ( -- )  gas-solenoid-pin    pin-high  ;
: gas-off    ( -- )  gas-solenoid-pin    pin-low  ;
: motors-on  ( -- )  stepper-enable-pin  pin-low  ;
: motors-off ( -- )  stepper-enable-pin  pin-high  ;

: pressure@  ( -- n )
   pressure-sensor-adc-channel adc@
   \ XXX Convert to useful units
;

: relax  ;

fl ${CBP}/lib/fb.fth
fl ${CBP}/lib/font5x7.fth
fl ${CBP}/lib/ssd1306.fth
: init-wemos-oled  ( -- )
   #22 #21 i2c-open abort" I2C open failed"
   ssd-init
;

: test-wemos-oled  ( -- )
   init-wemos-oled
   #20 0  do  i (u.)  fb-type "  Hello" fb-type  fb-cr  loop
;

: fb-line-at-xy  ( adr len x y -- )
   2dup fb-at-xy   ( adr len x y )
   2swap fb-type   ( x y )
   \ Erase the rest of the line unless we are already
   \ on the next line.
   nip  line# =  if  ( )
      #columns column#  ?do  bl fb-emit  loop  ( )
   then              ( )
;

: init  ( -- )
   decimal
   init-wemos-oled
   liquid-solenoid-pin gpio-is-output
   gas-solenoid-pin gpio-is-output
   stepper-enable-pin gpio-is-output
   lift-step-pin gpio-is-output
   lift-dir-pin gpio-is-output
   gas-step-pin gpio-is-output
   gas-dir-pin gpio-is-output
   hx711-dout-pin gpio-is-input-pullup
   hx711-sck-pin gpio-is-output
   limit-pin gpio-is-input-pullup

   2 adc-width!  \ 11-bit precision
   3 pressure-sensor-adc-channel adc-atten!  \ 11dB attenuation - range from 0 - 3.2V

   init-hx711
   #124 to hx711-divisor  \ Divisor for grams
   -1 to hx711-polarity

   init-stepper
   select-gas
   motors-on
   "   FILLER" 0 0 fb-line-at-xy
;
#200 value empty-bottle-low-grams  \ Nominal is 250g
#300 value empty-bottle-high-grams
#700 value full-bottle-grams       \ Nominal is 750g
: hx711-grams  ( -- n )  hx711-sample hx711-divisor /  ;
: .bottle  ( adr len -- )  2dup type cr  0 2 fb-line-at-xy  ;
: .grams  ( grams -- )  
   (.d) 2dup type cr
   0 1 fb-line-at-xy
;
: sense-weight  ( -- n )   hx711-grams  dup .grams  ;
: sense-bottle  ( -- state )  \ 0, 1, 2, 3
   sense-weight    ( grams )

   dup empty-bottle-low-grams <  if
      drop " NONE" .bottle
      0 exit
   then
   dup empty-bottle-high-grams < if
      drop " Empty" .bottle
      1 exit
   then
   dup  full-bottle-grams <  if
      drop " Filling" .bottle
      2 exit
   then
   drop " Full" .bottle
   3
;
: show-action  ( msg$ -- )  2dup type cr  0 4 fb-line-at-xy  ;
: wait-full  ( -- )
   begin  key? if key drop abort then  sense-bottle 3 = until
;
: wait-removed  ( -- )
   " REMOVE" show-action
   begin  key? if key drop abort then  sense-bottle 0 = until
;
: purge  ( -- )
   " PURGE" show-action
   gas-on #4000 ms  gas-off
;
: control-backpressure  ( -- )
;

#20 value seal-counts
0 value seal-total
: creep-up  ( -- )
   lift-up  #2000 #2000  seal-counts ramp-wait
   seal-total seal-counts + to seal-total
;
: seal  ( -- )
   " SEAL" show-action
   0 to seal-total
   sense-weight  #100 +  ( target-weight )
   begin          ( target-weight )
      creep-up    ( target-weight )
      dup sense-weight  <  ( target-weight reached? )
   until          ( target-weight )
   drop
;
: unseal  ( -- )
   " UNSEAL" show-action
   lift-down  #2000 #2000  seal-total ramp-wait
;

#10000 value liquid-ms
: fill-bottle  ( -- )
   " FILL" show-action
   liquid-on  
   get-msecs liquid-ms +   ( limit-time )
   begin                   ( limit-time )
      #500 ms
      control-backpressure ( limit-time )
      dup get-msecs - 0<   ( limit-time exit? )
      sense-bottle 3 = or  ( limit-time exit? )
   until                   ( limit-time )
   drop
   liquid-off
;
: run
   " HOME" show-action
   home-lift   
   " TARE" show-action
   hx711-tare
   
   " PLACE" show-action
   begin
      sense-bottle 1 =  if
         #300 ms  sense-bottle 1 =  if
            go-up
            purge
            seal
            fill-bottle
            wait-full
            unseal
            go-down
            wait-removed
            " PLACE" show-action
         then
      then

      \ wait for bottle or switch, while tare-ing
      \ Lift bottle to near the top - dead reckoning to
      \ near the bung
      \ Close the CO2 valve
      \ Open the CO2 valve for a timed burst to purge
      \ Lift carefully until the force increases
      \ Close the relief valve a little
      \ Open the CO2 valve
      \ Back off the relief valve until the pressure decreases to a setpoint
      \ Open the product valve
      \ When the pressure increases, back off the valve a bit
      \ Watch for stop switch and also run timer - when timer expires
      \ or switch it is pressed, close the product valve.
      \ If pulse switch is pressed, open product valve briefly
      \ When down switch is pressed, drop bottle
   key? until
   \ again
;

: app
   banner  hex
   interrupt?  if  quit  then
   ['] load-startup-file catch drop
   init
   run
   quit
;

alias id: \

" app.dic" save
