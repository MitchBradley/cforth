\ Driver for TSL2561 light-to-digital converter

$39 constant tsl2561-slave

: power!  ( b -- )  a0 tsl2561-slave i2c-b! abort" no ack"  ;
\ : power@  ( -- b )  a0 tsl2561-slave true i2c-b@  ;
: power-on  3 power!  ;
\ : power-off  0 power!  ;
\ : power-on?  power@  3 and 3 =  ;

: timing!  ( timing -- )  a1 tsl2561-slave i2c-b!  abort" no ack" ;
\ : timing@  ( -- timing )  a1 tsl2561-slave true i2c-b@   ;
\ : integ-13.7ms  0  ;
\ : integ-101ms   1  ;
: integ-402ms   2  ;
\ : integ-manual  3  ;

\ : +gain-low  ;
: +gain-high  10 or  ;

: timing-on  integ-402ms +gain-high  timing!  ;

\ manual integration
\ (the adc shadow register is not updated until manual integration ends)
\ : manual-on  timing@  8 or  timing!  ;
\ : manual-off  timing@  8 invert and  timing!  ;
\ : timing-manual  integ-manual +gain-high  timing!  ;

: adc0@  ( -- adc0 )  ac tsl2561-slave true i2c-le-w@  ;
: adc1@  ( -- adc1 )  ae tsl2561-slave true i2c-le-w@  ;

: adc@  ( -- adc0 adc1 )
   ac tsl2561-slave i2c-start-write  abort" no ack"
   true tsl2561-slave i2c-start-read  abort" no ack"
   0 i2c-byte@
   0 i2c-byte@  bwjoin
   0 i2c-byte@
   1 i2c-byte@  bwjoin
;

: init-tsl2561  power-on  timing-on  ;

: watch-tsl2561  init-tsl2561  begin  adc@ .d .d cr  #100 ms  key?  until  ;
