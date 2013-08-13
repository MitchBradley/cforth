//  Low-level interface to the JTAG tap controller hardware.

#include "types.h"
#include "jtag.h"
#include "ports.h"

#include "pio.h"

#define CLK_HIGH  PIO_SODR = MASK(TCK_BIT);
#define CLK_LOW   PIO_CODR = MASK(TCK_BIT);
#define PULSE  CLK_HIGH;  CLK_LOW;

inline void TMS_HIGH()
{
    PIO_SODR = MASK(TMS_BIT);
}

inline void TDI_LOW()
{
    PIO_CODR = MASK(TDI_BIT);
}

// Shift the LSB of bits into the JTAG scan chain, shift bits right,
// and put the JTAG scan chain output into the MSB of bits

inline u_long lsbit(u_long bits)
{
    if (bits & 1)                    // Set or clear TDI
        PIO_SODR = MASK(TDI_BIT);
    else
        PIO_CODR = MASK(TDI_BIT);
    
    CLK_HIGH;                        // Set TCK
    bits >>= 1;

    if( PIO_PDSR & MASK(TDO_BIT) ) { // Test TDO
        bits |= 0x80000000;
    }
    CLK_LOW;                         // Clear TCK

    return bits;
}

// Shift the MSB of bits into the JTAG scan chain, shift bits left,
// and put the JTAG scan chain output into the LSB of bits

inline u_long msbit(u_long bits)
{
    if (bits & 0x80000000)
        PIO_SODR = MASK(TDI_BIT);
    else
        PIO_CODR = MASK(TDI_BIT);

    CLK_HIGH;
    bits <<= 1;
        
    if( PIO_PDSR & MASK(TDO_BIT) ) {
        bits |= 1;
    }
    CLK_LOW;

    return bits;
}

// If first is true, advance the JTAG state machine to the Shift-DR state.
// Shift nbits, LSB first, between bits and the JTAG scan chain.
// If last is true, set TMS, shift one more bit, and pulse the clock
// again, thus leaving the JTAG state machine in the Update-DR state.
// (If last is false, the state machine remains in the Shift-DR state.)

u_long shift_lsbs(int first, int last, int nbits, u_long bits)
{
    if (first) {
        // Start in Run-Test/Idle, Update-DR, or Update-IR state
        PIO_SODR = MASK(TMS_BIT);  PULSE;           // One to Select-DR-Scan
        PIO_CODR = MASK(TMS_BIT);  PULSE;  PULSE;   // Zero to Shift-DR
    }

    while (nbits--) {
        bits = lsbit(bits);
    }

    if (last) {
        PIO_SODR = MASK(TMS_BIT);        // One to Exit1-DR state
        bits = lsbit(bits);
        PULSE;                           // One to update-dr state
    }
    return bits;
}

// Advance the JTAG state machine to the Shift-DR state.
// Shift the LSB of breakpt into the JTAG scan chain, discarding the output.
// Shift 32 bits, MSB first, of bits into the JTAG scan chain, capturing the
// output.  On the last of those bits, set TMS, and then pulse the clock
// again, thus leaving the JTAG state machine in the Update-DR state.

u_long shift_33msbs(int breakpt, u_long bits)
{
    u_long mask;
    int nbits;
    
    PIO_SODR = MASK(TMS_BIT);  PULSE;           // to select-dr-scan state
    PIO_CODR = MASK(TMS_BIT);  PULSE;  PULSE;   // to shift-dr state

    (void)lsbit(breakpt);

    for (nbits=32; nbits; nbits--) {
        if (nbits == 1) {                 // to exit1-dr state
            PIO_SODR = MASK(TMS_BIT);
        }
        bits = msbit(bits);
    }
    PULSE;                               // to update-dr state
    PIO_CODR = MASK(TMS_BIT);  PULSE;    // to run-test/idle state
    return bits;
}

u_char spi_byte(u_char write_byte)
{
    u_char read_byte;
    int mask;
    int count;
    read_byte = 0;
    for (mask = 0x80; mask; mask >>= 1) {
        read_byte <<= 1;
        if (write_byte & mask) {
            PIO_SODR = MASK(TDI_BIT);   // Same as MOSI
        } else {
            PIO_CODR = MASK(TDI_BIT);   // Same as MOSI
        }

        // Do this several times to slow down the SPI clock,
        // thus meeting the AVR's timing requirements even when
        // it is running from its 1 MHz RC oscillator.
        // Empirically, counting to 4 (here and below) is good
        // enough, at least on one sample, but I made it 10 just
        // in case.  The programming time penalty is about 0.4 sec.
        // The SPI clock period is 4.86 us with the 10 count.
        for (count = 0; count < 10; count++) {
            CLK_HIGH;
        }

        if( PIO_PDSR & MASK(TDO_BIT) ) {
            read_byte |= 1;
        }

        for (count = 0; count < 10; count++) {
            CLK_LOW;
        }
    }

    return read_byte;
}

u_char fast_spi_byte(u_char write_byte)
{
    u_char read_byte;
    int mask;
    read_byte = 0;
    for (mask = 0x80; mask; mask >>= 1) {
        read_byte <<= 1;
        if (write_byte & mask) {
            PIO_SODR = MASK(TDI_BIT);   // Same as MOSI
        } else {
            PIO_CODR = MASK(TDI_BIT);   // Same as MOSI
        }

        CLK_HIGH;

        if( PIO_PDSR & MASK(TDO_BIT) ) {
            read_byte |= 1;
        }

        CLK_LOW;
    }

    return read_byte;
}

void rf_read(int reg, int len, u_char *adr)
{
    int mask;
    u_char write_byte;
    u_char read_byte;
    
    PIO_CODR = MASK(PTT_BIT);   // Same as NSS
    write_byte = reg;
    
    for (mask = 0x80; mask; mask >>= 1) {
        if (write_byte & mask) {
            PIO_SODR = MASK(TDI_BIT);   // Same as MOSI
            CLK_LOW;
        } else {
            PIO_CODR = MASK(TDI_BIT) | MASK(TCK_BIT);   // Same as MOSI
        }
        CLK_HIGH;
    }
    CLK_LOW;
    
    while (len--) {
        read_byte = 0;

        for (mask = 8; mask--; ) {
            read_byte <<= 1;
            CLK_HIGH;
            if( PIO_PDSR & MASK(TDO_BIT) ) {
                read_byte |= 1;
            }
            CLK_LOW;
        }
        *adr++ = read_byte;
    }
    PIO_SODR = MASK(PTT_BIT);   // Same as NSS
}

void rf_write(int reg, int len, u_char *adr)
{
    int mask;
    u_char write_byte;
    
    PIO_CODR = MASK(PTT_BIT);   // Same as NSS
    write_byte = reg | 0x80;
    
    for (mask = 0x80; mask; mask >>= 1) {
        if (write_byte & mask) {
            PIO_SODR = MASK(TDI_BIT);   // Same as MOSI
            CLK_LOW;
        } else {
            PIO_CODR = MASK(TDI_BIT) | MASK(TCK_BIT);   // Same as MOSI
        }
        CLK_HIGH;
    }
    
    while (len--) {
        write_byte = *adr++;

        for (mask = 0x80; mask; mask >>= 1) {
            if (write_byte & mask) {
                PIO_SODR = MASK(TDI_BIT);   // Same as MOSI
                CLK_LOW;
            } else {
                PIO_CODR = MASK(TDI_BIT) | MASK(TCK_BIT);   // Same as MOSI
            }
            CLK_HIGH;
        }
    }
    CLK_LOW;
    PIO_SODR = MASK(PTT_BIT);   // Same as NSS
}

void psoc_bits(int nbits, int data)
{
    unsigned int mask;
    PIO_OER = MASK(TDI_BIT);   // Drive data
    for (mask = 1 << nbits; (mask >>= 1) != 0;  ) {
        if (data & mask)
            PIO_SODR = MASK(TDI_BIT);
        else
            PIO_CODR = MASK(TDI_BIT);
        PIO_SODR = MASK(TCK_BIT);
        PIO_CODR = MASK(TCK_BIT);
    }
    PIO_CODR = MASK(TDI_BIT);  // Force data low before floating it
    PIO_ODR = MASK(TDI_BIT);   // Float data
}

void psoc_clocks(int nclocks)
{
    int i;
    while (nclocks--) {
        // The nop's limit the clock frequency to 1.5 MHz per the Fsclk spec
        CLK_HIGH;
        asm("nop"); asm("nop"); asm("nop"); asm("nop"); asm("nop"); asm("nop");
        CLK_LOW;
        asm("nop"); asm("nop"); asm("nop"); asm("nop");
    }
}

unsigned char psoc_read_byte()
{
    unsigned char data;
    int i;
    psoc_clocks(2);            // Turnaround time
    data = 0;
    for (i = 8; i--; ) {
        PIO_SODR = MASK(TCK_BIT);
        data <<= 1;
        if (PIO_PDSR & MASK(TDI_BIT))
            data |= 1;
        PIO_CODR = MASK(TCK_BIT);
    }
    PIO_SODR = MASK(TDI_BIT);  // Set bit
    PIO_OER = MASK(TDI_BIT);   // Enable driver
    psoc_clocks(1);            // Clock it out
    PIO_CODR = MASK(TDI_BIT);  // Force line down
    PIO_ODR = MASK(TDI_BIT);   // Disable driver
    return data;
}

#if 0
void psoc_poll(int temp)
{
    int reg;
    temp = 0;
    // XXX switch to input mode
    do {
        CLK_HIGH;
        reg = PIO_PDSR;
        CLK_LOW;
        if( (reg & MASK(TDO_BIT)) == 0) {
            return;
        }
    } while(--temp);
}

#define SMALL_GAP 10

long grab_bits(int nbits)
{
    long value;
    int gap;
    unsigned long reg;
    unsigned long preg;

    value = 0;

    while (nbits--) {
        gap = 20000000;
        while (1) {
            reg = PIO_PDSR;
            if (reg & MASK(TCK_BIT))
                break;
            if (--gap <= 0)
                return -1;
        }

        // Capture the data value before the falling edge
        do {
            preg = reg;
            reg = PIO_PDSR;
        } while (reg & MASK(TCK_BIT));
        
        value <<= 1;
        if (preg & MASK(TDI_BIT))
            value |= 1;
    }
    return value;
}

int vectors(long *adr, int num)
{
    long value;
    int gap;

    gap = 20000000;
    while (!(PIO_PDSR & MASK(TDI_BIT))) {
        if (--gap <= 0) {
            return -3;
        }
    }

    while (num) {
        value = grab_bits(22);
        if (value == -1) {
            return num;
        }
        *adr++ = value;
        num--;
        if (!value) {
            gap = 20000000;
            while (!(PIO_PDSR & MASK(TDI_BIT))) {
                if (--gap <= 0) {
                    return -3;
                }
            }
        }
    }
    return num;
}

int bit_capture(unsigned long *adr, int gap, int len)
{
    unsigned long reg;
    unsigned long value;
    int small_gap;
    int i;
    int bitcount;

    while (!(PIO_PDSR & MASK(TCK_BIT)))
        ;

    bitcount = 0;
    value = 0;
    while (len > 0) {
        // Start with clock high; wait for it to go low
        do {
            reg = PIO_PDSR;
        } while (reg & MASK(TCK_BIT));
        
        // Capture the data value on the falling edge
        value <<= 1;

        if (reg & MASK(TDI_BIT))
            value |= 1;

        if (++bitcount == 24) {
            value |= (bitcount << 24);
            *adr++ = value;
            value = 0;
            bitcount = 0;
            len -= 4;
        }
        
        i = 0;
        while (!(PIO_PDSR & MASK(TCK_BIT))) {
            if (++i == SMALL_GAP && bitcount) {
                value |= (bitcount << 24);
                *adr++ = value;
                value = 0;
                bitcount = 0;
                len -= 4;
            }
            if (i == gap) {
                return len;
            }
        }
    }
}
#endif

#if 0
u_long shift_out(u_int data_bit, u_int clock_bit, u_long bits, int nbits)
{

}
    
void state_transition(u_long bits, int nbits)
{
    (void)shift_out(MASK(TMS_BIT), MASK(TCK_BIT), bits, nbits);
}

// Generic JTAG state machine transitions

typedef unsigned char BYTE;

int current_scan_chain;
int last_jtag_instruction;

void shift_dr()
{
    state_transition(0x1, 3);  // 1,0,0
}

void exit1_to_update()
{
    state_transition(0x1, 1);  // 1
}
       
void update_to_idle()
{
    state_transition(0x0, 1);  // 0
}

void exit1_to_idle()
{
     state_transition(0x1, 2);  // 1,0 
}

void test_logic_reset()
{
    // 5 ones gets to test_logic_reset from anywhere, then 0 to run-test/idle
    state_transition(0x1f, 6);
    current_scan_chain = -1;
    last_jtag_instruction = -1;
}

void jtag_instruction(u_long n)
{
    unsigned char final;
    last_jtag_instruction = n;
    state_transition(0x3, 4);      // shift_ir
    n = put_lsbs(3, n);
    TMS_HIGH;
    (void)put_lsbs(1, n);
    exit1_to_update();               // update_ir
}

// Switch back to system state from debug state
// The RESTART takes effect upon entry to run_test_idle state

void jtag_restart()
{
    jtag_instruction(4);
    update_to_idle();
}

void select_scan_chain(u_int n)
{
    if (n != current_scan_chain) {
        current_scan_chain = n;
        jtag_instruction(2);    // SCAN_N instruction
        shift_dr();
        n = put_lsbs(3, n);
        TMS_HIGH;
        put_lsbs(1, n);
        exit1_to_update();
    }
    if ( last_jtag_instruction != 0xc ) {
        jtag_instruction(0xc);    // INTEST instruction
    }
}

void start_jtag()
{
}
#endif
