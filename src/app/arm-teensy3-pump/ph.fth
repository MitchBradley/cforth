\ pH sensor interface using ADC and analog buffer board
\ A0 is the reference voltage, A1 is the pH voltage
decimal
: pH-counts  ( -- n )
   #12 analogReadRes
   pinA0 analogRead  pinA1 analogRead  -
;
: avg-pH-counts  ( -- n )
   0  #10 0  do  ph-counts +  loop  #10 /
;

0 [if]
125E-3 153E0 f/ fconstant V/count
\ -59E-3 fvalue V/pH  59 mV is nominal but some probes are off a bit
-56E-3 fvalue V/pH
0E0 fvalue pH-offset
: pH  ( -- f.ph )
   avg-pH-counts
   float  ( f.counts )
   V/count f*       ( f.V )
   pH-offset f-     ( f.V )
   V/pH f/       ( f.deltapH )
   7E0 f+           ( f.ph )
;
: f.pH  ( -- )  1 set-precision  pH f.  ;
[then]

#125000 #153 2constant *uV/counts
0 value pH-offset-uV  \ Calibrate this to the pH sensor
#-56000 value uV/pH   \ Calibrate this to the pH sensor
: pH*10  ( -- ph*10 )
   avg-ph-counts    ( counts )
   *uV/counts */    ( uV )
   pH-offset-uV -   ( uV )
   #20 uV/pH */     ( deltapH*20 )
   1+ 2/            ( deltaph*10 )  \ Round
   #70 +            ( ph*10 )  \ Offset to neutral pH 7.0
;
: nn.n  ( -- )  push-decimal <# u# '.' hold u#s u#> type pop-base  ;
: .pH  ( -- )  pH*10  nn.n  ;


#55 value pH-limit-low
#65 value pH-limit-high





0 [if]
0 value ph-timer
#60000 value ph-timer-interval
: clear-ph-timer  ( -- )  0 to ph-timer  ;

: set-ph-timer  ( -- )
   get-msecs ph-timer-interval +   ( target-time )
   dup 0=  if  1+  then            ( target-time' )
   to ph-timer                     ( )
;
: ph-timeout?  ( -- flag )
   ph-timer  0=  if  false exit  then
   ph-timer get-msecs - 0<   ( flag )
;

: pulse-gpio  ( gpio# ms -- )  over 1 swap gpio-pin!  ms  0 swap gpio-pin!  ;
#55 value ph-limit-low
#65 value ph-limit-high
#300 value ph-up-ms
#300 value ph-down-ms

#20000 value recirc-ms
: recirculate  ( -- )  ." Recirculating" cr   recirc-gpio recirc-ms  pulse-gpio  ;
: ph-change  ( gpio ms -- )
   pulse-gpio
   recirculate
   set-ph-timer
;

defer ph-state
defer ph-ok-state
defer ph-low-state
defer ph-high-state

: enter-ph-ok-state  ( -- )
   ['] ph-ok-state to ph-state
   clear-ph-timer
;

: enter-ph-high-state  ( -- )
   ." Lowering pH" cr
   pH-down-gpio ph-down-ms ph-change
   ['] ph-high-state to ph-state
   set-ph-timer
;
: do-ph-high-state  ( -- )
   ph-timeout?  if
      pH*10 ph-limit-high <=  if
         enter-ph-ok-state
      else
	 enter-ph-high-state
      then
   then
;
' do-ph-high-state to ph-high-state

: enter-ph-low-state  ( -- )
   ." Raising pH" cr
   pH-up-gpio ph-up-ms ph-change
   ['] ph-low-state to ph-state
   set-ph-timer
;
: do-ph-low-state  ( -- )
   ph-timeout?  if
      pH*10 ph-limit-low >=  if
	 enter-ph-ok-state
      else
	 enter-ph-low-state
      then
   then
;
' do-ph-low-state to ph-low-state

: do-ph-ok-state  ( -- )
   pH*10                     ( pH*10 )
   ." pH: " dup nn.n cr      ( pH*10 )
   dup ph-limit-low <  if    ( ph*10 )
      drop
      enter-ph-low-state
      exit
   then                      ( pH*10 )
   ph-limit-high  >  if
      enter-ph-high-state
   then
;
' do-ph-ok-state to ph-ok-state

: init-ph  ( -- )  ['] ph-ok-state to ph-state  ;
init-ph
[then]
