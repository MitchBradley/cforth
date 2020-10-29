\ DoitCar control program
0 constant LED-pin
1 constant left-speed-pin
7 constant right-speed-pin
3 constant left-direction-pin
2 constant right-direction-pin
5 constant left-s1-pin
6 constant left-s2-pin
7 constant right-s1-pin
8 constant right-s2-pin

: pwm-on  ( pin -- )
   >r
   #1023 #1000 r@ pwm-setup
   r@ pwm-start
   0 r> pwm-duty!
;

: led-on  ( -- )  0 LED-pin gpio-pin!  ;
: led-off  ( -- )  1 LED-pin gpio-pin!  ;

: left-speed  ( n -- )  left-speed-pin pwm-duty!  ;
: right-speed  ( n -- )  right-speed-pin pwm-duty!  ;

: left-forward  ( -- )  1 left-direction-pin gpio-pin!  ;
: left-backward  ( -- )  0 left-direction-pin gpio-pin!  ;
: right-forward  ( -- )  1 right-direction-pin gpio-pin!  ;
: right-backward  ( -- )  0 right-direction-pin gpio-pin!  ;

variable last-left
variable last-right
variable left-period
variable right-period
: left-cb  ( level -- )
   drop timer@                       ( this-us )
   dup last-left @ -  left-period !  ( this-us )
   last-left !                       ( )
   gpio-int-negedge left-s1-pin gpio-enable-interrupt
;
: right-cb  ( level -- )
   drop timer@                         ( this-us )
   dup last-right @ -  right-period !  ( this-us )
   last-right !                        ( )
   gpio-int-negedge right-s1-pin gpio-enable-interrupt
;
0 constant nopull
1 constant pullup
: car-init
   left-speed-pin pwm-on  0 left-speed
   right-speed-pin pwm-on  0 right-speed
   nopull gpio-output LED-pin gpio-mode   led-on
   nopull gpio-output left-direction-pin gpio-mode
   nopull gpio-output right-direction-pin gpio-mode
   pullup gpio-interrupt left-s1-pin gpio-mode
   pullup gpio-interrupt right-s1-pin gpio-mode

   ['] left-cb left-s1-pin gpio-callback!
   gpio-int-negedge left-s1-pin gpio-enable-interrupt

   ['] right-cb right-s1-pin gpio-callback!
   gpio-int-negedge right-s1-pin gpio-enable-interrupt
;
: l.  left-period @ .d ;
: r.  right-period @ .d ;
