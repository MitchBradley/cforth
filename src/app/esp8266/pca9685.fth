\ Driver for PCA9685 I2C pulse-width modulator / LED driver

$60 value pca-slave  \ Base is $40; my board has A6 strapped
: select-pca  ( 0..3 -- )  $40 + to pca-slave  ;

4 buffer: pca-buf
: ?pca-error  ( error? -- )  abort" PCA9685 write failed"  ;
: pca-b@  ( reg# -- b )  pca-slave 0 i2c-b@  ;
: pca-b!  ( b reg# -- )  pca-slave i2c-b! ?pca-error  ;
: pca-w@  ( reg# -- w )  pca-slave 0 i2c-le-w@  ;
: pca-w!  ( w reg# -- )  pca-slave i2c-le-w! ?pca-error  ;

: pca-on  ( -- )
   $ff $fe pca-b!
   $20 0 pca-b!    \ Normal mode ($10 clear), auto-increment ($20 set)
;  \ Turn off sleep and all-call bits

: pca-on!  ( n channel# -- )  2 << 6 +  pca-w!  ;
: pca-off!  ( n channel# -- ) 2 << 8 +  pca-w!  ;

: init-pca  ( -- )
   pca-on
   $1000 0 pca-off!
   $1000 4 pca-off!
   0 0 pca-on!
   0 4 pca-on!
;

\ Values from 50 to 260 are good for micro servos
: ch0  ( n -- )  0 pca-off!  ;
: ch4  ( n -- )  4 pca-off!  ;
