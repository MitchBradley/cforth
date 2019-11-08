// Top-level routine for starting Forth

#if CFORTHSIZE > SHIMBASE - RAMBASE
#    error "cforth.img is too large"
#endif

#define cell long
void spi_read(cell offset, cell len, cell adr);

#define UARTREG ((unsigned int volatile *)0xd4018000)  // UART3
// #define UARTREG ((unsigned int volatile *)0xd4030000)  // UART1

void init_io(void);

void main()
{
    void *up;

    init_io();   // Perform platform-specific initialization

    spi_read(0x2000, SHIMBASE - RAMBASE, 0xd1000000);
    ((void (*)())0xd1000000)();
}

void init_io()
{
    *(int *)0xd4051024 = 0xffffffff;  // PMUM_CGR_PJ - everything on
    *(int *)0xD4015064 = 0x7;         // APBC_AIB_CLK_RST - reset, functional and APB clock on
    *(int *)0xD4015064 = 0x3;         // APBC_AIB_CLK_RST - release reset, functional and APB clock on
    *(int *)0xD401502c = 0x13;        // APBC_UART1_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)
    *(int *)0xD4015034 = 0x13;        // APBC_UART3_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)

//  *(int *)0xd401e120 = 0xc1;        // GPIO51 = af1 for UART3 RXD
//  *(int *)0xd401e124 = 0xc1;        // GPIO52 = af1 for UART3 TXD
    *(int *)0xd401e260 = 0xc4;        // GPIO115 = af4 for UART3 RXD
    *(int *)0xd401e264 = 0xc4;        // GPIO116 = af4 for UART3 TXD
    *(int *)0xd401e0c8 = 0xc1;        // GPIO29 = af1 for UART1 RXD
    *(int *)0xd401e0cc = 0xc1;        // GPIO30 = af1 for UART1 TXD

    UARTREG[1] = 0x40;  // Marvell-specific UART Enable bit
    UARTREG[3] = 0x83;  // Divisor Latch Access bit
    UARTREG[0] = 42;    // 38400 baud
    UARTREG[1] = 00;    // 38400 baud
    UARTREG[3] = 0x03;  // 8n1
    UARTREG[2] = 0x07;  // FIFOs and stuff

    *(int *)0xd4015050=7;  // Clock on
    *(int *)0xd4015050=3;
    *(int *)0xd401e100 = 0x5003;  // Pin muxing - GPIO43..46
    *(int *)0xd401e104 = 0x5003;
    *(int *)0xd401e108 = 0x5003;
    *(int *)0xd401e10c = 0x5003;
}
void irq_handler()
{
}

void swi_handler()
{
}
