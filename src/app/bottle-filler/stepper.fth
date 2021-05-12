\ Stepper motor driver

\ Needs:  dir-pin, step-pin

false value schedule-done?

false value limited?
: stepper-wait  ( -- )
   begin  #50 ms  schedule-done?  until
   limited?  if
      ." LIMIT" cr
      false to limited?
   then
;

0 value step-interval

: step  ( -- )  
   0 step-pin gpio-pin!
   2 us
   1 step-pin gpio-pin!
;

0 value tcounts
0 value tmin
0 value tmax
0 value @step-ramp
0 value alpha
#160 value alpha0
#7 value delta-alpha

\ This is an approximation to a linear ramp whereby the amount to
\ adjust the interval is a constant percentage of the current interval.
\ It is simple and works fairly well.
: +adjust  ( interval -- interval adjust )
   dup alpha #1000 */  1 max
   alpha delta-alpha -  0 max to alpha
;
: -adjust  ( interval -- interval adjust )
   dup alpha #1000 */  1 max
   alpha delta-alpha +  alpha0 min to alpha
;

: stop-stepping  ( -- )
   @step-ramp  0  set-alarm-us
   true to schedule-done?
;
false value pulloff?

-1 value limit-pin
: limit?  ( -- flag )
   limit-pin -1 =  if  false exit  then
   limit-pin gpio-pin@ 0=
;
: step-ramp  ( -- )
   limit?  pulloff? 0= and  if
      true to limited?
      stop-stepping exit
   then
   tcounts  if
      \ Accelerating or cruising
      step-interval tmin >  if
          \ Accelerate until min interval reached
          step-interval +adjust - to step-interval
      else
          \ Cruise until tcounts expires
         tcounts 1- to tcounts
      then
   else
      \ Decelerating or stop
      step-interval tmax <  if
         \ Decelerate until max interval reached
         step-interval -adjust + to step-interval
      else
         \ Stop at max interval
         stop-stepping
         exit
      then
   then
   @step-ramp  step-interval  set-alarm-us
   step
;

: ramp  ( max min counts -- )
   alpha0 to alpha
   false to schedule-done?
   ['] step-ramp to @step-ramp
   to tcounts  to tmin  to tmax
   tmax to step-interval
   step-ramp
;

: set-dir  ( cw? -- )  dir-pin gpio-pin!  ;

: init-stepper  ( -- )
   false gpio-output dir-pin gpio-mode
   false gpio-output step-pin gpio-mode
;


#30000 value bottle-distance
#300 value backoff-distance
#400 value seek-distance
#3800 value initial-distance
: lift-down  ( -- )  select-lift  0 set-dir  ;
: lift-up  ( -- )  select-lift  1 set-dir  ;

: ramp-wait  ( max min counts -- )  ramp stepper-wait  ;
: go-down  ( -- )
   lift-down  #2000 #80 bottle-distance ramp-wait
;
: go-up  ( -- )
   lift-up  #2000 #80 bottle-distance ramp-wait
;
: bump-up  ( -- )
   lift-up  #2000 #200 bottle-distance #100 / ramp-wait
;
: bump-down  ( -- )
   lift-down  #2000 #200 bottle-distance #100 / ramp-wait
;

: homing-backoff  ( -- )
   limit?  if
      true to pulloff?  
      lift-up  #2000 #1000 backoff-distance ramp-wait
      limit? abort" Limit switch is stuck"
   then
   false to pulloff?
;
: ?limit-released  ( -- )  limit?  abort" Limit switch did not release"  ;

: ?limit-engaged  ( -- )  limit?  0= abort" Limit switch did not engage"  ;

: home-lift  ( -- )
   limit-pin -1 =  abort" No limit switch; can't home"
   homing-backoff
   \ Limit switch is now inactive
   lift-down  #2000 #80 bottle-distance 3 2 */ ramp-wait
   ?limit-engaged
   homing-backoff
   ?limit-released
   lift-down  #2000 #1000 seek-distance ramp-wait
   ?limit-engaged
   homing-backoff
   ?limit-released   
   lift-up  #2000 #80 initial-distance ramp-wait
;

0 [if]

0 value 'schedule
create null-schedule 0 ,

variable remaining-steps

0 value @step-handler

: next-step  ( -- )
   @step-handler  step-interval  set-alarm-us
   step
   -1 remaining-steps +!
;
: next-segment  ( -- )
   'schedule @ dup  remaining-steps !   ( #steps )
   if
      'schedule cell+ @ to step-interval
      'schedule 2 cells +  to 'schedule
      next-step
   else
      ['] noop  0 set-alarm-us
      true to schedule-done?
   then
;
: step-handler  ( -- )
   remaining-steps @  if  next-step  else  next-segment  then
;

: run-schedule  ( schedule -- )
   to 'schedule
   ['] step-handler to @step-handler
   false to schedule-done?
   next-segment
;

3 cells buffer: one-segment
: steps  ( #steps interval-us cw? -- )
   set-dir              ( #steps interval-us )
   one-segment na1+ !   ( #steps )
   one-segment !        ( )
   one-segment run-schedule
;
: steps-cw  ( #steps interval-us -- )  1 steps  ;
: steps-ccw  ( #steps interval-us -- )  0 steps  ;
: u  1 set-dir  ;
: dn  0 set-dir  ;

: schedule:   ( "name" -- )
   create  does> run-schedule
;
schedule: one-rev
   #100 , #400 ,
   #300 , #200 ,
   #800 , #130 ,
   #300 , #200 ,
   #100 , #400 ,
   0 ,

schedule: fast-ramp
    #50 , #1600 ,
   #150 ,  #800 ,
   #100 ,  #400 ,
   #100 ,  #200 ,
 #10000 ,  #130 ,
   #100 ,  #200 ,
   #100 ,  #400 ,
   #150 ,  #800 ,
    #50 , #1600 ,
      0 ,

schedule: rev-1.5
    #25 , #2400 ,
    #25 , #2200 ,
    #25 , #2000 ,
    #25 , #1850 ,
    #50 , #1700 ,
    #50 , #1500 ,
    #50 , #1400 ,
    #50 , #1300 ,
  #1800 , #1200 ,
   #200 , #1600 ,
   #100 , #2400 ,
      0 ,
[then]

\ init-stepper
