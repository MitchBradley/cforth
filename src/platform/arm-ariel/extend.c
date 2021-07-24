/* Based on src/platform/arm-xo-1.75/extend.c */

#include "forth.h"

void spi_read(cell offset, cell len, cell adr);
cell inflate(cell wpptr, cell nohdr, cell clear, cell compr);
extern int dbg_uart_only;

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
extern int kbhit3(void);

cell ((* const ccalls[])()) = {
  C(spi_send)        //c spi-send        { a.adr i.len -- }
  C(spi_send_only)   //c spi-send-only   { a.adr i.len -- }
  C(spi_read_slow)   //c spi-read-slow   { a.adr i.len i.offset -- }
  C(spi_read_status) //c spi-read-status { -- i.status }
  C(spi_send_page)   //c spi-send-page   { a.adr i.len i.offset -- }
  C(spi_read)        //c spi-read        { a.adr i.len i.offset -- }
  C(lfill)           //c lfill           { a.adr i.len i.value -- }
  C(lcheck)          //c lcheck          { a.adr i.len i.value -- i.erraddr }
  C(incfill)         //c inc-fill        { a.adr i.len -- }
  C(inccheck)        //c inc-check       { a.adr i.len -- i.erraddr }
  C(randomfill)      //c random-fill     { a.adr i.len -- }
  C(randomcheck)     //c random-check    { a.adr i.len -- i.erraddr }
  C(inflate)         //c (inflate)       { a.compadr a.expadr i.nohdr a.workadr -- i.expsize }
  C(get_control_reg) //c control@        { -- i.value }
  C(set_control_reg) //c control!        { i.value -- }
  C(get_tcm_size)    //c tcm-size@       { -- i.value }
  C(inflate_adr)     //c inflate-adr     { -- a.value }
  C(byte_checksum)   //c byte-checksum   { a.adr i.len -- i.checksum }
  C(wfi)             //c wfi             { -- }
  C(rdpsr)           //c psr@            { -- i.value }
  C(wrpsr)           //c psr!            { i.value -- }
  C(one_uart_adr)    //c 'one-uart       { -- a.value }
  C(reset_reason_val)//c reset-reason    { -- i.value }
  C(version_adr)     //c 'version        { -- a.value }
  C(build_date_adr)  //c 'build-date     { -- a.value }
  C(wfi_loop)        //c wfi-loop        { -- }
  C(kbhit3)          //c ukey3?          { -- i.value }
};
