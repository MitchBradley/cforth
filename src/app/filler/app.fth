\ Load file for bucket filler
\ Pin Assignment
\
\ Buzzer


\ : fl safe-parse-word 2dup type cr included ;
fl ../esp8266/common.fth

fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

fl ../esp8266/wifi.fth

fl ../esp8266/tcpnew.fth

fl ../../lib/redirect.fth
fl ../esp8266/sendfile.fth
fl ../esp8266/server.fth

: init-pwm  ( freq pin -- )
   0 0 pwm_init  \ Arguments ignored  ( freq pin )
   0 rot pwm_set_freq                 ( pin )
   0 gpio-output 2 pick gpio-mode     ( pin )
   pwm_add
;

8 constant buzzer-pin
: init-buzzer  ( -- )  #1000 buzzer-pin init-pwm  ;
: buzzer-on  ( -- )  buzzer-pin #500 pwm_set_duty pwm_start  ;
: buzzer-off  ( -- )  buzzer-pin 0 pwm_set_duty pwm_start  ;
: beep  ( ms -- )  buzzer-on  ms  buzzer-off  ;

3 constant switch-pin
: init-switch  ( -- )
   true gpio-input switch-pin gpio-mode
;
: switch?  ( -- flag )
   switch-pin gpio-pin@ 0=
;
: wait-switch-released  ( -- )
   begin  1 ms  switch? 0= until
;

6 constant sensor-pin
: init-sensor  ( -- )
   true gpio-input sensor-pin gpio-mode
;
: immersed?  ( -- flag )  sensor-pin gpio-pin@   ;

7 constant relay-pin
: init-relay  ( -- )
   false gpio-output relay-pin gpio-mode
;
: relay-on  ( -- )  1 relay-pin gpio-pin!  ;
: relay-off  ( -- )  0 relay-pin gpio-pin!  ;

: run-cycle  ( -- )
   relay-on
   wait-switch-released

   begin  switch? 0=  immersed?  and  while
      #50 ms
   repeat

   relay-off
   #2000 beep
;

: run  ( -- )
   init-buzzer
   init-switch
   init-sensor
   init-relay

   begin
      switch?  if
         immersed?  0=  if
            #200 beep  #200 ms  #200 beep
         else
            run-cycle
         then
      then
      #50 ms
   key? until
;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
\ : app  banner  hex init-i2c  showstack  quit  ;

: app
   banner  hex
   interrupt?  if  quit  then
   ['] run catch .error
   quit
;


" app.dic" save
