\ Load file for application-specific Forth extensions
\ This particular one is sort of a "kitchen sink" build
\ with a bunch of drivers for various sensors.

fl ../esp8266/common.fth
fl ../../lib/random.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

fl ../esp8266/wifi.fth

fl ../../lib/redirect.fth
fl ../esp8266/tcpnew.fth

fl ../../lib/url.fth

: init-i2c  ( -- )  8 3 i2c-setup  ;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
\ : app  banner  hex init-i2c  showstack  quit  ;
create relay-gpio-map  \ Indexed by relay number 1..8
\ Relay#  1    2    3    4    5    6    7
( gpio#)  1 c, 2 c, 0 c, 5 c, 6 c, 7 c, 4 c,

: >relay-gpio#  ( relay#1..7 -- gpio# )  1- relay-gpio-map + c@  ;

\ We set D8 to output mode to change it from open drain (the usual
\ I2C mode) to totem-pole because D8 has a 12K pulldown that
\ interferes with I2C signaling.  D8 is the I2C clock line which
\ is okay with totem-pole drive, so long as you don't need to use
\ clock stretching.  I2C data must be open drain.
\ We can't use a strong pullup to overdrive the 12K pulldown because
\ the D8 line is sampled during ROM startup to choose the boot mode.

: keg-init-i2c  ( -- )  8 3 i2c-setup  false gpio-output 8 gpio-mode  ;

: relay-off  ( relay# -- )  >relay-gpio#  true swap gpio-pin!  ;
: relay-on   ( relay# -- )  >relay-gpio#  false swap gpio-pin!  ;
: init-relay  ( relay# -- )
   dup relay-off
   false gpio-output rot >relay-gpio# gpio-mode
;
: init-relays  ( -- )  8 1  do  i init-relay  loop  ;

fl ../../lib/colors.fth
fl ../../lib/mcp23017.fth
fl ../../lib/rgblcd.fth
: init-all  ( -- )
   keg-init-i2c
   init-relays
   init-lcd
   home-lcd
   lcd-magenta  " Ready" 0 0 lcd-type-at
;

: load-startup-file  ( -- )  " start" included   ;

: app
   banner  hex
   interrupt?  if  quit  then
   init-i2c
   ['] load-startup-file catch drop
   quit
;

" app.dic" save
