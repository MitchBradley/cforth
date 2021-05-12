marker -spi.fth cr lastacf .name

  1 constant HSPI_HOST           \ GPIO13=MOSI GPIO14=SCK
#64 constant /max-write          \ A limit of the ESP-12F
5 cells constant /spi_config_t     0 value &spi_config_t

\  SPI default bus interface parameter definition */
\  CS_EN:1, MISO_EN:1, MOSI_EN:1, BYTE_TX_ORDER:0, BYTE_TX_ORDER:0, BIT_RX_ORDER:0, BIT_TX_ORDER:0, CPHA:0, CPOL:0 */
$1C0 constant SPI_DEFAULT_INTERFACE
$10  constant SPI_MASTER_DEFAULT_INTR_ENABLE

#0  constant SPI_MASTER_MODE
#40 constant SPI_2MHz_DIV
#20 constant SPI_4MHz_DIV
#16 constant SPI_5MHz_DIV
#10 constant SPI_8MHz_DIV
#8  constant SPI_10MHz_DIV
#4  constant SPI_16MHz_DIV
#3  constant SPI_20MHz_DIV
#2  constant SPI_40MHz_DIV
#1  constant SPI_80MHz_DIV

: InitSpiMaster  ( spi_clk_div - )
   /spi_config_t allocate throw dup to &spi_config_t
          SPI_DEFAULT_INTERFACE over !           \ spi_config.interface
   cell+  SPI_MASTER_DEFAULT_INTR_ENABLE over !  \ spi_config.intr_enable
   cell+  0 over !                               \ spi_config.event
   cell+  SPI_MASTER_MODE over !                 \ spi_config.mode
   cell+  !                                      \ spi_clk_div
   &spi_config_t HSPI_HOST spi_init throw ;

: spi-master-write  ( &buffer size - )
   4 + dup /max-write /mod nip dup 0>
       if  2 pick swap /max-write * dup >r bounds
               do    i /max-write  spi_master_write64  /max-write
               +loop
           r> /string
       else   drop
       then
    spi_master_write64  ;

\ \s
