/*
 * Ariel (Dell Wyse 3020) Console I/O
 *
 * Copyright (C) 2020 Lubomir Rintel <lkundrak@v3.sk>
 *
 * Based on src/platform/arm-xo-1.75/consoleio.c
 */

#include "forth.h"
#include "compiler.h"

#define UART3REG ((unsigned int volatile *)0xd4018000)

int dbg_uart_only = 0;

void txdbg(char c)
{
    while ((UART3REG[5] & 0x20) == 0)
        ;
    UART3REG[0] = (unsigned int)c;
}

void raw_putchar(char c)
{
    txdbg(c);
}

int kbhit3() {
    return (UART3REG[5] & 0x1) != 0;
}

int kbhit() {
    return kbhit3();
}

int getkey()
{
    do {
        if (kbhit3())
            return UART3REG[0];
    } while (1);
}

void init_io(int argc, char **argv, cell *up)
{
    dbg_uart_only = 0;

    // If the PJ4 processor has already been started, this is an unexpected
    // reset so we skip the SoC init to preserve state for debugging.
    if (((*(int *)0xd4050020) & 0x02) == 0)
        return;

    *(int *)0xd4051024 = 0xffffffff;    // PMUM_CGR_PJ - everything on
    *(int *)0xd4015064 = 0x00000007;    // APBC_AIB_CLK_RST - reset, functional and APB clock on
    *(int *)0xd4015064 = 0x00000003;    // APBC_AIB_CLK_RST - release reset, functional and APB clock on
    *(int *)0xd4051020 = 0x00000000;    // PMUM_PRR_PJ - Turn off SLAVE_R and WDTR2 (empirically, the WDTR2 bit stays set afterwards)

    *(int *)0xd401e120 = 0x00001001;    // GPIO51 = AF1 for UART3 RXD
    *(int *)0xd401e124 = 0x00001001;    // GPIO52 = AF for UART3 TXD

    *(int *)0xd4015034 = 0x00000013;    // APBC_UART3_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)

    UART3REG[1] = 0x40; // Marvell-specific UART Enable bit
    UART3REG[3] = 0x83; // Divisor Latch Access bit
    UART3REG[0] = 14;   // 115200 baud
    UART3REG[1] = 00;   // 115200 baud
    UART3REG[3] = 0x03; // 8n1
    UART3REG[2] = 0x07; // FIFOs and stuff
}

void irq_handler()
{
}

void swi_handler()
{
}

void raise()
{
}

int strlen(const char *s)
{
    const char *p;

    for (p=s; *p != '\0'; *p++)
        ;

    return p-s;
}
