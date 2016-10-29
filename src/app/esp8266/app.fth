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

fl wifi.fth

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
   init-i2c
   ['] load-startup-file catch drop
   quit
;

alias id: \

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

" app.dic" save
