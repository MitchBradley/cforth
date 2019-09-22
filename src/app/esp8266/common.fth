\ Common code that most ESP8266 app will need

fl ../../lib/misc.fth
fl ../../lib/dl.fth

warning @ warning off
: bye standalone?  if  restart  then  bye  ;
warning !
: ms  ( msecs -- )  start-ms rest  ;

: relax  ( -- )  1 ms  ;  \ Give the system a chance to run

\ Long-running words like "words" can cause watchdog resets unless
\ we return to the OS periodically.
: paused-exit?  ( -- flag )  standalone?  if  relax  then  key?  ;
' paused-exit? to exit?

\ m-emit is defined in textend.c
alias m-key  key
alias m-init noop

: m-avail?  ( -- false | char true )
   key?  if  key true exit  then
   relax
   false
;
alias get-ticks timer@
: ms>ticks  ( ms -- ticks )  #1000 *  ;

fl xmifce.fth
fl ../../lib/crc16.fth
fl ../../lib/xmodem.fth

fl files.fth

: .commit  ( -- )  'version cscount type  ;
: .built  ( -- )  'build-date cscount type  ;
: banner  ( -- )
   cr ." CForth built " .built  ."  from " .commit cr
;

alias id: \

: interrupt?  ( -- flag )
   ." Type a key within 2 seconds to interact" cr
   #20 0  do  key?  if  key drop  true unloop exit  then  #100 ms  loop
   false
;

fl gpio.fth

: load-startup-file  ( -- )  " start" included   ;
