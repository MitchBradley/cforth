marker spi_slave_test.fth

needs exchange-timeout spi_slave.fth

char 0 value testchar    75 value exchange-timeout

: init-sent ( - )
   testchar &sendbuf /SpiData bounds  do
     [char] E  i c!
             1+ dup i 1+ c!
   2 +loop
   dup  [ char z /SpiData - ] literal  >  if
      drop [char] 0
   then
   to testchar
 ;
: test-spi  ( - )
    begin  init-sent &recvbuf &sendbuf 10000  SpiExchangeData 0=
    while  cr ." Out:" &sendbuf /SpiData type
              ."  In:" &recvbuf /SpiData type exchange-timeout ms
    repeat
 ."  End of test "
 ;
: test      ( - ) InitSpiSlave ."  Waiting for data..." test-spi  ;

cr cr test
.s quit


0 [if]             \ Save the following gforth-source on the Raspberry Pi as RpiSpiMaster.fs:
\ Connections:
\ GPio SPI
\ 11   SCLK
\ 10   MOSI
\ 9    MISO
\ 8    SPI Chip Select 0

needs wiringPi.fs  \ From https://github.com/kristopherjohnson/wiringPi_gforth

0 constant SpiPort               0       constant mode
0 constant SpiChannel            4000000 constant spiSpeed
0 value    fdSpiData             16      value    /SpiData
0 value    &AppData              0       value    &SpiData
char 0 value testchar

: init-sent        ( - )
   testchar &AppData /SpiData bounds   do
      [char] r  i c!  1+ dup i 1+ c!
      2 +loop
   dup  [ char z /SpiData - ] literal  >   if
      drop [char] 0
      then
    to testchar
;
: .spi-settings    ( - )
   ." SPI settings Raspberry Pi Master:"   3 set-precision ." Spi clk: " SpiSpeed s>f fe. ." hz. "
   cr  ."  Mode:" mode .  ." /SpiData:" /SpiData .  ."  SpiPort:" SpiPort . ."  SpiChannel:" SpiChannel .
;
: spiSetupMode     ( mode spiSpeed spiChannel -  fd )
   /SpiData allocate drop to &AppData    /SpiData allocate drop to &SpiData
   .spi-settings  wiringPiSPISetupMode
;
: SpiExchangeData  ( - ) \ &SpiData will be overwritten
   SpiPort &SpiData /SpiData wiringPiSPIDataRW drop
;
: test-SpiExchangeData   ( - )
   init-sent   &AppData &SpiData /SpiData cmove
   cr ." Out:" &SpiData /SpiData type
   SpiExchangeData
   ."  In:" &SpiData /SpiData type
;
: test-spi         ( - )
   begin  key?  if
            key 27 <>
            else true
            then
   while   test-SpiExchangeData 2000 ms
   repeat
;

cr cr mode spiSpeed  SpiChannel  spiSetupMode  to fdSpiData
test-spi
.s quit \ End code for the Raspberry Pi

[then]
