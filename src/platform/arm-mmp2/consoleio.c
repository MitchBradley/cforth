
// Character I/O stubs

#define UARTREG ((unsigned int volatile *)0xd4018000)

void raw_putchar(char c)
{
    // send the character to the console output device
    while ((UARTREG[5] & 0x20) == 0)
        ;
    UARTREG[0] = (unsigned int)c;
}

int kbhit() {
    return (UARTREG[5] & 0x1) != 0;
}

int getkey()
{
    while (!kbhit())
        ;
    // return the next character from the console input device
    return (unsigned char)UARTREG[0];
}

void init_io()
{
    *(int *)0xd4051024 = 0xffffffff;  // PMUM_CGR_PJ - everything on
    *(int *)0xD4015064 = 0x7;         // APBC_AIB_CLK_RST - reset, functional and APB clock on
    *(int *)0xD4015064 = 0x3;         // APBC_AIB_CLK_RST - release reset, functional and APB clock on
    *(int *)0xD4015034 = 0x13;        // APBC_UART3_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)

    *(int *)0xd401e120 = 0xc1;        // GPIO51 = af1 for UART3 RXD
    *(int *)0xd401e124 = 0xc1;        // GPIO52 = af1 for UART3 TXD

    UARTREG[1] = 0x40;  // Marvell-specific UART Enable bit
    UARTREG[3] = 0x83;  // Divisor Latch Access bit
    UARTREG[0] = 42;    // 38400 baud
    UARTREG[1] = 00;    // 38400 baud
    UARTREG[3] = 0x03;  // 8n1
    UARTREG[2] = 0x07;  // FIFOs and stuff
}

void irq_handler()
{
}

void swi_handler()
{
}
