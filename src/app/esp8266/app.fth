\ Load file for application-specific Forth extensions
\ This particular one is sort of a "kitchen sink" build
\ with a bunch of drivers for various sensors.

fl common.fth

fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

\ fl ../../sensors/vl6180x.fth
fl ../../sensors/ds18x20.fth
fl ../../sensors/ads1115.fth
fl ../../sensors/bme280.fth
fl ../../sensors/pca9685.fth
fl hcsr04.fth

fl wifi.fth

fl tcpnew.fth

fl ../../lib/redirect.fth
fl sendfile.fth
fl server.fth

\ fl serve-sensors.fth
fl serve-hcsr04.fth

fl car2.fth

\ Measures NTC thermistor on channel 2 pulled up with 10K
\ against 2:1 voltage divider on channel 3.
: ads-temp@  ( -- n )  3 ads-channel@ w->n  ;

: init-i2c  ( -- )  3 4 i2c-setup  ;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
\ : app  banner  hex init-i2c  showstack  quit  ;

: app
   banner  hex
   interrupt?  if  quit  then
   init-i2c
   ['] load-startup-file catch drop
   quit
;

fl ${CBP}/lib/fb.fth
fl ${CBP}/lib/font5x7.fth
fl ${CBP}/lib/ssd1306.fth
: init-wemos-oled  ( -- )
   1 2 i2c-setup
   ssd-init
;
: test-wemos-oled  ( -- )
   init-wemos-oled
   #20 0  do  i (u.)  fb-type "  Hello" fb-type  fb-cr  loop
;

fl wemos-rgb-led.fth

0 [if]
\ Open Firmware stuff; omit if you don't need it
fl ${CBP}/ofw/loadofw.fth      \ Mostly platform-independent
fl ofw-rootnode.fth \ ESP8266-specific

fl sdspi.fth

-1 value hspi-cs   \ -1 to use hardware CS mode, 8 to use pin8 with software

' spi-transfer to spi-out-in
' spi-bits@    to spi-bits-in

: sd-init  ( -- )
   0 true #100000 hspi-cs spi-open
   ['] spi-transfer to spi-out-in
   ['] spi-bits@    to spi-bits-in
   sd-card-init
;
[then]

4 constant eth-cs-gpio  \ Depends on hardware wiring
\ The MAC address of my first-article Sun2 Ethernet card
create s2mac  8 c, 0 c, $20 c, 1 c, 2 c, $5b c,
: start-net  ( -- )
   s2mac eth-cs-gpio open-ethernet drop
;

" app.dic" save
