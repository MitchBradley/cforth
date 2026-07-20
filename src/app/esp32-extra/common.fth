\ Load file for application-specific Forth extensions
fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

warning @ warning off
: bye standalone?  if esp-wifi-stop restart  then  bye  ;
warning !

: .commit ( -- )  'version cscount type  ;

: .built  ( -- )  'build-date cscount type  ;

: banner  ( -- )   cr ." CForth under ESP-IDF V5.5.1, " .built
   ."  from, " .commit 
   cr
;

\ m-emit is defined in textend.c
alias m-key  key
alias m-init noop

: m-avail?  ( -- false | char true )
   key?  if  key true exit  then
   false
;

: ms>ticks ( ms -- ticks ) get-tick-rate-hz / ;

: system-time>f ( us seconds -- ) ( f: -- us )
   s" s>d d>f f# 1.0e6 f*  s>d d>f  f+ "  evaluate
; immediate

: usf@ ( f: -- us )
   s" 0. sp@ get-system-time! system-time>f" evaluate  ; immediate

: ms@  ( -- ms ) f# 1.0e-3 usf@ f* f>d d>s  ;

alias get-msecs ms@

: fus  ( f: us - )
   usf@  f+  begin
      fdup  usf@  f- f# 1.0e8 f>
   while   #100000000 us
   repeat
   usf@  f- f>d d>s abs us
;

: ms   ( ms -- )   s>d d>f f# 1.0e3 f* fus ;

0 [if] \ In case you need it.
fl ../esp8266/xmifce.fth
fl ../../lib/crc16.fth
fl ../../lib/xmodem.fth
also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous
[then]

fl files.fth
fl mcpwm.fth
fl espnow.fth 
fl adc_esp32.fth
fl tools/extra.fth
fl wifi.fth                \ Use logon
fl i2c.fth
fl server.fth
fl tools/timezones.fth     \ Set your own timezone
fl tools/timediff.fth      \ Time calculations.
fl tools/webcontrols.fth   \ Extra tags and html parser
fl tools/transfer.fth      \ Much faster than xmodem. Use: transfer

: interrupt?  ( -- flag )
   ." Type a key within 2 seconds to interact" cr
   #20 0  do  #100 ms  key?  if  key drop  true unloop exit  then   loop
   false
;

: load-startup-file  ( -- ior )   " start" ['] included catch   ;

: app ( - )
   1 s" *" log-level! banner interrupt? hex 0= if
      s" start" file-exist? if
         load-startup-file drop
      then
   then
   quit
;
alias id: \

" app.dic" save
