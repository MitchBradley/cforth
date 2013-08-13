// Things that we get to choose about how we set up the chip - mostly
// clock frequencies established by dividers or PLLs.

// Main Clock (aka OSC) runs at 16.384 MHz
// #define MAINCLKFREQ 1638400  // Crystal frequency

// Page 454 says PLLs run at 80-160 MHz

// PLL runs at 116.508416 MHz
// Divide PLLout by 4 to get 29.127104 MHz MCK for CPU,
// Divide MCK by 32 to get 910,222 for IR (off by 0.02%)
// Divide MCK by 16 to get 1,820,444 for UART (1.3% off vs. 1,843,000)
#define PLLDIVVAL   8 // 16,384,000 /  8 =   2,048,000
#define PLLMULVAL  64 //  1,820,444 * 64 = 131,072,000 (PLLout)
#define PLLR_VAL \
    (PLLMUL(PLLMULVAL) | PLLDIV(PLLDIVVAL) | PLLCOUNT(PLLDELAY))

// This is a little faster than the spec but it's necessary for the DAC
#define MCLK_FREQ   32768000
#define MCLK_MHZ    (MCLK_FREQ / 1000000)

#define BAUD_115200  18 // 32,768,000 /  18 / 16 = 113,778 (1.3% below 115,200)
#define BAUD_38400   53 // 32,768,000 /  53 / 16 =  38,641 (0.6% above  38,400)
#define BAUD_19200  107 // 32,768,000 / 107 / 16 =  19,140 (0.3% below  19,200)
#define BAUD_9600   213 // 32,768,000 / 213 / 16 =   9,615 (0.2% above   9,600)
#define BAUDDIVISOR BAUD_115200

// PLL startup delay
//  Max is 3f.  This looked conservative on a scope.
#define PLLDELAY 0x1f

// TC1 drives IR link via the TIOB1 output
// IR link runs at 455 KHz cycles/second
// We send bits at 2x that, 2 bits per cycle
//   32 bits of 10101010... is 16 cycles of carrier.
// MCK is 29,127,104; divide that by 32 to get 910,222 (0.2% above 910,000)
#define TC1SEL_VAL  1     // Select TIMER_CLOCK2 which is MCK/8
// According to the manual, we should have to adjust these divisors by -1,
// but empirically these unmodified values give the right result.  Perhaps
// we don't understand the manual...
#define TC1RC_VAL   4     // Divide by 4 again to get MCK/32
#define TC1RB_VAL   2     // Divide by 2 to get the half-cycle

#define CMRVAL (TCCLKS(TC1SEL_VAL) | WAVESEL(2) | WAVE | BCPB(1) | BCPC(2))


// PCK0 drives ADC/MCLK from Main clock (OSC)
// clock at one freq for a fixed short amount of time to get codec
// thru troublesome start-up phase, then reduce clock to something
// that gets us 8kHz.
#define MCLKEXPSTART 2 // 16,384,000 / 4 = 4,096,000 = 32,000 * 128
#define MCLKEXP      3 // 16,384,000 / 8 = 2,048,000 = 16,000 * 128

// flash mem location for hardware rev and serial numbers
#define ID_LOC 0xFF80
// here's how we read from this location
#define fl_read(offset)  *((unsigned char *)0x100000 + offset)


// Debugging

// Size of audio buffers - 2 bytes per sample
// Each 1K of samples (2K of memory) holds 64 ms (at 16K samples/second)
// Setup to use 2 buffers: 2*4K is 1/2 second
#define ABUF_SIZE 1000

