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
: (write-i2c)  ( adr len -- )  tuck  i2c-fid h-write-file  <>  ;
: write-i2c  ( adr len -- )  (write-i2c) abort" write-i2c failed"  ;


4 buffer: i2c-buf
: i2c-reg-setup  ( reg slave -- )  set-i2c-slave i2c-buf c!  ;
: i2c-read-regs  ( reg slave stop? #bytes -- buf )
   >r drop  i2c-reg-setup  i2c-buf 1 write-i2c
   i2c-buf r> read-i2c  i2c-buf
;
: i2c-b@     ( reg slave stop? -- b )  1 i2c-read-regs  c@  ;
: i2c-be-w@  ( reg slave stop? -- w )  2 i2c-read-regs  be-w@  ;
: i2c-le-w@  ( reg slave stop? -- w )  2 i2c-read-regs  be-l@  ;
: i2c-b!     ( b reg slave -- error? )
   i2c-reg-setup  i2c-buf 1+ c!
   i2c-buf 2 (write-i2c)
;
: i2c-be-w!  ( w reg slave -- error? )
   i2c-reg-setup  i2c-buf 1+ be-w!
   i2c-buf 2 (write-i2c)
;
: i2c-le-w!  ( w reg slave -- error? )
   i2c-reg-setup  i2c-buf 1+ le-w!
   i2c-buf 2 (write-i2c)
;
