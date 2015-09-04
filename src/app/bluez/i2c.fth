\ Interface to Linux I2C driver

-1 value i2c-fid
: ?open-i2c  ( -- )
   i2c-fid 0<  if
      " /dev/i2c-1" h-open-file to i2c-fid
      i2c-fid 0< abort" Can't open I2C driver"
   then
;

: set-i2c-slave  ( slave# -- )
   ?open-i2c
   $0703 i2c-fid ioctl 0< abort" set-i2c-slave failed"
;

: read-i2c  ( adr len -- )  tuck  i2c-fid h-read-file  <> abort" read-i2c failed"  ;
: write-i2c  ( adr len -- )  tuck  i2c-fid h-write-file  <> abort" write-i2c failed"  ;
