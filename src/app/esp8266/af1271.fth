\ Driver for Adafruit AF-1271 four digit seven segment display, based on
\ Holtek HT16K33 28 SOP-A RAM Mapping 16*8 LED Controller Driver with keyscan

$70 value ht-slave

: ht-cmd  ( cmd -- )  ht-slave i2c-start-write drop i2c-stop  ;
: ht-on  ( -- ) 21 ht-cmd  ;  \ turn on oscillator
: ht-off  ( -- ) 20 ht-cmd  ;  \ turn on oscillator
: ht-br!  ( brightness -- )  e0 or ht-cmd  ;  \ set brightness

: leds-off    ( -- )  80 ht-cmd  ;
: leds-on     ( -- )  81 ht-cmd  ;
: leds-2hz    ( -- )  83 ht-cmd  ;
: leds-1hz    ( -- )  85 ht-cmd  ;
: leds-0.5hz  ( -- )  87 ht-cmd  ;

: ram!  ( val pos -- )
   ht-slave i2c-start-write abort" start write"
   i2c-byte! drop
   i2c-stop
;

: all-ram!  ( val -- )
   0 ht-slave i2c-start-write abort" start write"  ( val )
   10 0 do dup i2c-byte! drop loop drop          ( )
   i2c-stop
;

: 0ram    0 all-ram!  ;
: 1ram  $ff all-ram!  ;

create leds  \ segment mapping; g f e d c b a
3f c, 06 c, 5b c, 4f c, 66 c, 6d c, 7d c, 07 c,
7f c, 6f c, 77 c, 7c c, 39 c, 5e c, 79 c, 71 c,  \ unused; a through f

\ dots mapping; n/c n/c n/c right bottom-left bottom-right centre n/c
: colon-on  2 4 ram!  ;
: colon-off  0 4 ram!  ;

0 value pos

: leds-cr  0 to pos  ;

: leds-next  ( -- )
   pos 2+ to pos
   pos 4  =  if  pos 2+ to pos  then
   pos #10  =  if  leds-cr  then
;

: leds-emit  ( number -- )
   $30 -  leds + c@  pos ram!
   leds-next
;

: leds-type  ( adr len -- )
   bounds  do  i c@ leds-emit  loop
;

: leds-spaces  ( n -- )
   0 max 0 ?do
      0 pos ram!
      leds-next
   loop
;

: leds.  ( number -- )
   leds-cr  (.)  leds-type
;

: leds.r  ( number width -- )
   leds-cr >r (.) r> over - leds-spaces leds-type
;

: af1271-init
   ht-on
   0ram
   3 ht-br!
   leds-on
;

: af1271-test
   af1271-init
   2 0 do  1ram  d# 100 ms  0ram  d# 400 ms  loop
   push-decimal
   #10000 0 do i 4 leds.r 1 ms loop
   pop-base
;
