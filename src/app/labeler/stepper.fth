\ Stepper motor driver

\ Needs:  dir-pin, step-pin

0 value step-timer

false value schedule-done?
0 value 'schedule
create null-schedule 0 ,
variable remaining-steps
: step  ( -- )  
   0 step-pin gpio-pin!
   2 us
   1 step-pin gpio-pin!
   -1 remaining-steps +!
;
: next-segment  ( -- )
   'schedule @ dup  remaining-steps !   ( #steps )
   if
      'schedule cell+ @  0 1 step-timer arm-timer
      'schedule 2 cells +  to 'schedule
      step
   else
      step-timer disarm-timer
      true to schedule-done?
   then
;
: step-handler  ( -- )
   remaining-steps @  if
      step
   else
      next-segment
   then
;

: init-stepper  ( -- )
   false gpio-output dir-pin gpio-mode
   false gpio-output step-pin gpio-mode
   reinit-timer
\   ['] step-handler new-timer to step-timer
;

: run-schedule  ( schedule -- )
   false to schedule-done?
   to 'schedule
   next-segment
;

3 cells buffer: one-segment
: set-dir  ( cw? -- )  dir-pin gpio-pin!  ;
: steps  ( #steps interval-us cw? -- )
   set-dir              ( #steps interval-us )
   one-segment na1+ !   ( #steps )
   one-segment !        ( )
   one-segment run-schedule
;
: steps-cw  ( #steps interval-us -- )  1 steps  ;
: steps-ccw  ( #steps interval-us -- )  0 steps  ;

: stepper-wait  ( -- )  begin  #50 ms  schedule-done?  until  ;

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
   #800 ,  #130 ,
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

\ init-stepper
