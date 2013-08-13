// JTAG programming functions for Atmel AT91SAM7

#include "types.h"
#include "aborts.h"
#include "jtag.h"

// Sets PMC_MCKR to CSS_SLOW, PRES(0), thus switching the processor to
// the slow clock.
void force_slow_clock()
{
    jtag_set_mem(0, 0xfffffc30);
}

#define MCLK_MHZ 16

#ifndef FRDY
#define FRDY 1
#define MOSCEN 1
#define CSS_MAIN 1
#define PCK0 0x100
#define PCK1 0x200
#define PMC_SCER 0xfffffc00
#define CKGR_MOR 0xfffffc20
#define PMC_MCKR 0xfffffc30
#define PMC_PCK0 0xfffffc40

#define PIO_PER  0xfffff400
#define PIO_PDR  0xfffff404
#define PIO_PSR  0xfffff408
#define PIO_OER  0xfffff410
#define PIO_ODR  0xfffff414
#define PIO_OSR  0xfffff418
#define PIO_MDER 0xfffff450
#define PIO_MDDR 0xfffff454
#define PIO_ASR  0xfffff470
#define PIO_BSR  0xfffff474

#define MC_FMR 0xffffff60  // Flash mode register
#define MC_FCR 0xffffff64  // Flash command register
#define MC_FSR 0xffffff68  // Flash status register
#endif

#define FLASH_PAGE_BYTES 128


void wait_flash_ready()
{
    u_long value;
    value = 0;

    while( (value & FRDY) == 0) {
        value = jtag_get_mem(MC_FSR);
    }
}

void mem_to_flash(u_long address, int numbytes, u_long flash_adr)
{
    int thisbytes;

    thisbytes = FLASH_PAGE_BYTES;

    while (numbytes > 0) {
        wait_flash_ready();
        if (numbytes < FLASH_PAGE_BYTES) {
            thisbytes = numbytes;
        }
        jtag_out(address, thisbytes, flash_adr);
        jtag_set_mem(MC_FMR, MCLK_MHZ << 16);
        jtag_set_mem(MC_FCR, ((flash_adr & 0x1ff80) << 1) | 0x5a000001);
        flash_adr += thisbytes;
        address += thisbytes;
        numbytes -= thisbytes;
    }
}

void start_mclk()
{
    jtag_set_mem(CKGR_MOR, MOSCEN | 0xff00);   // Start main oscillator

    // Probably no need to poll for ready
    jtag_set_mem(PMC_MCKR, CSS_MAIN);

    jtag_set_mem(PMC_SCER, PCK0 | PCK1);
    jtag_set_mem(PMC_PCK0, CSS_MAIN);   // MCLK to test point for debugging

    jtag_set_mem(PIO_PDR, 0x40);        // PA6 for special function PCK0
    jtag_set_mem(PIO_BSR, 0x40);        // Assign it to the B function
}

void start_jtag()
{
    u_long id;

    setup_jtag_ports();
    assert_ptt();
    power_cycle();   // PTT turns on power
    line("Power is on");
    test_logic_reset();
    line("idcode");    ms(1000);
    id = idcode();
    line("idcode out");    ms(1000);
    dotn(id);
    id = idcode();
    line("idcode agin");    ms(1000);
    dotn(id);
    if( id == 0x3f0f0f0f  ) {
        line("Stopping core");  ms(1000);
        stop_core();
        line("Core stopped");

        start_mclk();
        line("MCLK started");
    }
}

#define AT91SAM7_CODE_BASE 0x200000

void jtag_to_mem(u_long address, int numbytes)
{
    start_jtag();
    line("Loading diags to memory in remote");
    jtag_out(address, numbytes, AT91SAM7_CODE_BASE);
    line("Running code");
    jtag_goto(AT91SAM7_CODE_BASE);
}

#define AT91SAM7_FLASH_BASE 0x100000

void jtag_to_flash(u_long address, int numbytes)
{
    u_char b;
    start_jtag();
//    line("Type s to skip FLASH loading");
//    getkey(b);
//    if( b != 's' ) {
        line("Starting FLASH loading");
        mem_to_flash(address, numbytes, AT91SAM7_FLASH_BASE);
//        line("Next step is to power cycle");
//        waitkey();
//    }
    power_cycle();   // PTT turns on power
}

#if 0
// Read a bunch of registers to see what happens, for initial debugging
void test_registers()
{
    u_long id;

    id = idcode(id);
    id = get_cpsr();
    id = 0x87654321;
    ice_set(watchpoint0_adr, id);
    id = idcode();
    id = ice_get(watchpoint0_adr);
    set_register(5, 0xaa5533cc);
    set_register(12, 0x1234fedc);
    id = get_register(5);
    id = get_register(12);
}
#endif
