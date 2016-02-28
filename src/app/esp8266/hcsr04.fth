\ Driver for HC-SR04 ultrasonic distance sensor

6 constant trigger-pin
7 constant echo-pin

0 value echo-start
0 value echo-end
0 value good-echo?

: echo-cb  ( level -- )
   timer@  swap  if  ( time )
      to echo-start  ( )
      gpio-int-negedge echo-pin gpio-enable-interrupt
   else              ( time )
      to echo-end    ( )
      true to good-echo?
   then
;
: echo-end-cb  ( level -- )
   drop timer@ to echo-end
   true to good-echo?
;
: echo-start-cb  ( level -- )
   drop timer@ to echo-start
   ['] echo-end-cb echo-pin gpio-callback!
   gpio-int-negedge echo-pin gpio-enable-interrupt
;
: hcsr04-trigger  ( -- )
   ['] echo-cb echo-pin gpio-callback!
   gpio-int-posedge echo-pin gpio-enable-interrupt
   1 trigger-pin gpio-pin!
   #60 us
   0 trigger-pin gpio-pin!
;
: hcsr04-distance  ( -- false | mm true )
   false to good-echo?
   hcsr04-trigger
   #10 0  do
      good-echo?  if  leave  then
      1 ms
   loop

   good-echo?  if
      echo-end echo-start -     ( us )
      #1765 #10000 */           ( mm )
      true
   else
      0 gpio-int-disable echo-pin gpio-enable-interrupt
      false
   then
;
: init-hcsr04  ( -- )
   false gpio-output trigger-pin gpio-mode 
   true gpio-interrupt echo-pin gpio-mode
;

: .hcsr04-distance  ( -- )
   hcsr04-distance  if  .d ." mm"  else  ." No echo"  then
;
