\ Driver for SHT21 temperature and humidity sensor

$40 constant sht21-i2c-slave \ Cannot be changed

\ The default setting is good, giving max resolution
: sht21-user@  ( -- b )  $e7 sht21-i2c-slave 0 i2c-b@  ;
: sht21-user!  ( b -- )  $e7 sht21-i2c-slave i2c-b!  ;

: sht21-command  ( command -- )
   sht21-i2c-slave i2c-start-write abort" SHT21 not responding"
;
: sht21-reset  ( -- )  $fe sht21-command  ;

: sht21-crc-step   ( crc byte -- crc' )
   xor
   8 0  do
      2* dup $100 and  if  $131 xor  then
   loop
   \ The result will be zero above bit 7.  If bit 8 is set after a 2*, the
   \ $131 xor will clear it
;

: sht21-check-crc  ( high low check -- error? )
   >r                        ( high low r: check )
   0 rot sht21-crc-step      ( low crc r: check )
   swap sht21-crc-step       ( crc  r: check )
   r> <>
;

: sht21-read  ( command ms -- w )
   >r sht21-command
   r> ms
   begin
      0 sht21-i2c-slave i2c-start-read  ( nack? )
   while
      5 ms
   repeat
   0 i2c-byte@  0 i2c-byte@             ( high low )
   2dup  1 i2c-byte@   sht21-check-crc  ( high low error? )
   abort" SHT21 CRC error"              ( high low )       
   swap bwjoin                          ( w )
;
: 2dp$  ( n*100 -- adr len )
   push-decimal <# u# u# '.' hold u#s u#> pop-base  ( adr len )
;

: sht21-temp@  ( -- C*100 )
   $f3 #60 sht21-read               ( w )
   #175.72 $10000 */                ( scaled )
   #46.85 -                         ( C*100*2^16 )
;
: sht21-temp$  ( -- adr len )  sht21-temp@  2dp$  ;
: .sht21-temp  ( -- )  sht21-temp$ type  ." C"  ;

: sht21-humidity@  ( -- %rh*100 )
   $f5 #20 sht21-read              ( w )
   #125.00 $10000 */               ( scaled )
   #6.00 -                         ( %rh*100 )
;
: sht21-humidity$  ( -- adr len )  sht21-humidity@ 2dp$  ;
: .sht21-humidity  ( -- )  sht21-humidity$ type  ." %"  ;
