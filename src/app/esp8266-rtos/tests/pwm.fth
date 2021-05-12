\ Test for ESP8266 RTOS PWM
1 constant #pwm-channels
create pwm-pins gpio13 ,
#2000 constant pwm-period
create pwm-duties #1000 ,

: init-pwm  ( -- )
   pwm-pins #pwm-channels pwm-duties pwm-period pwm-init
   0 0 pwm-phase!
;
: pwm-for-1  ( duty -- )  0 pwm-duty! pwm-start  #1000 ms  pwm-stop  ;
: test-pwm  ( -- )
   init-pwm
   begin
           0 pwm-for-1
        #500 pwm-for-1
       #1000 pwm-for-1
       #1500 pwm-for-1
       #2000 pwm-for-1
   key? until
   pwm-stop
;
