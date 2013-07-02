// This is the only thing that we need from forth.h
#define cell long

#define FCHUNK 15
void spi_read(cell offset, cell len, cell adr)
{
    unsigned char *p = (unsigned char *)adr;
    int cansend, i;
    volatile unsigned long *fifo = (volatile unsigned long *)0xd4035010;
    volatile unsigned long *stat = (volatile unsigned long *)0xd4035008;
    unsigned long regval;
    *(volatile unsigned long *)0xd4035000 = 0x0010000f;  // 32-bit, not enabled
    *(volatile unsigned long *)0xd4035000 = 0x0010008f;  // 32-bit, enabled
    while (len > 0) {
        *fifo = (0x03 << 24) | offset;
        cansend = (len < (FCHUNK * 4)) ? (len/4) : FCHUNK;
        for(i = cansend; i; i--) {
            *fifo = 0;
        }
        while ((*stat & 8) == 0)
            ;
        regval = *fifo;  // Discard readback from cmd and adr bytes

        for(i = cansend; i; i--) {
            while ((*stat & 8) == 0)
                ;
            regval = *fifo;
            *p++ = (regval >> 24) & 0xff;
            *p++ = (regval >> 16) & 0xff;
            *p++ = (regval >> 8) & 0xff;
            *p++ = regval & 0xff;
        }
        len -= (cansend * 4);
        offset += (cansend * 4);
    }
    *(volatile unsigned long *)0xd4035000 = 0x00000007;  // 8-bit, not enabled
    *(volatile unsigned long *)0xd4035000 = 0x00000087;  // 8-bit, enabled
}

