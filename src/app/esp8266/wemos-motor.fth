$30 value motor-i2c-slave

\ Motor commands
\ 0 constant brake
\ 1 constant cw
\ 2 constant ccw
\ 3 constant stop
\ 4 constant standby

: i2c-bout  ( byte -- )  i2c-byte! abort" I2C failed"  ;
\ Speed is PWM percent * 100, commands as above, motor is 0 or 1
\ Speed only matters for cw and ccw commands; others ignore it
: motor-set  ( w.speed command motor# -- )
   i2c-start  motor-i2c-slave i2c-bout   ( w.speed command motor )
   $10 or i2c-bout                  ( w.speed command )
   i2c-bout                         ( w.speed )
   wbsplit i2c-bout i2c-bout        ( )
   i2c-stop
;
: motor-frequency  ( l.frequency -- )
   i2c-start  motor-i2c-slave i2c-bout   ( w.speed command motor )
   lbsplit $f and i2c-bout i2c-bout i2c-bout i2c-bout ( )
   i2c-stop
;
: motor-init  ( -- )
   1 2 i2c-setup
   #1000 motor-frequency
;
: motor-cw       ( power motor# -- )  1 swap motor-set  ;
: motor-ccw      ( power motor# -- )  2 swap motor-set  ;
: motor-brake    ( motor# -- )  0 0 rot motor-set  ;
: motor-stop     ( motor# -- )  0 3 rot motor-set  ;
: motor-standby  ( motor# -- )  0 4 rot motor-set  ;
: motor-cw-ms    ( ms motor# -- )
   >r                  ( ms r: motor# )
   #10000 r@ motor-cw  ( ms r: motor# )
   ms                  ( r: motor# )
   r@ motor-brake      ( r: motor# )
   r> motor-standby    ( )
;
: motor-ccw-ms  ( ms motor# -- )
   >r                  ( ms r: motor# )
   #10000 r@ motor-ccw ( ms r: motor# )
   ms                  ( r: motor# )
   r@ motor-brake      ( r: motor# )
   r> motor-standby    ( )
;
