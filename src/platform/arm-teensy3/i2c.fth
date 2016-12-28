h# 4006.6000 value i2c-base  \ two modules

: i2c-set-module  ( 0|1 -- )  h# 1000 *  h# 4006.6000 +  to i2c-base  ;
: i2c@  ( n -- v )  i2c-base + c@  ;
: i2c!  ( n a -- )  i2c-base + c!  ;

\ enable the module clock
\ (if not enabled, reading registers causes a fault)
\ reference, datasheet, p252, sim_scgc4
h# 4004.8034 constant sim_scgc4
: i2c-clk-on-0  sim_scgc4 @  40 or  sim_scgc4 !  ;
: i2c-clk-on-1  sim_scgc4 @  80 or  sim_scgc4 !  ;

\ pin mux, select alternate function 2 for a pair of pins
\ reference, datasheet, p208
\ i2c module 0
\ pin 35 aka ptb0 is i2c0_scl  is teensy pin 16/a2/scl0
\ pin 36 aka ptb1 is i2c0_sda  is teensy pin 17/a3/sda0
\ pin 37 aka ptb2 is i2c0_scl  is teensy pin 19/a5/scl0
\ pin 38 aka ptb3 is i2c0_sda  is teensy pin 18/a4/sda0
: i2c-set-pins-0
   0 +af2  port-b# 2  pcr!
   0 +af2  port-b# 3  pcr!
;
\ i2c module 1
\ pin 55 aka ptc10 is i2c1_scl is teensy pin 29 on rear
\ pin 56 aka ptc11 is i2c1_sda is teensy pin 30 on rear
: i2c-set-pins-1
   0 +af2  port-c# d# 10  pcr!
   0 +af2  port-c# d# 11  pcr!
;

: i2c-set-rate   0 1 i2c!  ;

: i2c-iicen-on   2 i2c@    80                   or  2 i2c!  ;
: i2c-iicen-off  2 i2c@  [ 80 invert ] literal and  2 i2c!  ;

: i2c-mst-on     2 i2c@    20                   or  2 i2c!  ;
: i2c-mst-off    2 i2c@  [ 20 invert ] literal and  2 i2c!  ;

: i2c-tx-on      2 i2c@    10                   or  2 i2c!  ;
: i2c-tx-off     2 i2c@  [ 10 invert ] literal and  2 i2c!  ;

: i2c-txak       2 i2c@    08                   or  2 i2c!  ;
: i2c-rsta       2 i2c@    04                   or  2 i2c!  ;

: i2c-iicif?  ( -- iicif? )  \ i/o completion interrupt flag
   3 i2c@  dup 10 and if
      10 3 i2c! \ clear arbl
      drop true abort" arbitration lost"
   then
   2 and if
      2 3 i2c! \ clear iicif
      true
   else
      false
   then
;

: i2c-wait-no-ack  ( -- )
   d# 10 get-msecs +                            ( msecs )
   begin                                        ( msecs )
      dup get-msecs - 0< abort" timeout"        ( msecs )
      i2c-iicif?                                ( msecs done? )
   until                                        ( msecs )
   drop                                         ( )
;

: i2c-wait-ack  ( -- )
   i2c-wait-no-ack
   3 i2c@  1 and  abort" missing acknowledge"
;

: i2c-put  ( val -- )  4 i2c!  i2c-wait-ack  ;
: i2c-get  ( -- val )  4 i2c@  i2c-wait-no-ack  ;

0 value i2c-addr

\ slave register read
: i2c-reg@  ( reg -- val )
   \ enable transmit and raise START signal
   i2c-tx-on i2c-mst-on                         ( reg )
   \ write device address
   i2c-addr i2c-put                             ( reg )
   \ write register address
   i2c-put                                      ( )
   \ raise repeated START
   i2c-rsta                                     ( )
   \ write device address for read
   i2c-addr 1+ i2c-put                          ( )
   \ switch to rx mode, acknowledge after next transmission by slave
   i2c-tx-off i2c-txak                          ( )
   \ dummy read (we see what we just sent)
   i2c-get drop                                 ( )
   \ read device response
   i2c-get                                      ( val )
   \ raise STOP signal
   i2c-mst-off                                  ( val )
;

\ slave register write
: i2c-reg!  ( val reg -- )
   \ enable transmit and raise START signal
   i2c-tx-on i2c-mst-on                         ( val reg )
   \ write device address
   i2c-addr i2c-put                             ( val reg )
   \ write register address
   i2c-put                                      ( val )
   \ write register value
   i2c-put                                      ( )
   \ raise STOP signal
   i2c-mst-off                                  ( )
;

: i2c-open  ( addr -- )
   2* to i2c-addr
   i2c-clk-on-0
   i2c-set-pins-0
   i2c-set-rate
   i2c-iicen-on
;

: i2c-close  i2c-iicen-off  ;
