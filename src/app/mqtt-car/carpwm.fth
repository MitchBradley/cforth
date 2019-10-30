0 constant LED-pin
2 constant left-speed-pin
1 constant right-speed-pin
4 constant left-direction-pin
3 constant right-direction-pin

: pwm-on  ( freq -- )
   0 0 pwm_init  \ Arguments ignored
   0 swap pwm_set_freq
;
: pwm-pin-on  ( pin -- )
   false gpio-output 2 pick gpio-mode  ( pin )
   pwm_add drop
;
: pwm  ( duty pin -- )  swap pwm_set_duty pwm_start  ;

: left-forward  ( -- )  1 left-direction-pin gpio-pin!  ;
: left-backward  ( -- )  0 left-direction-pin gpio-pin!  ;
: right-forward  ( -- )  0 right-direction-pin gpio-pin!  ;
: right-backward  ( -- )  1 right-direction-pin gpio-pin!  ;

: init-car  ( -- )
   0 gpio-output LED-pin gpio-mode
   0 gpio-output left-direction-pin gpio-mode
   0 gpio-output right-direction-pin gpio-mode
   \ freq #10 works at even lower duty cycle but it is jerky
   #20 pwm-on  \ The motors work at lower duty cycles with lower freq
   left-speed-pin pwm-pin-on
   right-speed-pin pwm-pin-on
   left-forward
   right-forward
;
: left-speed  ( duty -- )  left-speed-pin pwm  ;
: right-speed  ( duty -- )  right-speed-pin pwm  ;
: speed  ( duty -- )
   left-speed-pin over pwm_set_duty   ( pin )
   right-speed-pin swap pwm_set_duty  ( )
   pwm_start
;
\ Speed is negative to go backward
: motors  ( left-speed right-speed -- )
   dup 0<  if  right-backward negate  else  right-forward  then  ( lspeed |rspeed| )
   right-speed-pin swap pwm_set_duty              ( lspeed )
   dup 0<  if  left-backward negate  else  left-forward  then    ( |lspeed| )
   left-speed-pin swap pwm_set_duty               ( )
   pwm_start
;

: led-on  ( -- )  0 LED-pin gpio-pin!  ;
: led-off  ( -- )  1 LED-pin gpio-pin!  ;

: stop  0 speed  ;
: forward  ( speed -- )  left-forward right-forward speed  ;
: backward  ( speed -- )  left-backward right-backward speed  ;
