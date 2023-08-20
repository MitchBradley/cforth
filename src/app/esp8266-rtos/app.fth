\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

warning @ warning off
: bye standalone?  if  restart  then  bye  ;
warning !

: .commit  ( -- )  'version cscount type  ;

: .built  ( -- )  'build-date cscount type  ;

: banner  ( -- )
   cr ." CForth built " .built
   ."  from " .commit
   cr
;

fl gpio.fth

\ m-emit is defined in textend.c
alias m-key  key
alias m-init noop

: m-avail?  ( -- false | char true )
   key?  if  key true exit  then
   false
;
alias get-ticks get-msecs
: ms>ticks  ( ms -- ticks )  ;

fl ../esp32/wifi.fth

fl ../esp8266/xmifce.fth
fl ../../lib/crc16.fth
fl ../../lib/xmodem.fth
fl ../../lib/mcp23017.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

fl ../esp32/files.fth

\ fl ../esp8266-rtos/server.fth
fl ../esp32/server.fth

: relax ;

\ fl tests/oled.fth

fl tasking_rtos.fth          \ Pre-emptive multitasking
fl ../esp/extra.fth
fl ../esp/timediff.fth     \ Time calculations. The local time was received from a RPI
fl ../esp/webcontrols.fth  \ Extra tags in ROM

\ Optional:
fl ../esp/rcvfile.fth
fl ../esp/wsping.fth

\ 211:
fl tests/spi.fth
fl tests/spi_ledstrip_apa201.fth
fl ../esp8266_jos/ledstrip_plotter.fth
fl ../esp8266_jos/squares.fth

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
\ : app  banner  hex init-i2c  showstack  quit  ;
: interrupt?  ( -- flag )
   ." Type a key within 2 seconds to interact" cr
   #20 0  do  key?  if  key drop  true unloop exit  then  #100 ms  loop
   false
;

: load-startup-file  ( -- )  " start" included   ;

: app
   banner  hex
   interrupt?  if  quit  then
   ['] load-startup-file catch drop
   quit
;

alias id: \

" app.dic" save
