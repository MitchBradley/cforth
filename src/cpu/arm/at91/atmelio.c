#include "regs.h"
#include "pio.h"
#include "param.h"
#include "audioin.h"
#include <stddef.h>
#include "config.h"
#include "common.h"

extern int reset_reason, old_pc, old_cpsr;

// int waits;

void debug_key()
{
}


#if 0
inline int ptt_on(int message)
{
    return ((PIO_PDSR & PTT) == 0);
}
#endif

inline void interrupts_off()
{
// Disable all the interrupts I can find
    PMC_IDR   = 0xFFFFFFFF;
    DBGU_IDR  = 0xFFFFFFFF;
    US1_IDR   = 0xFFFFFFFF;
    PIO_IDR   = 0xFFFFFFFF;
    TC_IDR(0) = 0xFFFFFFFF;
    TC_IDR(1) = 0xFFFFFFFF;
    TC_IDR(2) = 0xFFFFFFFF;
    SSC(SSC_IDR) = 0xFFFFFFFF;
    AIC_IDCR  = 0xFFFFFFFF;
// Turn off pending interrupts too
    AIC_IPR   = 0xFFFFFFFF;  
}

void clear_bss()
{
    extern long first_to_clear, __bss_end__;
    extern long saved_dp;
    long *p;
}

void show_reset()
{
    cr();
    switch (reset_reason) {
    case 0: break;  // Power-on reset
    case 1: type("Undefined Instruction Exception"); break;
    case 2: type("Prefetch Abort Exception"); break;
    case 3: type("Data Abort Exception"); break;
    case 4: type("Fast Interrupt Exception"); break;
    case 5: type("Software Restart"); break;
    default: type("Strange reset_reason"); break;
    }
    if (1 <= reset_reason && reset_reason <= 4) {
        type(" at PC "); dotn(old_pc);
        type("CPSR "); dotn(old_cpsr);
    }
    cr();

// Don't turn it off because diags() needs it.  If we turn it on and
// off too much it tends to output garbage characters.
//    debug_uart_off();
}

void init_io()
{
    watchdog_off();
    enable_reset();

// Get here from reset with CPU running on slow clock
// Get here on trap with whatever we were using.

    di();
    DBGU_CR = RSTRX | RSTRX;           // Reset Debug TTY port

    external_clocks_off();

    peripheral_clocks_on();            // clocks for PIO and SSC
    
    configure_pio();

    init_clocks();

#if 0
    reset_adc();
#endif

    interrupts_off();

    init_rtt();

    clear_bss();

    disable_usb();

    init_debug_uart();
    // rem_init();
    // rcv_init();
    // show_reset();

#ifdef LATER
    init_cpu_adc();
#endif

    // mclk to codec is set to 4mhz in clock.c so we can quick start
    // slow it down here.  usually it is slowed down in sscadc.c
    PMC_PCK2 = CSS_MAIN | PRES(MCLKEXP);  // For ADC
}

#if 0
tp1_low() { PIO_CODR = TP1; }
tp1_high() { PIO_SODR = TP1; }

tp2_low() { PIO_CODR = TP2; }
tp2_high() { PIO_SODR = TP2; }
#endif

void irq_handler()
{
    AIC_IDCR = -1;
    type("\r\nIRQ\r\n");
}

void swi_handler()
{
    type("SWI\r\n");
}

// FIXME - STUBS

void abort_utterance() { }

void reset()
{
    RSTC_CR = PROCRST | PERRST;  // Reset processor and peripherals
}
