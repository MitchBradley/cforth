// Low-level serial drivers for Atmel AT91SAM7

#include "types.h"
#include "regs.h"
#include "pio.h"
#include "param.h"

void init_debug_uart()
{
    u_char junk;

    DBGU_BRGR = BAUD_115200;
    DBGU_MR = PAR_NONE | CHMODE_NORMAL;
    spin(1000);
    DBGU_CR = RXEN | TXEN;
    PIO_PDR = DTXD;

    junk = (u_char)DBGU_RHR;  // Junk leftover from break
    junk = (u_char)DBGU_RHR;
}

int dbgu_mayget(u_char *byte)
{
    if ((DBGU_SR & RXRDY) == 0)
        return 0;
    *byte = (u_char)DBGU_RHR;
    return 1;
}

int dbgu_mayput(u_char c)
{
    if ((DBGU_SR & TXRDY) == 0)
        return 0;
    DBGU_THR = (u_long)c;
    return 1;
}

void raw_putchar(u_char c)
{
    while (dbgu_mayput(c) == 0) ;

    // while ((DBGU_SR & TXEMPTY) == 0) ;
}

void type(u_char *s)
{
    u_char c;
    while ( (c = *s) != 0) {
        raw_putchar(c);
        s++;
    }
}

void cr()
{
    type("\r\n");
}

void line(u_char *s)
{
    type(s);
    cr();
}

u_char ukey()
{
    u_char byte;

    while (0 == dbgu_mayget(&byte))
        ;
    return byte;
}

int timed_key(u_char *cp, u_int ticks)
{
    u_int end_ticks;
    
    end_ticks = get_ticks() + ticks;
    do {
        if (dbgu_mayget(cp))
            return 1;
    } while ((get_ticks() - end_ticks) > 0);
    return 0;
}

#define UBUFLEN 256
static u_char ubuf[UBUFLEN*2];
static u_char *nextbuf;
static u_char *nextbyte;

void rem_init()
{
    PMC_PCER = US0_PID;

    US0_CR = RXDIS | TXDIS | RSTRX | RSTTX | RSTSTA;

    USART0(PTCR) = RXTDIS | TXTDIS;

    nextbyte = &ubuf[0];
    nextbuf = &ubuf[0];    // Both buffers are already attached now
    USART0(RPR) = (u_long) &ubuf[0];
    USART0(RCR) = (u_long) UBUFLEN;
    USART0(RNPR) = (u_long) &ubuf[UBUFLEN];
    USART0(RNCR) = (u_long) UBUFLEN;
    USART0(PTCR) = RXTEN;

    US0_BRGR = BAUD_115200;
    US0_RTOR = 18;           // bit times of delay before timeout
    US0_MR = PAR_NONE | CHMODE_NORMAL | USCLKS_MCK | CHRL_8 | NBSTOP_1 | STTTO;
    spin(1000);
    US0_CR = RXEN | TXEN;

    // junk = (u_char)US0_RHR;  // Junk leftover from break
    // junk = (u_char)US0_RHR;
}

// Poll for an input character from the serial line.
// If one is available store it in byte and return true.
int rem_mayget(u_char *byte)
{
    // The software buffer pointer chases the hardware pointer
    // around the ring
    if (nextbyte == (u_char *) USART0(RPR))
        return 0;
    
    *byte = *nextbyte++;

    if (nextbyte == &ubuf[UBUFLEN*2])  // Wraparound
        nextbyte = &ubuf[0];

    if (US0_CSR & ENDRX) {      // Keep recycling buffer halves    
        // XXX we need something like:
        //  int offset = nextbyte - nextbuf;
        //  if (offset < 0 || offset >= UBUFLEN) {
        // but then we would have to worry about restarting
        // after an overflow (we probably should worry about
        // that anyway because the current code is not entirely
        // overflow-proof).
        USART0(RNPR) = (u_long) nextbuf;
        USART0(RNCR) = UBUFLEN;
        USART0(PTCR) = RXTEN;
        nextbuf = (nextbuf == &ubuf[0]) ? &ubuf[UBUFLEN] : &ubuf[0];
    }
    return 1;
}

u_char rem_key()
{
    u_char byte;
    while (rem_mayget(&byte) == 0) {}
    return byte;
}

int rem_mayput(u_char c)
{
    if ((US0_CSR & TXRDY) == 0)
        return 0;
    US0_THR = (u_long)c;
    return 1;
}

void rem_emit(u_char c)
{
    while ((US0_CSR & TXRDY) == 0) {}
    US0_THR = (u_long)c;
}

void rcv_init()
{
    u_char junk;

    PMC_PCER = US1_PID;
    US1_BRGR = BAUD_19200;
    US1_MR = PAR_ODD | CHMODE_NORMAL | USCLKS_MCK | CHRL_8 | NBSTOP_1;
    spin(1000);
    US1_CR = RXEN | TXEN;

    junk = (u_char)US1_RHR;  // Junk leftover from break
    junk = (u_char)US1_RHR;
}

int rcv_mayput(u_char c)
{
    if ((US1_CSR & TXRDY) == 0)
        return 0;
    US1_THR = (u_long)c;
    return 1;
}

void rcv_emit(u_char c)
{
    while ((US1_CSR & TXRDY) == 0) {}
    US1_THR = (u_long)c;
}

int rcv_navail()
{
    return (US1_CSR & RXRDY) != 0;
}

int rcv_key()
{
    int status;
    long retval;

    while (((status = US1_CSR) & RXRDY) == 0) {}

    retval = US1_RHR;
    if (status & PARE) {
        retval |= 0x100;
        US1_CR = RSTSTA;
    }
    return retval;
}
