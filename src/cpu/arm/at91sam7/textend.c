// This is an example for how you can include some C routines that
// can be called as Forth words.  See "ccalls" below.

#include "types.h"   // u_xxx shorthands for unsigned xxx

// This is the only thing that we need from forth.h
#define cell long

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
void tx(u_char);

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
    (cell (*)())index_fetch,          // Entry # 0
    (cell (*)())index_store,          // Entry # 1
    (cell (*)())data_fetch,           // Entry # 2
    (cell (*)())data_store,           // Entry # 3

    (cell (*)())ram_serial_to_flash,  // Entry # 4
    (cell (*)())ram_erase_flash_range,// Entry # 5
    (cell (*)())ram_write_flash_range, // Entry # 6

    (cell (*)())rem_mayget,           // Entry # 7
    (cell (*)())rem_key,              // Entry # 8
    (cell (*)())rem_emit,             // Entry # 9
    (cell (*)())rem_init,             // Entry # 10

    (cell (*)())rcv_navail,           // Entry # 11
    (cell (*)())rcv_key,              // Entry # 12
    (cell (*)())rcv_emit,             // Entry # 13
    (cell (*)())rcv_init,             // Entry # 14

    (cell (*)())dbgu_mayget,          // Entry # 15
    (cell (*)())ukey,                 // Entry # 16
    (cell (*)())tx,                   // Entry # 17

    (cell (*)())xtoa,                 // Entry # 18

    (cell (*)())setup_tones,          // Entry # 19
    (cell (*)())tones_next,           // Entry # 20

    (cell (*)())shift_lsbs,           // Entry # 21
    (cell (*)())shift_33msbs,         // Entry # 22
    (cell (*)())spi_byte,             // Entry # 23
    (cell (*)())psoc_clocks,          // Entry # 24
    (cell (*)())psoc_bits,            // Entry # 25
    (cell (*)())psoc_read_byte,       // Entry # 26
    (cell (*)())fast_spi_byte,        // Entry # 27
    (cell (*)())rf_write,             // Entry # 28
    (cell (*)())rf_read,              // Entry # 29

    (cell (*)())end_addr,             // Entry # 30

#if 0
    (cell (*)())realfft,              // Entry # 28

    (cell (*)())psoc_poll,            // Entry # 29
    (cell (*)())capture,              // Entry # 30
    (cell (*)())vectors,              // Entry # 31
#endif
};

// Forth words to call the above routines may be created by:
//
//  system also
//  0 ccall: sum      { i.a i.b -- i.sum }
//  1 ccall: byterev  { s.in -- s.out }
//
// and could be used as follows:
//
//  5 6 sum .
//  p" hello"  byterev  count type
