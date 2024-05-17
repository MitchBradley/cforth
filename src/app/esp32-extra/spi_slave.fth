marker spi_slave.fth cr lastacf .name #19 to-column .( 17-05-2024 )

[ifdef] mosi-gpio
  cr .( ERROR: mosi-gpio must not be defined.)
  cr .( Use the ESP32 as a master OR a slave! Hit <ctrl c> )
  key abort
[then]

\ GPIO pins:
#0  constant mode          #1  constant dma
#1  constant /que

#33 value    sclk-gpio     #25 value    spics-gpio
#26 value    mosi-gpio     #27 value    miso-gpio
0   value    &recvbuf      0   value    &sendbuf

#4092 constant /max-write  \ the limit when DMA enabled or use 64 if DMA is disabled.
#16   #4 /mod nip #4 * /max-write min value /SpiData

: .spi-settings-slave
      ." SPI settings Esp32 Slave:"
   cr ." Miso-gpio:" miso-gpio  .  ."  Mosi-gpio:"  mosi-gpio  .
      ."  Sclk-gpio:" sclk-gpio .  ."  Spics-gpio:" spics-gpio .
   cr ."  Mode:" mode           .  ."  /SpiData:"   /SpiData   .
      ."  Dma:"  Dma            .  ."  /que:"       /que       .
;
: InitSpiSlave ( - )
   /SpiData 4 + >r
   r@ allocate drop dup to &recvbuf r@ erase
   r@ allocate drop dup to &sendbuf r> erase
   cr .spi-settings-slave
   /que  dma  mode  spics-gpio  sclk-gpio  miso-gpio  mosi-gpio  spi-bus-init-slave
   abort" spi-bus-init-slave failed"
;
: SpiExchangeData ( &recvbuf &sendbuf timeout - flag )
   /SpiData swap spi-slave-data
;
