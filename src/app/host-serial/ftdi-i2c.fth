\ Bitbanging I2C driver for use with FTDI TTL-232RG serial dongles
\ modified according to the "Mod: INA219 Current Sensing" section of
\   https://sites.google.com/a/nod-labs.com/development/proto2-ftdi-debug-cable
\ CBUS0 is connected to SDA, CBUS1 to SCL
\
\ This assumes that serial-ih is already set to the result of open-com,
\ as with open-serial in wicedforth/serial-tools.fth, and also requires
\ ft-bit-change therefrom.

\ SCL low is $20, SCL high is $00, SDA low is $10, SDA high is data&$20 = 0
: scl-sda!  ( mask -- )  $33 ft-bit-change  ;

: scl-sda@  ( -- mask )  serial-ih ft-getbits  ;
: sda@  ( -- 1|0 )  scl-sda@ 1 and  ;
: scl@  ( -- 2|0 )  scl-sda@ 2 and  ;

\ $10 puts SCL in output mode, $20 puts SDA in output mode
\ $01 is the SCL output state bit, $02 is the SDA output state bit
\ Since I2C is an open drain bus with pullups, we never have to
\ set the output state bits explicitly to 1; to let a line go
\ high we put it in input mode so the pullup will drive it.

: +scl+sda  ( -- )  $00 scl-sda!  ;  \ Both SCL and SDA inputs
: +scl-sda  ( -- )  $10 scl-sda!  ;  \ SCL input, SDA output low
: -scl+sda  ( -- )  $20 scl-sda!  ;  \ SCL output low, SDA input
: -scl-sda  ( -- )  $30 scl-sda!  ;  \ Both SCL and SDA output low

\ Send enough clocks with data high to clear any hung devices
: select-i2c  +scl+sda  d# 16 0  do -scl+sda +scl+sda  loop  ;

\ Each primitive below assumes that SCL is high on entry
\ The bit primitives first drive SCL low and SDA to the
\ desired state, then drive SCL high, leaving it high in
\ preparation for the next bit.  Each primitive except
\ i2c-start performs a falling edge and a rising edge of SCL.

: i2c-start  ( -- )  +scl-sda  ;  \ On entry: SDA and SCL are high (bus idle)
: i2c-repeated-start  ( -- )  -scl+sda  +scl+sda  +scl-sda  ;
: i2c-stop  ( -- )  -scl-sda  +scl-sda  +scl+sda  ;
: i2c-bit!  ( flag -- )  if  -scl+sda +scl+sda   else  -scl-sda +scl-sda  then  ;
: i2c-bit@  ( -- n )   -scl+sda  +scl+sda  sda@   ;
: i2c-byte!  ( n -- )
   8 0  do  dup $80 and  i2c-bit!  2*  loop  drop
   i2c-bit@  if  i2c-stop true abort" No ACK"  then
;
: i2c-byte@  ( nack? -- n )
   0                                ( nack? n )
   8 0  do  2* i2c-bit@ or  loop    ( nack? n )
   swap i2c-bit!                    ( n )
;

0 value devadr  \ 7-bit form
: set-i2c-slave  ( n -- )  to devadr  ;

: i2c-begin  ( 1|0 -- )  i2c-start  devadr 2* or  i2c-byte!  ;

: read-i2c  ( adr len -- )
   dup 0=  if  2drop exit  then     ( adr len )
   1 i2c-begin  

   \ Read len-1 bytes and ACK afterwards
   1- 0  ?do  false i2c-byte@ over c!  1+  loop  ( adr' )

   \ Read the last byte and NACK afterwards
   true i2c-byte@ swap c!

   i2c-stop
;

: write-i2c  ( adr len -- )
   0 i2c-begin  
   bounds  ?do  i c@  i2c-byte!  loop
   i2c-stop
;

: i2c-b@  ( -- b )  1 i2c-begin   true i2c-byte@  i2c-stop  ;
: i2c-b!  ( b -- )  0 i2c-begin   i2c-byte!  i2c-stop  ;
: i2c-be-w@  ( -- w )
   1 i2c-begin   false i2c-byte@  true i2c-byte@  i2c-stop  ( b.hi b.lo )
   swap bwjoin
;
: i2c-be-w!  ( w -- )  wbsplit  0 i2c-begin   i2c-byte!  i2c-byte!  i2c-stop  ;
