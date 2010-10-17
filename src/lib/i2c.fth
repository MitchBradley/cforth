: select-i2c  4 index!  3 data!  d# 50 0 do 2 data! 3 data! loop ;
: i2c-stop  0 data! 1 data! 3 data!  ;
: i2c-start  3 data!  1 data!  ;
: bit  ( flag -- )  if  3 2 else  1 0  then  data!  data!  ;
: bits  ( n numbits -- )
   1 swap lshift          ( n mask )
   begin  2/  dup  while  ( n mask )
      2dup and  bit       ( n mask )
   repeat                 ( n mask )
   2drop                  ( )
;
: get-ack  ( -- n )   ( 3 data! ) 4 data!  data@ 8 and  5 data! 1 data!  ;
: i2c-byte  ( n -- )  8 bits get-ack drop  ;
h# 80 constant devadr
: i2c-reg!  ( data reg# -- )
   i2c-start  devadr i2c-byte  h# f8 or  i2c-byte  i2c-byte  i2c-stop
;
