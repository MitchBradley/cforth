// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

// This is the only thing that we need from forth.h
#define cell long

// Prototypes

void spi_send(cell len, cell adr);
void spi_read(cell offset, cell len, cell adr);
cell inflate(cell wpptr, cell nohdr, cell clear, cell compr);
void *ps2_devices[2];
void init_ps2();
#if 0   // Examples
cell sum(cell b, cell a);
cell byterev(cell n);
#endif
cell ps2_out(cell byte, cell device_num);
cell dbg_uart_only;

#define DECLARE_REGS \
    volatile unsigned long *fifo = (volatile unsigned long *)0xd4035010; \
    volatile unsigned long *stat = (volatile unsigned long *)0xd4035008

void spi_send(cell len, cell adr)
{
    unsigned char *p = (char *)adr;
    unsigned long regval;
    DECLARE_REGS;
    while (len--)
        *fifo = (unsigned long)*p++;
    do {
        regval = *stat;
    } while ((regval & 0xf04) != 4);
}

void spi_send_only(cell len, cell adr)
{
    unsigned char *p = (char *)adr;
    unsigned long regval;
    DECLARE_REGS;
    int i;
    for (i = len; i; i--)
        *fifo = (unsigned long)*p++;
    for (i = len; i; i--) {
        while ((*stat & 8) == 0)
            ;
        regval = *fifo;
    }
}

#ifdef notdef
void spi_send_many(cell len, cell adr)
{
    unsigned char *p = (char *)adr;
    int cansend;
    unsigned long regval;
    DECLARE_REGS;
    while (len) {
        do {
            regval = *stat;
        } while ((regval & 4) == 0);
        cansend = 16 - ((regval >> 8) & 0xf);
        if (cansend > len)
            cansend = len;
        len -= cansend;
        while (cansend--)
            *(volatile unsigned long *)fifo = (unsigned long)*p++;
    }
}
#endif

void spi_send_page(cell offset, cell len, cell adr)
{
    unsigned char *p = (char *)adr;
    int cansend, i;
    unsigned long regval;
    DECLARE_REGS;

    *fifo = 0x02;  // Page write
    *fifo = (offset >> 16) & 0xff;
    *fifo = (offset >>  8) & 0xff;
    *fifo = offset & 0xff;

    cansend = 12;
    while (len) {
        if (len < cansend)
            cansend = len;

        for (i = cansend; i; i--)
            *(volatile unsigned long *)fifo = (unsigned long)*p++;

        len -= cansend;

        do {
            regval = *stat;
        } while ((regval & 4) == 0);
        cansend = 16 - ((regval >> 8) & 0xf);
    }
    while ((*stat & 8) != 0)
        regval = *fifo;
}

#define CHUNK 12
void spi_read_slow(cell offset, cell len, cell adr)
{
    unsigned char *p = (char *)adr;
    int cansend, i;
    DECLARE_REGS;
    unsigned long regval;
    while (len) {
        *fifo = 0x03;
        *fifo = (offset >> 16) & 0xff;
        *fifo = (offset >>  8) & 0xff;
        *fifo = offset & 0xff;
        cansend = (len < CHUNK) ? len : CHUNK;
        for(i = cansend; i; i--) {
            *fifo = 0;
        }
        for(i = 4; i; i--) {
            while ((*stat & 8) == 0)
                ;
            regval = (unsigned char)*fifo;  // Discard readback from cmd and adr bytes
        }

        for(i = cansend; i; i--) {
            while ((*stat & 8) == 0)
                ;
            *p++ = (unsigned char)*fifo;
        }
        len -= cansend;
        offset += cansend;
    }
}

void lfill(cell value, cell len, cell adr)
{
    unsigned long *p = (unsigned long *)adr;
    while(len>0) {
        *p++ = value;
        len -= sizeof(long);
    }
}
cell lcheck(cell value, cell len, cell adr)
{
    unsigned long *p = (unsigned long *)adr;
    while(len>0) {
        if (*p != value)
            return (cell)p;
        p++;
        len -= sizeof(long);
    }
    return -1;
}
void incfill(cell len, cell adr)
{
    unsigned long *p = (unsigned long *)adr;
    while(len>0) {
        *p = (unsigned long)p;
        p++;
        len -= sizeof(long);
    }
}
cell inccheck(cell len, cell adr)
{
    unsigned long *p = (unsigned long *)adr;
    while(len>0) {
        if (*p != (cell)p)
            return (cell)p;
        p++;
        len -= sizeof(long);
    }
    return -1;
}
#define NEXTRAND(n) ((n*1103515245+12345) & 0x7fffffff)
void randomfill(cell len, cell adr)
{
    unsigned long *p = (unsigned long *)adr;
    unsigned long value = 0;
    while(len>0) {
        value = NEXTRAND(value);
        *p = value;
        p++;
        len -= sizeof(long);
    }
}
cell randomcheck(cell len, cell adr)
{
    unsigned long *p = (unsigned long *)adr;
    unsigned long value = 0;
    while(len>0) {
        value = NEXTRAND(value);
        if (*p != value)
            return (cell)p;
        p++;
        len -= sizeof(long);
    }
    return -1;
}


cell spi_read_status()
{
    DECLARE_REGS;
    unsigned long regval;
    *fifo = 5;
    *fifo = 0;
    while ((*stat & 8) == 0) ;
    regval = (unsigned char)*fifo;  // Discard readback from cmd byte
    while ((*stat & 8) == 0) ;
    return *fifo;
}

void set_control_reg(cell arg)
{
    __asm__ __volatile__ (
        "mcr	p15, 0, %0, c1, c0, 0\n\t"
        : : "r" (arg));
}

cell get_control_reg()
{
    unsigned long value;
    __asm__ __volatile__ (
        "mrc	p15, 0, %0, c1, c0, 0\n\t"
        : "=r" (value));
    return value;
}

cell get_tcm_size()
{
    unsigned long value;
    __asm__ __volatile__ (
        "mrc	p15, 0, %0, c0, c0, 2\n\t"
        : "=r" (value));
    return value;
}

cell inflate_adr(void)
{
    return (cell)inflate;
}

cell byte_checksum(cell len, cell adr)
{
    unsigned char *p = (unsigned char *)adr;
    unsigned long value = 0;
    while(len--) {
        value += *p++;
    }
    return value;
}

cell wfi()
{
    __asm__ __volatile__ (" mcr  p15, 0, r0, c7, c0, 4");
//        "wfi\n\t"
//	    ".long 0xe320f003\n\t"  // wfi - which older assemblers don't support

    return 0;
}

cell wfi_loop()
{
    while (1) {
        __asm__ __volatile__ (" mcr  p15, 0, r0, c7, c0, 4");
//        "wfi\n\t"
//	    ".long 0xe320f003\n\t"  // wfi - which older assemblers don't support
    }

    return 0;
}

cell rdpsr()
{
    cell psrval;
    __asm__ __volatile__ (
	"mrs     %0, cpsr\n\t"
	: "=r"(psrval)
	:
	);
    return psrval;
}
cell wrpsr(cell psrval)
{
    __asm__ __volatile__ (
	"msr     cpsr, %0"
	:
	:"r"(psrval)
	);
}
#define GPIO71_MASK 0x80
#define GPIO72_MASK 0x100
cell kbd_bit_in()
{
    volatile unsigned long *kbdgpio = (unsigned long *)0xd4019008;
    unsigned long regval;
    unsigned long bitval;
    do {
	regval = *kbdgpio;
    } while ((regval & GPIO71_MASK) != 0);

    bitval = (regval & GPIO72_MASK) ? 0x100 : 0;
    
    do {
	regval = *kbdgpio;
    } while ((regval & GPIO71_MASK) == 0);

    return bitval;
}
#define DIR_OUT 0x15
#define DIR_IN 0x18
cell kbd_bit_out(cell bitval)
{
    volatile unsigned long *kbdgpio = (unsigned long *)0xd4019008;
    unsigned long regval;
    do {
	regval = *kbdgpio;
    } while ((regval & GPIO71_MASK) != 0);

    // Seting direction IN pulls up to 1, OUT drives to 0
    kbdgpio[bitval ? DIR_IN : DIR_OUT] = GPIO72_MASK;
    
    do {
	regval = *kbdgpio;
    } while ((regval & GPIO71_MASK) == 0);

    return bitval;
}

cell ps2_devices_adr(void)
{
    return (cell)&ps2_devices;
}
cell one_uart_adr(void)
{
    return (cell)&dbg_uart_only;
}
cell reset_reason_val(void)
{
    extern cell reset_reason;
    return reset_reason;
}

cell version_adr(void)
{
    extern char version[];
    return (cell)version;
}

cell build_date_adr(void)
{
    extern char build_date[];
    return (cell)build_date;
}
extern int kbhit1(void);
extern int kbhit2(void);
extern int kbhit3(void);
extern int kbhit4(void);

cell ((* const ccalls[])()) = {
// Add your own routines here
    (cell (*)())spi_send,        // Entry # 0
    (cell (*)())spi_send_only,   // Entry # 1
    (cell (*)())spi_read_slow,   // Entry # 2
    (cell (*)())spi_read_status, // Entry # 3
    (cell (*)())spi_send_page,   // Entry # 4
    (cell (*)())spi_read,        // Entry # 5
    (cell (*)())lfill,           // Entry # 6
    (cell (*)())lcheck,          // Entry # 7
    (cell (*)())incfill,         // Entry # 8
    (cell (*)())inccheck,        // Entry # 9
    (cell (*)())randomfill,      // Entry # 10
    (cell (*)())randomcheck,     // Entry # 11
    (cell (*)())inflate,         // Entry # 12
    (cell (*)())get_control_reg, // Entry # 13
    (cell (*)())set_control_reg, // Entry # 14
    (cell (*)())get_tcm_size,    // Entry # 15
    (cell (*)())inflate_adr,     // Entry # 16
    (cell (*)())byte_checksum,   // Entry # 17
    (cell (*)())wfi,             // Entry # 18
    (cell (*)())rdpsr,           // Entry # 19
    (cell (*)())wrpsr,           // Entry # 20
    (cell (*)())kbd_bit_in,      // Entry # 21
    (cell (*)())kbd_bit_out,     // Entry # 22
    (cell (*)())ps2_devices_adr, // Entry # 23
    (cell (*)())init_ps2,        // Entry # 24
    (cell (*)())ps2_out,         // Entry # 25
    (cell (*)())one_uart_adr,    // Entry # 26
    (cell (*)())reset_reason_val,// Entry # 27
    (cell (*)())version_adr,     // Entry # 28
    (cell (*)())build_date_adr,  // Entry # 29
    (cell (*)())wfi_loop,        // Entry # 30
    (cell (*)())kbhit1,          // Entry # 31
    (cell (*)())kbhit2,          // Entry # 32
    (cell (*)())kbhit3,          // Entry # 33
    (cell (*)())kbhit4,          // Entry # 34
};


// Forth words to call the above routines may be created by:
//
// system also
// 0 ccall: spi-send     { i.adr i.len -- }

//  1 ccall: byterev  { s.in -- s.out }
//
// and could be used as follows:
//
//  5 6 sum .
//  p" hello"  byterev  count type
