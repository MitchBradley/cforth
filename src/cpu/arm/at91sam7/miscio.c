#include "regs.h"
#include "pio.h"
#include "param.h"

// Magic recipe from Julie to save 10 uA by disabling USB pads ??
// Also disables USB clocks
void disable_usb()
{
    PMC_SCER  =  SC_UDP;
    PMC_PCER  =  UDP_PID;
    UDP(0x74) = 0x100;
    spin(1000);
    PMC_PCDR  =  UDP_PID;
    PMC_SCDR  =  SC_UDP;
}

void configure_pio()
{
    int flag;

    // Configure the I/O pins, pp. 205-230
    // setup unused pins as GPIO inputs with pullups
    PIO_PER  = ~(PIO_ASRVAL | PIO_BSRVAL);
    PIO_PDR  =  PIO_ASRVAL | PIO_BSRVAL;

    PIO_ODR  = ~(PIO_OUTS);      // everything that shouldn't be an output isn't

    PIO_OER  =  PIO_OUTS;
    PIO_MDDR =  TOTEM_POLES;  // Totem pole drivers
    PIO_MDER =  OPEN_DRAINS;  // Open drain drivers
    PIO_ASR  =  PIO_ASRVAL;   // Assign the pins to the A functions
    PIO_BSR  =  PIO_BSRVAL;   // Assign the pins to the B functions

    // Turn off pullups to save power
    PIO_PUDR =  PIO_GPIOS | PIO_ASRVAL | PIO_BSRVAL;
    PIO_PUER =  PULLUPS;      // enable internal pullups
}

inline void watchdog_off() {
    WDT_MR = WDDIS;
}

inline void enable_reset() {
    RSTC_MR = URSTEN;
}

#if 0
void tploop()
{
    PIO_PER = TP1;
    PIO_OER = TP1;

    while(1) {
        PIO_SODR = TP1;
        PIO_CODR = TP1;
    }
}
#endif
