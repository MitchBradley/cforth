\ Driver for DS1307 RTC

$68 value ds-slave

: ds-read-setup  ( reg# -- )
   ds-slave i2c-start-write abort" ds1307 fail write"
   false ds-slave i2c-start-read abort" ds1307 fail read"
;

$9 buffer: ds

: ds-read  ( -- )
   0 ds-read-setup
   ds  8 0  do
      false i2c-byte@  over c! 1+
   loop
   true i2c-byte@  swap c!
;

: .ds
   ds-read
   ds 9 cdump
;

: ds-set  ( cc yy mm dd ww hh mm ss -- )
   0 ds-slave i2c-start-write abort" ds1307 fail write"
   8 0 do i2c-byte! drop loop
   $90 i2c-byte! drop  \ sqwe 1hz
   i2c-stop
;
