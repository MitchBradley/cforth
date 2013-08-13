#include "types.h"
#include "param.h"
#include "regs.h"

#define TIMING_FACTOR  ((MCLK_MHZ * 3 / 2) + 1)   // Clocks in 1.5 uSec

#define START_CHAR  1       // ^A
#define IMAGE_CHAR  6       // ^F, typical first character of ARM binary image
#define LONG_TIMEOUT 60000   // milliseconds
#define SHORT_TIMEOUT 1000   // milliseconds
#define MAX_FLASH_PAGE 256

// These need to be inlined so that serial_to_flash will be self-contained
// and thus position-independent and easy to copy to an arbitrary RAM address.
// ARM subroutine calls aren't position-independent.

static inline int timed_getchar(u_char *c, int ms)
{
    int target_ticks;
    target_ticks = (int)RTT_VR + 1 + (ms << 5);

    while ((DBGU_SR & RXRDY) == 0) {
        if (((int)RTT_VR - target_ticks) > 0) {
            return -1;
        }
    }
    *c = (u_char)DBGU_RHR;
    return 0;
}

static inline void wait_flash()
{
    while ((MC_FSR & FRDY) == 0) {
    }
}

// Copy the RAM page buffer to the FLASH page buffer and start writing
// it to FLASH.  Returns nonzero if the FLASH is not ready for writing
// when called.
static inline int page_to_flash(u_long *pagebuf, u_long *flash_adr)
{
    int pagelongs = 1 << (FLASH_PAGE_BITS - 2);
    int i;

    // The FLASH is supposed to be ready now because it takes longer
    // to collect the serial bytes than to write a FLASH page.
    if ((MC_FSR & FRDY) == 0) {
        return -1;
    }

    for (i = 0; i < pagelongs; i++) {
        flash_adr[i] = pagebuf[i];
        pagebuf[i] = flash_adr[i + pagelongs];
    }

    MC_FMR = FCMN(TIMING_FACTOR) | FWS(1);
    MC_FCR = WP(flash_adr);   // Write page

    return 0;
}

// Assumes that the serial port is already initialized
// flash_adr must be page-aligned
int serial_to_flash(u_char *flash_adr)
{
    u_char pagebuf[MAX_FLASH_PAGE];
    int page_offset;
    int pagelen;
    u_char c;
    u_long *flash_ptr;

    pagelen = (1 << FLASH_PAGE_BITS);

    do {
        if (timed_getchar(&c, LONG_TIMEOUT) != 0) {
            return -1;
        }
//    } while (c != START_CHAR && c != IMAGE_CHAR);
    } while (c == '\r');

    if (c == START_CHAR) {
        if (timed_getchar(&c, LONG_TIMEOUT) != 0) {
            return -1;
        }
    }

    flash_ptr = (u_long *)((u_long)flash_adr & ~(pagelen-1));

    for (page_offset = 0; page_offset < pagelen; page_offset++) {
        pagebuf[page_offset] = *((u_char *)flash_ptr)++;
    }

    flash_ptr = (u_long *)((u_long)flash_adr & ~(pagelen-1));
    page_offset = (u_long)flash_adr & (pagelen-1);

    do {
        pagebuf[page_offset++] = c;
        if (page_offset == pagelen) {
            if (page_to_flash((u_long *)pagebuf, flash_ptr) != 0) {
                return -2;
            }
            flash_ptr += (pagelen/sizeof(long));
            page_offset = 0;
        }
    } while (timed_getchar(&c, SHORT_TIMEOUT) == 0);
    
    wait_flash();
    if (page_offset != 0) {
        if (page_to_flash((u_long *)pagebuf, flash_ptr) != 0) {
            return -2;
        }
    }
    wait_flash();

    if (((int)flash_adr & 0xfffff) == 0) {   // Can't return because we clobbered the program
        RSTC_CR = PROCRST | PERRST;  // Reset processor and peripherals
    }

    return (u_char *)flash_ptr - flash_adr + page_offset;
}
int serial_to_flash_end() { }

int ram_to_flash(u_char *flash_adr, int len, u_char *adr)
{
    u_char pagebuf[MAX_FLASH_PAGE];
    int page_offset;
    int pagelen;
    u_char c;
    u_long *flash_ptr;

    pagelen = (1 << FLASH_PAGE_BITS);

    flash_ptr = (u_long *)((u_long)flash_adr & ~(pagelen-1));

    for (page_offset = 0; page_offset < pagelen; page_offset++) {
        pagebuf[page_offset] = *((u_char *)flash_ptr)++;
    }

    flash_ptr = (u_long *)((u_long)flash_adr & ~(pagelen-1));
    page_offset = (u_long)flash_adr & (pagelen-1);

    while (len--) {
        pagebuf[page_offset++] = *adr++;
        if (page_offset == pagelen) {
            if (page_to_flash((u_long *)pagebuf, flash_ptr) != 0) {
                return -2;
            }
            flash_ptr += (pagelen/sizeof(long));
            page_offset = 0;
        }
    }
    
    wait_flash();
    if (page_offset != 0) {
        if (page_to_flash((u_long *)pagebuf, flash_ptr) != 0) {
            return -2;
        }
    }
    wait_flash();

    if (((int)flash_adr & 0xfffff) == 0) {   // Can't return because we clobbered the program
        RSTC_CR = PROCRST | PERRST;  // Reset processor and peripherals
    }

    return (u_char *)flash_ptr - flash_adr + page_offset;
}
int ram_to_flash_end() { }


int erase_flash_range(u_char *flash_adr, int len)
{
    u_char *end_adr;
    int i;
    int pagelongs;

    pagelongs = (1 << (FLASH_PAGE_BITS - 2));

    // Fill the page buffer
    for (i=0; i < pagelongs; i++) {
        ((u_long *)flash_adr)[i] = 0xffffffff;
    }
    
    for (end_adr = flash_adr + len;
         flash_adr < end_adr;
         flash_adr += (pagelongs * 4))
    {
        wait_flash();
        MC_FMR = FCMN(TIMING_FACTOR) | FWS(1);
        MC_FCR = WP(flash_adr);   // Write page
    }
    wait_flash();
    return len;
}

int erase_flash_range_end() {}

int execute_from_ram(int (*start)(), int (*end)(),
                     int (*ram_addr)(), int arg0, int arg1, int arg2)
{
    u_long *p;
    u_long *q;
    int result;

    // Copy to RAM
    q = (u_long *)ram_addr;
    
    for(p = (u_long *)start; p < (u_long *)end; p++) {
        *q++ = *p;
    }

    return ram_addr(arg0, arg1, arg2);      // Execute RAM copy
}

int __end__();

int ram_serial_to_flash(u_char *flash_adr)
{
    return execute_from_ram(serial_to_flash, serial_to_flash_end,
                            &__end__, (int)flash_adr, 0, 0);
}

int ram_erase_flash_range(int len, u_long *flash_adr)
{
    return execute_from_ram(erase_flash_range, erase_flash_range_end, 
                            &__end__, (int)flash_adr, len, 0);
}

int ram_write_flash_range(int len, u_long *flash_adr, u_char *adr)
{
    return execute_from_ram(ram_to_flash, ram_to_flash_end, 
                            &__end__, (int)flash_adr, len, (int)adr);
}
