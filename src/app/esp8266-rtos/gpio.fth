\ GPIO stuff

\ GPIO numbers are the numbers used on bare ESP modules.
\ Pin numbers are the pin identifiers on NodeMCU and D1 Mini Modules.

decimal

\ Function3 is always GPIO.
\ Pin multiplexing: Offsets are relative to $60000800
\           pinmux-offset  Function 0  Function1  Function2  Function4
#0  constant GPIO0   \ 34  GPIO0       SPI_CS2               CLK_OUT
#1  constant GPIO1   \ 18  UART0_TXD   SPI_CS1               CLK_RTC_BK
#2  constant GPIO2   \ 38  GPIO  2     I2SO_WS    UART1_TXD  UART0_TXD
#3  constant GPIO3   \ 14  UART0_RXD   I2SO_DATA             CLK_XTAL_BK
#4  constant GPIO4   \ 3c  GPIO4       CLK_XTAL
#5  constant GPIO5   \ 40  GPIO5       CLK_RTC
#6  constant GPIO6   \ 1c  SDCLK       SPICLK                UART1_CTS
#7  constant GPIO7   \ 20  SDDATA0     SPIQ_MISI             UART1_TXD
#8  constant GPIO8   \ 24  SDDATA1     SPID_MOSI             UART1_RXD
#9  constant GPIO9   \ 28  SDDATA2     SPIHD                 HSPIHD
#10 constant GPIO10  \ 2c  SDDATA3     SPIWP                 HSPIWP
#11 constant GPIO11  \ 30  SDCMD       SPICS0                UART1_RTS
#12 constant GPIO12  \ 04  MTDI        I2SI_DATA  HSPI_MISO  UART0_DTR
#13 constant GPIO13  \ 08  MTCK        I2SI_BCK   HSPI_MOSI  UART0_CTS
#14 constant GPIO14  \ 0c  MTMS        I2SI_WS    HSPI_CLK   UART0_DSR
#15 constant GPIO15  \ 10  MTDO        I2S0_BCK   HSPI_CS0   UART0_RTS
#16 constant GPIO16  \ Also wakeup from deep sleep

\ NodeMCU/D1Mini Pinout Label Init Restrict  Special
GPIO0  constant Pin-D3  \ D3       Boot: MBH
GPIO1  constant Pin-TX  \ TX   PU  Boot: MBH TXD0
GPIO2  constant Pin-D4  \ D4   PU  Boot: MBH RXD0
GPIO3  constant Pin-RX  \ RX   PU            FLASH
GPIO4  constant Pin-D2  \ D2                 SDA
GPIO5  constant Pin-D1  \ D1                 SCL
GPIO9  constant Pin-D10 \ SD2  PU                 not on mini
GPIO10 constant Pin-D9  \ SD3  PU                 not on mini
GPIO12 constant Pin-D6  \ D6                 MISO
GPIO13 constant Pin-D7  \ D7                 MOSI
GPIO14 constant Pin-D5  \ D5                 SCLK
GPIO15 constant Pin-D8  \ D8       Boot: MBL CS
GPIO16 constant Pin-D0  \ D0                 WAKE

create 'pin>gpio
\     D0         D1       D2        D3   
  GPIO16 c,   GPIO5 c, GPIO4 c,  GPIO0 c,
\     D4         D5        D6        D7        D8      
   GPIO2 c,  GPIO14 c, GPIO12 c, GPIO13 c, GPIO15 c,

: pin>gpio  ( pin# -- gpio# )
   dup 8 >  if  drop -1 exit  then
   'pin>gpio c@
;

\ Pinmux bits
\ bit function
\ 0   OE
\ 1   Sleep_OE
\ 2   Sleep_PullDown
\ 3   Sleep_PullUp
\ 4   Function # bit0
\ 5   Function # bit1
\ 6   PullDown
\ 7   PullUp
\ 8   Function # bit2

create pinmux-offsets
  $34 c, $18 c, $38 c, $14 c, $3c c, $40 c, $1c c, $20 c,
  $24 c, $28 c, $2c c, $30 c, $04 c, $08 c, $0c c, $10 c,

: gpio-function!  ( function# gpio# -- )
   pinmux-offsets + c@ $60000800 +  >r  ( function# r: pinmux-addr )

   \ Clear function# bits in register value
   r@ l@  $130 invert and  ( function# regval r: pinmux-addr )

   \ Bits 1,0 of function# go to bits 5,4 of register
   over 3 and 4 lshift or  ( function# regval' r: pinmux-addr )

   \ Bit 2 of function# goes to bit 8 of register
   swap 4 and 8 lshift or  ( regval' r: pinmux-addr )

   r> l!
;
