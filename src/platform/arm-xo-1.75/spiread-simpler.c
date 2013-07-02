
#define cell long

#define CS_LOW      *(volatile unsigned long *)0xd4019028 = 0x00004000
#define CS_HIGH     *(volatile unsigned long *)0xd401901c = 0x00004000
#define GPIO46_OUT  *(volatile unsigned long *)0xd4019058 = 0x00004000
#define GPIO46_IS_GPIO  *(volatile unsigned long *)0xd401e10c = 0xc0;
#define GPIO46_IS_SSP1  *(volatile unsigned long *)0xd401e10c = 0xc3;
void spi_read(cell offset, cell len, cell adr)
{
    unsigned char *p = (unsigned char *)adr;
    int cansend, i;
    volatile unsigned long *fifo = (volatile unsigned long *)0xd4035010;
    volatile unsigned long *stat = (volatile unsigned long *)0xd4035008;
    unsigned long regval;

    CS_HIGH;
    GPIO46_OUT;
    GPIO46_IS_GPIO;

    CS_LOW;
    *fifo = (unsigned long)0x03;
    *fifo = (offset >> 16) & 0xff;
    *fifo = (offset >>  8) & 0xff;
    *fifo = offset  & 0xff;
    *fifo = 0;           // One extra to pipeline the reads
    *fifo = 0;           // One extra to pipeline the reads
    for (i=0; i<4; i++) {
        while ((*stat & 8) == 0) ;
        regval = *fifo;  // Discard readback from cmd and adr bytes
    }

    while (len > 0) {
        *fifo = 0;           // One extra to pipeline the reads

        while ((*stat & 8) == 0) ;
        regval = *fifo;  // Discard readback from cmd and adr bytes

        *p++ = (unsigned char)regval;
        len--;
    }

    while ((*stat & 8) == 0) ;
    regval = *fifo;  // Discard readback from cmd and adr bytes

    while ((*stat & 8) == 0) ;
    regval = *fifo;  // Discard readback from cmd and adr bytes

    CS_HIGH;
}
