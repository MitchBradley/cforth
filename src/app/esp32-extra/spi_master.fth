marker spi_master.fth  cr lastacf .name #19 to-column .( 17-05-2024 )


[ifdef] mosi-gpio
  cr .( ERROR: mosi-gpio must not be defined.)
  cr .( Use the ESP32 as a master OR a slave! Hit <ctrl c> )
  key abort
[then]

#23 value miso-gpio       #26 value mosi-gpio
#33 value sclk-gpio       #25 value spics-gpio

 #1 value dma              #0 value spi_handle
 #0 value mode       #4000000 value SpiSpeed
 #3 value /que          #4092 value /SpiBufLimit

: .spi-settings
      ." Settings Esp32 SPI master:" ."  SpiSpeed:"  SpiSpeed  . ." hz"
   cr ."  Miso-gpio:" miso-gpio .    ."  Mosi-gpio:"  mosi-gpio  .
      ."  Sclk-gpio:" sclk-gpio .    ."  Spics-gpio:" spics-gpio .
   cr ."  Mode:"     mode     .      ."  Dma:"       Dma       .
      ."  /que:"     /que     .      ."  /SpiBufLimit:" /SpiBufLimit .
;
: InitSpiMaster  ( - )
   .spi-settings   dma  sclk-gpio  miso-gpio  mosi-gpio
   spi-bus-init abort" spi_bus_initialize failed"
   /que mode SpiSpeed spi-bus-setup  to spi_handle
;
: spi-master-write  ( &buffer size - )
   dup /SpiBufLimit /mod nip dup 0>  if
   2 pick swap /SpiBufLimit * dup >r bounds   do
           /SpiBufLimit  i pad spi_handle spi-master-data
                   abort" spi-master-data failed"
           /SpiBufLimit +loop
           r> /string
       else   drop
       then
    swap pad spi_handle spi-master-data abort" spi-send-data failed"
;
\ \s
