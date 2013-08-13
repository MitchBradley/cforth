// I/O Port assignments

#include "regs.h"

#define MASK(bitno)  (1 << (bitno))

// PIO Port
#define VADJ0_BIT   0
#define VADJ1_BIT   1
#define PTT_BIT     2
#define SHUNT_BIT   3
#define TMS_BIT     7
#define TDO_BIT     12
#define TDI_BIT     13
#define TCK_BIT     14

// SPI bits, shared with JTAG
#define RESET_BIT   11
#define MISO_BIT    12
#define MOSI_BIT    13
#define SCK_BIT     14

#define SPI_RESET_LOW  PIO_CODR = MASK(RESET_BIT)
#define SPI_RESET_ON   PIO_CODR = MASK(RESET_BIT)
#define SPI_RESET_HIGH PIO_SODR = MASK(RESET_BIT)
#define SPI_RESET_OFF  PIO_SODR = MASK(RESET_BIT)

#define JTAG_RESET_LOW  PIO_CODR = MASK(RESET_BIT)
#define JTAG_RESET_ON   PIO_CODR = MASK(RESET_BIT)
#define JTAG_RESET_HIGH PIO_SODR = MASK(RESET_BIT)
#define JTAG_RESET_OFF  PIO_SODR = MASK(RESET_BIT)

#define SCK_LOW        PIO_CODR = MASK(SCK_BIT)
#define SCK_HIGH       PIO_SODR = MASK(SCK_BIT)

#define PTT_HIGH       PIO_SODR = MASK(PTT_BIT)
#define PTT_OFF        PIO_SODR = MASK(PTT_BIT)

#define PTT_LOW        PIO_CODR = MASK(PTT_BIT)
#define PTT_ON         PIO_CODR = MASK(PTT_BIT)

#define SHUNT_ON       PIO_SODR = MASK(SHUNT_BIT)
#define SHUNT_OFF      PIO_CODR = MASK(SHUNT_BIT)

#define MOSI_LOW       PIO_CODR = MASK(MOSI_BIT)
#define MOSI_HIGH      PIO_SODR = MASK(MOSI_BIT)
