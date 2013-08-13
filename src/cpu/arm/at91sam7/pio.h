// Assignments of PIO bits to specific functions,
// according to the board layout.
// This is platform-dependent.

#define BIT(n)  (1 << n)

// PIO GPIO bits
#define VADJ0     BIT(0)
#define VADJ1     BIT(1)
#define PTT       BIT(2)
#define SHUNT     BIT(3)
#define A0        BIT(4)
#define REMRXD    BIT(5)
#define REMTXD    BIT(6)
#define TMS       BIT(7)
#define ADR       BIT(8)
#define DRXD      BIT(9)
#define DTXD      BIT(10)
#define RESET_    BIT(11)
#define MISO      BIT(12)
#define MOSI      BIT(13)
#define SCK_TCK   BIT(14)
#define DA_FS     BIT(15)  // TF peripheral A
#define DA_SCLK   BIT(16)  // TK peripheral A
#define DA_SDIN   BIT(17)  // TD peripheral A
#define DA_MCLK   BIT(18)  // PCK2 peripheral B
#define RD_WR_    BIT(19)
#define IRQ       BIT(20)
#define RCVRXD    BIT(21)
#define RCVTXD    BIT(22)
#define STROBE    BIT(23)
#define DATABUS   0xff000000

#define PULLUPS    0
#define PIO_INS    (IRQ | DATABUS)
#define TOTEM_POLES (SHUNT | A0 | TMS | ADR | RESET_ | RD_WR_ | STROBE)
#define OPEN_DRAINS (VADJ0 | VADJ1 | PTT)
#define PIO_OUTS   (OPEN_DRAINS | TOTEM_POLES)
#define PIO_GPIOS  (PIO_OUTS | PIO_INS)

#define SPI_PINS (MISO | MOSI | SCK_TCK)

#define PIO_ASRVAL (REMRXD | REMTXD | DTXD | DRXD | SPI_PINS | DA_FS | DA_SCLK | DA_SDIN | RCVRXD | RCVTXD)
#define PIO_BSRVAL (DA_MCLK)
