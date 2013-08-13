// Definitions for Atmel AT91SAM7 chip registers and their bits,
// according to the chip specification:

// AT91SAM7 Constants

#define RAMBASE 0x200000
#define RAMSIZE (64 * 1024)

#define ROMBASE 0x100000
#define ROMSIZE (256 * 1024)

// AT91SAM7 System Peripheral Registers and their bits
// The information is from 6070A-ATARM-06-Sep-04

// Peripheral ID numbers - page 26
#define PID(n)     (1<<(n))
#define FIQ_PID    PID(0)   // page 26
// PID(3) is reserved
// PID(15..29) are reserved

#define REG(base,offset) *(volatile unsigned long *)((void *)base + offset)

#define MC(offset)   REG(0xffffff00, offset)    // page 17
// Memory Controller - page 92
#define MC_RCR    MC(0x00)
#define MC_ASR    MC(0x04)
#define MC_AASR   MC(0x08)

#define MC_FMR    MC(0x60)
#define MC_FCR    MC(0x64)
#define MC_FSR    MC(0x68)
#define MC_FVR    MC(0x6c)

// MC_RCR bits - page 93
#define RCB  0x01    // Remap Command Bit - write 1 to toggle between RAM and ROM at address 0
// MC_ASR bits - page 94
// XXX add these bits, although we probably won't use them

#define FL_PAGE_LONGS 32

// Flash Mode Register bits

#define FRDY  0x01   // Interrupt enable for flash ready
#define LOCKE 0x04   // Interrupt enable for lock error
#define PROGE 0x08   // Interrupt enable for programming error
#define NEBP  0x80   // Don't automatically erase page prior to programming
#define FWS(n)  (((n) & 3) << 8)  // # of wait states for read (+1 for write)
#define FCMN(n) (((n) & 0xff) << 16)  // Master clock MHz

// Flash Command register bits

#define FLASH_PAGE_BITS   (((DBGU_CIDR >> 8) & 0xf) >= 7 ?    8 :    7)

#define PAGEN(adr)  ((((unsigned int)(adr) >> FLASH_PAGE_BITS) & 0x3ff) << 8)
#define FLASH_CMD(adr, cmd)  (0x5a000000 | PAGEN(adr) | (cmd & 0xf))

#define WP(adr)    FLASH_CMD(adr, 0x1)        // Write page
#define SLB(adr)   FLASH_CMD(adr, 0x2)        // Set lock bit
#define WPL(adr)   FLASH_CMD(adr, 0x3)        // Write page and lock
#define CLB(adr)   FLASH_CMD(adr, 0x4)        // Clear lock bit
#define EA         FLASH_CMD(0,   0x8)        // Erase all
#define SGBP(b)    FLASH_CMD(b<<8,0xb)   // Set general-purpose NVM bit
#define CGPB(b)    FLASH_CMD(b<<8,0xd)   // Clear general-purpose NVM bit
#define SSB        FLASH_CMD(0,   0xf)        // Set security bit

// Flash status register bits

// FRDY, LOCKE, and PROGE are the same as for the mode register
#define SECURITY   0x10
#define GPNVM      0xff00
#define LOCKS      0xffff0000

// Offsets to Peripheral Data Controller (DMA) registers from the peripheral
// base address.  This applies to many different peripherals.
#define RPR  0x100
#define RCR  0x104
#define TPR  0x108
#define TCR  0x10c
#define RNPR 0x110
#define RNCR 0x114
#define TNPR 0x118
#define TNCR 0x11c
#define PTCR 0x120
#define PTSR 0x124  // The manual says 0x114 - obviously wrong

// periph_PTCR bits - page 134
#define TXTDIS 0x200 // Transmitter transfer disable
#define TXTEN  0x100 // Transmitter transfer enable
#define RXTDIS 0x002 // Receiver transfer disable
#define RXTEN  0x001 // Receiver transfer enable

#define AIC_IRQ    PID(30)  // page 26
#define AIC(offset)  REG(0xfffff000, offset)    // page 17
// AIC registers - page 148
#define AIC_SMR(n)  AIC((n)*4)
#define AIC_SVR(n)  AIC(0x80+((n)*4))
#define AIC_IVR     AIC(0x100)
#define AIC_FVR     AIC(0x104)
#define AIC_ISR     AIC(0x108)
#define AIC_IPR     AIC(0x10c)
#define AIC_IMR     AIC(0x110)
#define AIC_CISR    AIC(0x114)
#define AIC_IECR    AIC(0x120)
#define AIC_IDCR    AIC(0x124)
#define AIC_ICCR    AIC(0x128)
#define AIC_ISCR    AIC(0x12c)
#define AIC_EOICR   AIC(0x130)
#define AIC_SPU     AIC(0x134)
#define AIC_DCR     AIC(0x138)
#define AIC_FFER    AIC(0x140)
#define AIC_FFDR    AIC(0x144)
#define AIC_FFSR    AIC(0x148)

// AIC_SMR bits
#define PRIOR(n)    ((n) & 0x07)
#define SRCTYPE(n)  (((n) & 0x03) << 5)
#define LOW_LEVEL    0
#define FALLING_EDGE 1
#define HIGH_LEVEL   2
#define RISING_EDGE  3

// Bits for AIC_IPR, AIC_IMR, AIC_IECR, AIC_IDCR, AIC_ICCR, AIC_ISCR..
#define AIC_FIQ 0x01
#define AIC_SYS 0x02

// AIC_SVR(n) bits - 32-bit handler address for interrupt n
// AIC_IVR bits - 32-bit value from SVR register for current active interrupt
// AIC_FIQ bits - 32-bit handler address for FIQ
// AIC_ISR bits - R/O, returns 5-bit interrupt source number for current active interrupt
// AIC_IPR bits - R/O, returns 32-bit mask of pending interrupts
// AIC_IMR bits - R/O, returns 32-bit mask of enabled interrupts
// AIC_CISR bits - R/O - 2-bit mask of whether IRQ and FIQ lines are active
#define NFIQ 0x01
#define NIRQ 0x02

// AIC_IECR, AIC_IDCR, AIC_ICCR, AIC_ISCR bits - write a 1 bit to enable,
// disable, clear, or set the corresponding interrupt

// AIC_EOICR bits - write anything when done with the current interrupt
// AIC_SPU bits - 32-bit handler address for spurious interrupt
// AIC_DEBUG bits
#define PROT 0x01
#define GMSK 0x02  /* Don't interrupt, but do wake up from idle state */

// AIC_FFER, AIC_FFDR - write a 1 bit to enable/disable FIQ forcing for
// that interrupt
// AIC_FFSR - R/O reads back state of fast-forcing mask

#define PMC(offset)  REG(0xfffffc00, offset)    // page 17
// PMC registers - page 140
#define PMC_SCER   PMC(0x00)  // System clock enable
#define PMC_SCDR   PMC(0x04)  // System clock disable
#define PMC_SCSR   PMC(0x08)  // System clock status
#define PMC_PCER   PMC(0x10)  // Peripheral clock enable
#define PMC_PCDR   PMC(0x14)  // Peripheral clock disable
#define PMC_PCSR   PMC(0x18)  // Peripheral clock status
#define CKGR_MOR   PMC(0x20)  // Main Oscillator
#define CKGR_MCFR  PMC(0x24)  // Main Clock Frequency
#define CKGR_PLLR  PMC(0x2c)  // PLL B
#define PMC_MCKR   PMC(0x30)  // Master Clock
#define PMC_PCK0   PMC(0x40)  // Programmable Clock 0
#define PMC_PCK1   PMC(0x44)  // Programmable Clock 1
#define PMC_PCK2   PMC(0x48)  // Programmable Clock 2
#define PMC_IER    PMC(0x60)  // Interrupt Enable
#define PMC_IDR    PMC(0x64)  // Interrupt Disable
#define PMC_SR     PMC(0x68)  // Status
#define PMC_IMR    PMC(0x6c)  // Interrupt Mask
#define PMC_VR     PMC(0xfc)  // Version

// PMC_SC{E,D,S}R bits - pages 173
#define PCK    0x01   // Processor Clock
#define SC_UDP 0x080  // USB Device Port Clock
#define PCK0   0x100  // Programmable Clock 0
#define PCK1   0x200  // Programmable Clock 1
#define PCK2   0x400  // Programmable Clock 2

// CKGR_MOR bits - page 180
#define MOSCEN     0x01    // Main Oscillator Enable
#define OSCBYPASS  0x02    // Oscillator Bypass
#define OSCOUNT(n) (n<<8)  // Startup delay in units of 64 slow clocks

// CKGR_PLLR - pages 179 
#define PLLDIV(n)  ((n) & 0xff)     // PLL divisor
#define PLLMUL(n)  (((n-1) & 0x7ff) << 16)  // PLL multiplier
#define PLLCOUNT(n)  (((n) & 0x3f) << 8)    // PLL startup delay
#define OUT(n)       (((n) & 0x3) << 14)    // PLL clock frequency range
#define USBDIV(n)    (((n) & 0x3) << 28)    // Divider for USB clock


// PMC_MCKR and PMC_PCK0-3 - page 180
#define CSS_SLOW  0x00  // Clock source selection ...
#define CSS_MAIN  0x01
// #define CSS_PLLA  0x02  // reserved on this chip
#define CSS_PLL   0x03

#define PRES(n) (((n) & 7) << 2)  // Log2 of prescale divisor

// PMC_IER, PMC_IDR, PMC_SR, PMC_IMR - pages 152-155
#define MOSCS   0x01   // Main oscillator ready
#define LOCK    0x04   // PLL locked in
#define MCKRDY  0x08   // Master clock ready
#define PCK0RDY 0x100  // Programmable clock 0 ready
#define PCK1RDY 0x200  // Programmable clock 1 ready
#define PCK2RDY 0x400  // Programmable clock 2 ready

#define RSTC(offset)  REG(0xfffffd00, offset)    // page 17
// Reset Controller register definitions and bits - page 57...
#define RSTC_CR     RSTC(0x00)
#define RSTC_SR     RSTC(0x04)
#define RSTC_MR     RSTC(0x08)

// Reset Controller Control Registers bits page 57

#define KEY(n) (0xa5000000 | (n)) // Must be 0xA5 for the other bits to work

#define PROCRST KEY(0x01)  // Resets the processor
#define ICERST  KEY(0x02)  // Resets the processor's ICE interface
#define PERRST  KEY(0x04)  // Resets the peripherals
#define EXTRST  KEY(0x08)  // Asserts the NRST pin

// Reset Controller Status Register bits page 59

#define URSTS   0x01      // NRST falling edge occurred
#define BODSTS  0x02      // Brown-out falling edge occurred
#define RSTTYP  0x700     // 0:Power-up 2:Watchdog 3:SWreset 4:NRST 5:BOD
#define NRSTL   0x10000   // NRST level registered at MCK
#define SRCMP   0x20000   // Software reset command in progress (rst ctlr busy)

// Reset Controller Mode Register bits page 60

#define URSTEN  KEY(0x01)  // Enables reset on NRST low
#define URSTIEN KEY(0x10)  // Enables software reset (via RSTC_SR USRTS bit)
#define BODIEN  KEY(0x10000)  // Enables brown-out reset
#define ERSTL(n) KEY(((n) & 0xf) << 8) // Log2 of external reset length slow clks

#define RTT(offset)  REG(0xfffffd20, offset)    // page 17
// Real Time Timer - page 64
#define RTT_MR   RTT(0x00)   // Mode register
#define RTT_AR   RTT(0x04)   // Alarm register
#define RTT_VR   RTT(0x08)   // Value register
#define RTT_SR   RTT(0x0c)   // Status register

// Real Time Timer Mode Register bits page 64
#define RTPRES(n)  (((n) & 0xffff) << 0)  // Prescaler value
#define ALMIEN     0x10000 // Alarm Interrupt Enable
#define RTTINCIEN  0x20000 // Interrupt Enable for RTT_SR RTTINC bit
#define RTTRST     0x40000 // Restarts the clock divider, resets the counter

// Real Time Timer Status Register bits page 68
#define ALMS    0x01  // Alarm occurred
#define RTTINC  0x02  // RTT timer tick occurred


#define PIT(offset)  REG(0xfffffd30, offset)    // page 17
// Periodic Interval Timer - page 72
#define PIT_MR   PIT(0x00)   // Mode register
#define PIT_SR   PIT(0x04)   // Status register
#define PIT_PIVR PIT(0x08)   // Value register
#define PIT_PIIR PIT(0x0c)   // Image register

// Periodic Interval Timer Mode Register bits page 73
#define PIV(n)  (((n) & 0xfffff)  // Periodic interval value
#define PITEN     0x1000000 // Timer Enable
#define PITIEN    0x2000000 // Interrupt Enable

// Periodic Interval Timer Status Register bits page 74
#define PITS  0x01  // Reached PIV

// Periodic Interval Timer Value and Image Register bits pages 75-76
#define CPIV(n)  ((n) & 0xfffff)  // Current value
#define PICNT  0xfff00000  // Number of occurrences


#define WDT(offset)  REG(0xfffffd40, offset)    // page 17
// Watchdog Timer register definitions and bits - page 80...
#define WDT_CR     WDT(0x00)
#define WDT_MR     WDT(0x04)
#define WDT_SR     WDT(0x08)

// Watchdog Timer Control Register bits - page 81
#define WDRSTT  KEY(0x01)   // Restarts the watchdog

// Watchdog Timer Mode Register bits - page 82
#define WDV(n)  ((n) & 0xfff)  // Value
#define WDFIEN    0x1000     // Interrupt enable
#define WDTRSTEN  0x2000     // Reset enable
#define WDRPROC   0x4000     // Reset only the processor (not everything)
#define WDDIS     0x8000     // Disable the watchdog timer
#define WDD(n)  (((n) & 0xfff) << 16)  // Delta value (see manual)
#define WDDBGHLT  0x10000000 // Stop watchdog when in debug state
#define WDIDLEHLT 0x20000000 // Stop watchdog when in idle state

// Watchdog Timer Status Register bits - page 83
#define WDUNF  0x01   // Underflow occurred
#define WDERR  0x02   // Watchdog error occurred


// Voltage Reglator register definitions and bits - page 85...
#define VREG_MR     REG(0xfffffd00, 0x60)       // page 17
#define PSTDBY  0x01   // Standby mode


// XX check this later
#define DBGU(offset) REG(0xfffff200, offset)    // page 17
// Debug Unit - page 192
#define DBGU_CR   DBGU(0x00)
#define DBGU_MR   DBGU(0x04)
#define DBGU_IER  DBGU(0x08)
#define DBGU_IDR  DBGU(0x0c)
#define DBGU_IMR  DBGU(0x10)
#define DBGU_SR   DBGU(0x14)
#define DBGU_RHR  DBGU(0x18)
#define DBGU_THR  DBGU(0x1c)
#define DBGU_BRGR DBGU(0x20)
#define DBGU_CIDR DBGU(0x40)
#define DBGU_EXID DBGU(0x44)
#define DBGU_FNR  DBGU(0x48)
// PDC registers start at offset 0x100

#define US0_PID    PID(6)   // page 26
#define USART0(offset) REG(0xfffc0000, offset)  // page 17

#define US0_CR   USART0(0x00)
#define US0_MR   USART0(0x04)
#define US0_IER  USART0(0x08)
#define US0_IDR  USART0(0x0c)
#define US0_IMR  USART0(0x10)
#define US0_CSR  USART0(0x14)
#define US0_RHR  USART0(0x18)
#define US0_THR  USART0(0x1c)
#define US0_BRGR USART0(0x20)
#define US0_RTOR USART0(0x24)
#define US0_TTGR USART0(0x28)

#define US1_PID    PID(7)   // page 26
#define USART1(offset) REG(0xfffc4000, offset)  // page 17

// USART Unit - page 300
#define US1_CR   USART1(0x00)
#define US1_MR   USART1(0x04)
#define US1_IER  USART1(0x08)
#define US1_IDR  USART1(0x0c)
#define US1_IMR  USART1(0x10)
#define US1_CSR  USART1(0x14)
#define US1_RHR  USART1(0x18)
#define US1_THR  USART1(0x1c)
#define US1_BRGR USART1(0x20)
#define US1_RTOR USART1(0x24)
#define US1_TTGR USART1(0x28)

#define US1_FIDI US(0x40)
#define US1_NER  US(0x44)
#define US1_IF   US(0x4c)
// PDC registers start at offset 0x100

// DBGU_CR page ?  and US_CR page 300
#define RSTRX  0x04   // Reset receiver
#define RSTTX  0x08   // Reset transmitter
#define RXEN   0x10   // Enable receiver
#define RXDIS  0x20   // Disable receiver
#define TXEN   0x40   // Enable transmitter
#define TXDIS  0x80   // Disable transmitter
#define RSTSTA 0x100  // Reset status bits
// US_CR only below here
#define STTBRK  0x200    // Start break
#define STPBRK  0x400    // Stop break
#define STTTO   0x800    // Start timeout
#define SENDA   0x1000   // Send address
#define RSTIT   0x2000   // Reset iterations
#define RSTNACK 0x4000   // Reset non-acknowledge
#define RETTO   0x8000   // Rearm timeout
#define DTREN   0x10000  // Enable DTR
#define DTRDIS  0x20000  // Disable DTR
#define RTSEN   0x40000  // Enable RTS
#define RTSDIS  0x80000  // Disable RTS

// US_MR
#define PAR_EVEN  0x000
//#define PAR_EVEN  0x800
#define PAR_ODD   0x200
#define PAR_SPACE 0x400
#define PAR_MARK  0x600
#define PAR_NONE  0x800
//#define PAR_NONE  0x000

#define CHMODE_NORMAL          0x0000
#define CHMODE_ECHO            0x4000
#define CHMODE_LOCAL_LOOPBACK  0x8000
#define CHMODE_EXT_LOOPBACK    0xc000

// USART only
#define USART_MODE_NORMAL          0x00
#define USART_MODE_RS485           0x01
#define USART_MODE_HW_HANDSHAKE    0x02
#define USART_MODE_MODEM           0x03
#define USART_MODE_ISO7816T0       0x04
#define USART_MODE_ISO7816T1       0x06
#define USART_MODE_IRDA            0x08

#define USCLKS_MCK      0x00
#define USCLKS_MCKDIV   0x10
#define USCLKS_SCK      0x30

#define CHRL_5  0x00
#define CHRL_6  0x40
#define CHRL_7  0x80
#define CHRL_8  0xc0

#define NBSTOP_1    0x0000
#define NBSTOP_1_5  0x1000
#define NBSTOP_2    0x3000

#define MSBF    0x10000
#define MODE9   0x20000
#define CLKO    0x40000
#define OVER    0x80000
#define INACK   0x100000
#define DSNACK  0x200000
#define MAX_ITERATION(n) ((n) & 0xf) << 24)
#define FILTER  0x1000000

// DBGU_{IER,IDR,IMR,SR}
#define RXRDY    0x01
#define TXRDY    0x02
#define ENDRX    0x08
#define ENDTX    0x10
#define OVRE     0x20
#define FRAME    0x40
#define PARE     0x80
#define TIMEOUT  0x100
#define TXEMPTY  0x200
#define TXBUFF   0x800
#define RXBUFF   0x1000
#define COMMTX   0x40000000
#define COMMRX   0x80000000

// DBGU_CIDR
// XXX add field definitions

// DBGU_FNR
#define FNTRST 0x01  // Force JTAG TAP controller reset

#define PIO_PID   PID(2)   // page 26
#define PIO(offset) REG(0xfffff400, offset)    // page 17

// PIO page 214
#define PIO_PER  PIO(0x00)
#define PIO_PDR  PIO(0x04)
#define PIO_PSR  PIO(0x08)
#define PIO_OER  PIO(0x10)
#define PIO_ODR  PIO(0x14)
#define PIO_OSR  PIO(0x18)
#define PIO_IFER PIO(0x20)
#define PIO_IFDR PIO(0x24)
#define PIO_IFS  PIO(0x28)
#define PIO_SODR PIO(0x30)
#define PIO_CODR PIO(0x34)
#define PIO_ODSR PIO(0x38)
#define PIO_PDSR PIO(0x3c)
#define PIO_IER  PIO(0x40)
#define PIO_IDR  PIO(0x44)
#define PIO_IMR  PIO(0x48)
#define PIO_ISR  PIO(0x4c)
#define PIO_MDER PIO(0x50)
#define PIO_MDDR PIO(0x54)
#define PIO_MDSR PIO(0x58)
#define PIO_PUDR PIO(0x60)
#define PIO_PUER PIO(0x64)
#define PIO_PUSR PIO(0x68)
#define PIO_ASR  PIO(0x70)
#define PIO_BSR  PIO(0x74)
#define PIO_ABSR PIO(0x78)
#define PIO_OWER PIO(0xa0)
#define PIO_OWDR PIO(0xa4)
#define PIO_OWSR PIO(0xa8)

#define TC0_PID    PID(12)  // page 26
#define TC1_PID    PID(13)  // page 26
#define TC2_PID    PID(14)  // page 26
#define TC012(n,offset) REG(0xfffa0000+0x40*n, offset)   // page 17

#define TC_BCR      TC012(3,0)   // Block control register
#define TC_BMR      TC012(3,4)   // Block mode register

// Timer Counter Channel registers page 363
#define TC_CCR(n)   TC012(n,0x00)    // Channel control
#define TC_CMR(n)   TC012(n,0x04)    // Channel mode
#define TC_CV(n)    TC012(n,0x10)    // Counter value
#define TC_RA(n)    TC012(n,0x14)    // Register A
#define TC_RB(n)    TC012(n,0x18)    // Register B
#define TC_RC(n)    TC012(n,0x1c)    // Register C
#define TC_SR(n)    TC012(n,0x20)    // Status
#define TC_IER(n)   TC012(n,0x24)    // Interrupt Enable
#define TC_IDR(n)   TC012(n,0x28)    // Interrupt Disable
#define TC_IMR(n)   TC012(n,0x2c)    // Interrupt Mask

// TC Block control register bits
#define SYNC  0x01  // Synchronizes the 3 channels

// TC Block mode register bits
#define TC0XC0S(n)  (((n) & 0x03) << 0)  // 0:TCLK0 2:TIOA1 3:TIOA2
#define TC1XC1S(n)  (((n) & 0x03) << 2)  // 0:TCLK1 2:TIOA0 3:TIOA2
#define TC2XC2S(n)  (((n) & 0x03) << 4)  // 0:TCLK2 2:TIOA0 3:TIOA1

// TC Channel Control register bits
#define CLKEN  0x01   // Enables clock if CLKDIS is not 1
#define CLKDIS 0x02   // Disables clock
#define SWTRG  0x04   // Reset the counter and start the clock

// TC Channel Mode register: wave mode
#define BCPB(n) (((n) & 3) << 24)
#define BCPC(n) (((n) & 3) << 26)

#define WAVE 0x8000
#define WAVESEL(n) (((n) & 3) << 13)
#define TCCLKS(n) (((n) & 7) << 0)
#define EEVT(n)  (((n) & 3) << 10)   // External event sel 0:TIOB 1:XC0 2:XC1 3:XC2

// XXX finish the TC mode bits


// XXX - add register definitions for: SPI, TW, MCI, UDP
#define UDP_PID    PID(11)  // page 26
#define UDP(offset)   REG(0xfffb0000, offset)   // page 17

#define TWI_PID    PID(9)  // page 26
#define TWI(offset)   REG(0xfffb8000, offset)   // page 17

#define SPI_PID    PID(5)  // page 26
#define SPI(offset)   REG(0xfffe0000, offset)   // page 17

#define SSC_PID   PID(8)  // page 26
#define SSC(offset) REG(0xfffd4000, offset)    // page 17

#define SSC_CR   0x0
#define SSC_CMR  0x4
#define SSC_RCMR 0x10
#define SSC_RFMR 0x14
#define SSC_TCMR 0x18
#define SSC_TFMR 0x1c
#define SSC_RHR  0x20
#define SSC_THR  0x24
#define SSC_RSHR 0x30
#define SSC_TSHR 0x34
#define SSC_SR   0x40
#define SSC_IER  0x44
#define SSC_IDR  0x48
#define SSC_IMR  0x4c

// SSC_SR bits
#define SSC_TXRDY   0x01
#define SSC_TXEMPTY 0x02
#define SSC_ENDTX   0x04
#define SSC_TXBUFE  0x08
#define SSC_RXRDY   0x10
#define SSC_OVRUN   0x20
#define SSC_ENDRX   0x40
#define SSC_RXBUFF  0x80
#define SSC_TXSYN  0x400
#define SSC_RXSYN  0x800
#define SSC_TXEN 0x10000
#define SSC_RXEN 0x20000

// SSC_TMCR and SSC_RMCR bits
#define CKS(n)  (((n) & 3) << 0)  // Tx: 0: Divided clock (BRG)  1: RK  2: TK Pin  3: res
                                  // Rx: 0: Divided clock (BRG)  1: TK  2: RK Pin  3: res
#define CKO(n)  (((n) & 7) << 2)   // 0: none 1: Continuous Tx or Rx Clk  else: res
#define CKI     0x20  // Data goes out on  0: falling edge 1: rising edge
#define SSC_START(n)  (((n) & 0xf) << 8)  // See manual
#define STTDLY(n)  (((n) & 0xff) << 16)
#define PERIOD(n)  (((n) & 0xff) << 24)

// SSC_TFMR and SSC_RFMR bits
#define DATLEN(n)  (((n) & 0x1f) << 0)  // Bit stream contains DATLEN +1 data bits
#define DATDEF 0x20  // Tx: Level on TD while out of transmission
#define LOOP   0x20  // Rx: loopback mode (RD from TD, RF from TF, RK from TK)
#define SSC_MSBF 0x80  // big-endian at the bit level
#define DATNB(n) (((n) & 0xf) <<  8)  // Data words per frame
#define FSLEN(n) (((n) & 0xf) << 16)  // Frame sync length
#define FSOS(n)  (((n) & 0x7) << 20)  // See manual
#define FSDEN  0x800000 // Shift out SSC_TSHR during frame sync
#define FSEDGE 0x1000000 // 0: positive edge  1: negative edge 

#define ADC_PID    PID(4)

#define ADC(offset) REG(0xfffd8000, offset)    // page 17

#define ADC_CR   ADC(0x00)
#define ADC_MR   ADC(0x04)
#define ADC_CHER ADC(0x10)
#define ADC_CHDR ADC(0x14)
#define ADC_CHSR ADC(0x18)
#define ADC_SR   ADC(0x1c)
#define ADC_LCDR ADC(0x20)
#define ADC_IER  ADC(0x24)
#define ADC_IDR  ADC(0x28)
#define ADC_IMR  ADC(0x2c)
#define ADC_CDR0 ADC(0x30)
#define ADC_CDR1 ADC(0x34)
#define ADC_CDR2 ADC(0x38)
#define ADC_CDR3 ADC(0x3c)
#define ADC_CDR4 ADC(0x40)
#define ADC_CDR5 ADC(0x44)
#define ADC_CDR6 ADC(0x48)
#define ADC_CDR7 ADC(0x4c)

// ADC Control Register bits
#define SWRST 0x01  // Simulates a hardware reset of the ADC
#define START 0x02  // Begins conversion

// ADC Mode Register bits
#define TRGEN 0x01  // Enables hardware triggering
#define TRGSEL(n) (((n) & 7)  << 1)  // Trigger: 0-2: TIOA out of TC0..2 6: ext
#define LOWRES 0x10 // 0: 10-bit resolution, 1: 8-bit resolution
#define SLEEP  0x20 // 0: Normal 1: Sleep
#define PRESCAL(n) (((n) & 0x3f) <<  8)  // ADCClock = MCK/((PRESCAL+1)*2)
#define STARTUP(n) (((n) & 0x1f) << 16)  // Startup Time = (STARTUP+1)*8/ADCClock
#define SHTIME(n)  (((n) & 0x0f) << 24)  // Sample&Hold Time = (SHTIM+1)/ADCClock

// ADC Channel Enable/Disable/Status Register bits
#define CH(n)  (1 << (n))  // enable/disable/sense channel n

// ADC_SR Status/Interrupt{Enable,Disable,Mask} Register bits
#define EOC(n) (1 << (n))  // 1 if conversion is complete
#define ADC_OVRE(n) (1 << ((n)+8))  // 1 if overrun occurred
#define DRDY       0x10000 // Data available in ADC_LCDR
#define GOVRE      0x20000 // Overrun occurred on some channel
#define ADC_ENDRX  0x40000 // Receive counter register reached 0
#define ADC_RXBUFF 0x80000 // Both ADC_RCR and ADC_RNCR

#define SYSIRQ_PID PID(1)   // page 26

#define SLOW_MSECS(n)  { int i; for (i = (n)*6; i--; ) {} }
#define FAST_MSECS(n)  { int i; for (i = (n)*6344; i--; ) {} }
