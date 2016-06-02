\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

warning @ warning off  : bye restart ;  warning !
: ms  ( msecs -- )  start-ms rest  ;

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
: rx  ( -- )  pad  unused here pad - -  (receive)  #100 ms  ;
previous

: .ssid  ( -- )  pad wifi-ap-config@ drop pad cscount type  ;
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

: http-get?  ( req$ -- false | url$ true )
   over " GET " comp 0=  if        ( req$ )
      4 /string                    ( req$' )  \ Lose "GET "
      bl split-string  2drop true  ( url$ true )
   else                            ( adr len )
      false                        ( req$ false )
   then
;

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

: init-all  ( -- )
   ['] init-vl6180x catch  if  ." VL6180x init failed" cr  then
   ['] init-ds18x20 catch  if  ." DS18x20 init failed" cr  then
   ['] init-ads     catch  if  ." ADS1115 init failed" cr  then
   ['] init-bme     catch  if  ." BME280 init failed" cr  then
   ['] init-pca     catch  if  ." PCA9685 init failed" cr  then
   ['] init-hcsr04  catch  if  ." HC-SR04 init failed" cr  then
;

fl server.fth

fl car.fth

\ Measures NTC thermistor on channel 2 pulled up with 10K
\ against 2:1 voltage divider on channel 3.
: ads-temp@  ( -- n )  3 ads-channel@ w->n  ;

: init-i2c  ( -- )  3 4 i2c-setup  ;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  ." CForth" cr hex init-i2c  quit  ;

\ " ../objs/tester" $chdir drop

" app.dic" save
