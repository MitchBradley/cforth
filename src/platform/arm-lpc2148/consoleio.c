// #define VCOM
// Character I/O stubs

#ifdef STANDALONE
#include "LPC214x.h"
#else
#ifdef VCOM
extern int VCOM_avail(void);
extern int VCOM_getchar(void);
extern int VCOM_putchar(int);
#else
extern int getc0(void);
extern int put_serial0(int ch);
#define UART0_BASE_ADDR		0xE000C000
#define U0RBR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x00))
#define U0THR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x00))
#define U0DLL          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x00))
#define U0DLM          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x04))
#define U0IER          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x04))
#define U0IIR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x08))
#define U0FCR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x08))
#define U0LCR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x0C))
#define U0MCR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x10))
#define U0LSR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x14))
#define U0MSR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x18))
#define U0SCR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x1C))
#define U0ACR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x20))
#define U0FDR          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x28))
#define U0TER          (*(volatile unsigned long *)(UART0_BASE_ADDR + 0x30))
#endif /* !VCOM */
#endif

void raw_putchar(char c)
{
#ifdef STANDALONE
    while (!(U0LSR & 0x20));
    return (U0THR = ch);
#else
#ifdef VCOM
    VCOM_putchar((int)c);
#else
    putc_serial0((int)c);
#endif
#endif
}

int kbhit() {
#ifdef VCOM
    return VCOM_avail() != 0;
#else
    return (U0LSR & 0x1) != 0;
#endif
}

int getkey()
{
#ifdef STANDALONE
    while (!kbhit())
        ;
    // return the next character from the console input device
    return U0RBR;
#else
#ifdef VCOM
    int c;
    while ((c = VCOM_getchar()) == -1)
	;
    return c;
#else
     return getc0();
#endif
#endif
}

void init_io()
{
#ifdef STANDALONE
    unsigned long baudrate = 9600;
    unsigned long Fdiv;

    PINSEL0 = 0x00000005;                  /* Enable RxD0 and TxD0              */
    U0LCR = 0x83;                          /* 8 bits, no Parity, 1 Stop bit     */
    Fdiv = ( Fcclk / 16 ) / baudrate ;     /* baud rate                        */
    U0DLM = Fdiv / 256;
    U0DLL = Fdiv % 256;
    U0LCR = 0x03;                           /* DLAB = 0                         */
#endif
}

void irq_handler()
{
}

void swi_handler()
{
}
