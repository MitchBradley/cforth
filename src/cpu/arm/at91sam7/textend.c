// This is an example for how you can include some C routines that
// can be called as Forth words.  See "ccalls" below.

#include "types.h"   // u_xxx shorthands for unsigned xxx

#include "forth.h"

// Prototypes

cell index_fetch(void);
void index_store(unsigned cell n);
cell data_fetch(void);
void data_store(unsigned cell n);

void ram_serial_to_flash(u_char *);
void ram_erase_flash_range(int, u_char *);
void ram_write_flash_range(int, u_char *, u_char *);
char *xtoa(int, int);

// int rem_navail();
int rem_mayget();
u_char rem_key();
void rem_emit(u_char);
void rem_init();

int rcv_navail();
u_char rcv_key();
void rcv_emit(u_char);
void rcv_init();

int dbgu_mayget();
u_char ukey();
void raw_putchar(u_char);

void shift_lsbs(int, int, int, unsigned long);
unsigned long shift_33msbs(int, unsigned long);
unsigned char spi_byte(unsigned char);
unsigned char fast_spi_byte(unsigned char);
void rf_write(int, int, unsigned char *);
void rf_read(int, int, unsigned char *);

void psoc_clocks(int);
void psoc_bits(int nbits, int data);
unsigned char psoc_read_byte();

int  end_addr(void);

#if 0
int realfft(int *input, int *output, int logN);
void psoc_poll();
void capture(unsigned char *, int, int, int, int);
void vectors(unsigned long *, int);
#endif

void setup_tones(int, int*);
short tones_next();

cell ((* const ccalls[])()) = {
    // Add your own routines here
    C(index_fetch)          //c cindex@      { -- i.byte }
    C(index_store)          //c cindex!      { i.byte -- }
    C(data_fetch)           //c cdata@       { -- i.byte }
    C(data_store)           //c cdata!       { i.byte -- }

    C(ram_serial_to_flash)  //c serial-flash { a.flash-adr -- i.length }
    C(ram_erase_flash_range)//c erase-flash  { a.flash-adr i.len -- i.length }
    C(ram_write_flash_range)//c write-flash  { a.buf a.flash-adr i.len -- i.length }

    C(rem_mayget)           //c rem-mayget   { a.buf -- i.gotone? }
    C(rem_key)              //c rem-key      { -- i.char }
    C(rem_emit)             //c rem-emit     { i.char -- }
    C(rem_init)             //c rem-init     { -- }

    C(rcv_navail)           //c rcv-key?     { -- i.numavail }
    C(rcv_key)              //c rcv-key      { -- i.char }
    C(rcv_emit)             //c rcv-emit     { i.char -- }
    C(rcv_init)             //c rcv-init     { -- }

    C(dbgu_mayget)          //c dbgu-mayget  { a.buf -- i.gotone? }
    C(ukey)                 //c dbgu-key     { -- i.char }
    C(raw_putchar)          //c dbgu-emit    { i.char -- }

    C(xtoa)                 //c xtoa         { i.digits i.num -- a.cstr }

    C(setup_tones)          //c setup-tones  { a.bins a.nbins -- }
    C(tones_next)           //c tones-next   { -- i.sample }

    C(shift_lsbs)           //c shift-lsbs   { i.bits i.nbits i.last i.first -- i.bits }
    C(shift_33msbs)         //c shift-33msbs { i.bits i.first -- i.bits }
    C(spi_byte)             //c spi-byte     { i.write -- i.read }
    C(psoc_clocks)          //c psoc-poll    { -- }
    C(psoc_bits)            //c capture      { i.delay i.match i.mask i.len a.adr -- }
    C(psoc_read_byte)       //c vectors      { i.num a.adr -- }
    C(fast_spi_byte)        //c fast-spi-write { i.write -- i.read }
    C(rf_write)             //c rf-write     { a.buf i.len i.? -- )
    C(rf_read)              //c rf-read      { a.buf i.len i.? -- )

    C(end_addr)             //c end-addr     { -- i }

#if 0
    C(realfft)              //c realfft      { i.logn a.out a.in -- i.val }
    C(psoc_poll)            //c psoc-poll    { -- }
    C(capture)              //c capture      { i.? i.? i.? i.? a.? -- }
    C(vectors)              //c vectors      { i.? a.? -- }
#endif
};
