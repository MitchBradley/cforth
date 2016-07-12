\ Driver for MS5803 Barometer and Thermometer
$77 value ms-slave
: ms-cmd  ( cmd -- )
   ms-slave i2c-start-write  ( err? )
   i2c-stop   ( err? )
   abort" Write failed"
;
: ms-prom@  ( adr -- w )
   2* $a0 + ms-slave  0 i2c-be-w@
;
8 /w* buffer: ms-caldata
: ms-get-cal  ( -- )
   8 0  do  i ms-prom@  ms-caldata i wa+ w!  loop
;
4 constant ms-temperature-precision
4 constant ms-pressure-precision
create ms-times  1 c, 2 c, 3 c, 5 c, 9 c,
: ms-wait  ( precision -- )   ms-times + c@ ms  ;
: ms-data@  ( -- n )
   0 ms-slave i2c-start-write abort" failed"
   0 ms-slave i2c-start-read abort" failed"
   0 i2c-byte@  0 i2c-byte@  1 i2c-byte@
   swap rot 0 bljoin
;
: ms-caldata@  ( index -- n )  ms-caldata swap wa+ w@  ;
: ms-dt  ( -- dT )
   $50 ms-temperature-precision 2* +  ms-cmd
   ms-temperature-precision ms-wait
   ms-data@                         ( raw )
   5 ms-caldata@ 8 lshift  -        ( dT )
;
: ms-temp@  ( -- C*100 )
   ms-dt
   6 ms-caldata@  1 #23 lshift  */  #2000 +
;
: ms-offset  ( -- n )
   2 ms-caldata@ #16 lshift  ( offt1 )
   4 ms-caldata@ ms-dt 1 7 lshift */  ( offt1 tco*dt )
   +
;
: ms-sens  ( -- n )
   1 ms-caldata@ #15 lshift          ( senst1 )
   3 ms-caldata ms-dt 1 8 lshift */  ( senst1 TCS*dT )
   +
;
: ms-pressure@  ( -- t )
   $40 ms-temperature-precision 2* +  ms-cmd
   ms-temperature-precision ms-wait
   ms-data@  ( d1 )
   ms-sens 1 #21 lshift */  ms-offset -
   #15 rshift
;
