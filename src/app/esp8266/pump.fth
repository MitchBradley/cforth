\ Control a speaker-based pump connected to a DRV8388 motor driver
\ chip via GPIOs as follows:
\
\ DRV8388 NodeMCU ESP8266
\ Signal  Pin     GPIO
\
\ SLP_    D2      4
\ PH      D3      0
\ EN      D4      2

decimal

2 constant slp-pin  \ Pull low to tri-state motor driver
3 constant ph-pin   \ Selects polarity of motor drive
4 constant en-pin   \ Turns motor drive off (0) or on (1)

: gpio-is-output  ( pin -- )  nopull gpio-output  rot  gpio-mode  ;

: init-pump  ( -- )
   slp-pin gpio-is-output
   en-pin gpio-is-output
   ph-pin gpio-is-output
   0 ph-pin gpio-pin!
   0 en-pin gpio-pin!
   1 slp-pin gpio-pin!  \ SLP_ is active low
;

#5 value seconds   \ How long to run the pump
#10 value frequency \ How fast to pulse the pump, in Hertz

: safe-frequency  ( -- hertz )  frequency  1 max  #500 min  ;
: dly  ( -- )  #500  safe-frequency  /  ms  ;
: pump  ( -- )
   init-pump
   1 en-pin gpio-pin!
   seconds safe-frequency *  0  ?do
      1 ph-pin gpio-pin! dly
      0 ph-pin gpio-pin! dly
   loop
   0 en-pin gpio-pin!
;
