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
also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

fl ../esp32/files.fth

fl ../esp32/server.fth

: relax ;

fl tests/oled.fth

\ Jos: 1 line added
fl tasking_rtos.fth  \ Pre-emptive multitasking

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
\ : app  banner  hex init-i2c  showstack  quit  ;
: interrupt?  ( -- flag )
   ." Type a key within 1 second to interact" cr \ changed to 1 second
   #10 0  do  key?  if  key drop  true unloop exit  then  #100 ms  loop \ 1 second

\   ." Type a key within 2 seconds to interact" cr  \ Original
\   #20 0  do  key?  if  key drop  true unloop exit  then  #100 ms  loop \ Original

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
