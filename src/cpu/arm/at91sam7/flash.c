#include "regs.h"
#include "param.h"

// out_adr must be 256-byte aligned
unsigned long *fl_write_page(unsigned long *in, unsigned long *out)
{
    unsigned long *end;

    while(!(MC_FSR & FRDY)) {}
    for (end = in + FL_PAGE_LONGS; in < end; in++) {
        *out++ = *in;
    }
    MC_FMR = FWS(0) | FCMN(MCLK_MHZ);   // Auto-erase, no interrupts
    MC_FCR = WP(out - FL_PAGE_LONGS);
    return (out);
}
