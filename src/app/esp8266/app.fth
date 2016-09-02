\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

warning @ warning off
: bye standalone?  if  restart  then  bye  ;
warning !
: ms  ( msecs -- )  start-ms rest  ;

\ Long-running words like "words" can cause watchdog resets unless
\ we return to the OS periodically.
: paused-exit?  ( -- flag )  standalone?  if  1 ms  then  key?  ;
' paused-exit? to exit?

\ m-emit is defined in textend.c
alias m-key  key
alias m-init noop

: m-avail?  ( -- false | char true )
   key?  if  key true exit  then
   1 ms
   false
;
alias get-ticks timer@
: ms>ticks  ( ms -- ticks )  #1000 *  ;

fl xmifce.fth
fl ../../lib/crc16.fth
fl ../../lib/xmodem.fth
also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

: .ssid  ( -- )
   pad wifi-ap-config@ drop
   pad  pad #96 + c@  type
   pad #32 + c@  if  ." Password: " pad #32 + cscount type  then
   \ pad+96.b is ssid_len
   \ pad+97.b is channel
   \ pad+100.l is auth_mode
   \ pad+104.b is hidden
   \ pad+105.b is max_connection
   \ pad+106.w is beacon_interval
;
: ipaddr@  ( -- 'ip )  pad 1 wifi-ip-info@ drop  pad  ; \ 1 for AP, 0 for STA
: (.d)  ( n -- )  push-decimal (.) pop-base  ;
: .ipaddr  ( 'ip -- )
   3 0 do  dup c@ (.d) type ." ." 1+  loop  c@ (.d) type
;
: .ip/port  ( adr -- )
   dup 0=  if  drop ." (NULL)" exit  then
   ." Local: " dup 2 la+ .ipaddr ." :" dup 1 la+ l@ .d
   ." Remote: " dup 3 la+ .ipaddr ." :" l@ .d
;
0 [if]
: .conntype  ( n -- )
   case  0 of  ." NONE"  endof  $10 of  ." TCP" endof  $20 of ." UDP" endof  ( default ) dup .x endcase
;
: .connstate  ( n -- )
   case  0 of ." NONE" endof 1 of ." WAIT" endof 2 of ." LISTEN" endof 3 of ." CONNECT" endof
         4 of ." WRITE" endof 5 of ." READ" endof 6 of ." CLOSE" endof  dup .x
   endcase
;
: .espconn  ( adr -- )
   dup .  dup l@ .conntype space  dup 1 la+ l@ .connstate space dup 2 la+ l@ .ip/port  6 la+ l@ ." Rev: " .x cr
;
[then]

0 constant gpio-input
1 constant gpio-output
2 constant gpio-interrupt

0 constant gpio-int-disable
1 constant gpio-int-posedge
2 constant gpio-int-negedge
3 constant gpio-int-anyedge
4 constant gpio-int-lolevel
5 constant gpio-int-hilevel

fl files.fth
fl vl6180x.fth
fl ds18x20.fth
fl ads1115.fth
fl bme280.fth
fl pca9685.fth
fl hcsr04.fth


fl redirect.fth
fl tcpnew.fth

fl url.fth
\ fl serve-sensors.fth

fl car.fth

\ Measures NTC thermistor on channel 2 pulled up with 10K
\ against 2:1 voltage divider on channel 3.
: ads-temp@  ( -- n )  3 ads-channel@ w->n  ;

: init-i2c  ( -- )  3 4 i2c-setup  ;

: .commit  ( -- )  'version cscount type  ;

: .built  ( -- )  'build-date cscount type  ;

: banner  ( -- )
   cr ." CForth built " .built
   ."  from " .commit
   cr
;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  banner  hex init-i2c  quit  ;

alias id: \

\ Open Firmware stuff; omit if you don't need it
fl ../../ofw/objsup.fth
fl ../../ofw/objects.fth
fl ../../ofw/linklist.fth
fl ../../ofw/parses1.fth
fl ../../ofw/cirstack.fth
fl ../../ofw/ofw-dt.fth
fl ../../ofw/deblock.fth

" app.dic" save
