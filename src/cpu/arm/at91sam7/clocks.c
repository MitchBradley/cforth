// Clock initialization for Atmel AT91SAM7

#include "regs.h"
#include "param.h"
#include "pio.h"

//#define SETUP_CLOCKS_HERE

// Peripheral startup code
inline void spin(int n)
{
    while (--n) {}
}

// Enable/disable the clocks to various peripherals
inline void peripheral_clocks_off()
{
    PMC_PCDR  =  SSC_PID;  // PIO clock must stay on for PTT sensing
}

inline void peripheral_clocks_on()
{
    PMC_PCER  =  PIO_PID | SSC_PID;
}

inline void external_clocks_off()
{
    PMC_SCDR  =  SC_UDP | PCK0 | PCK1 | PCK2;
}

inline void external_clocks_on()
{
   PMC_SCER  =  PCK2;
}

void init_external_clocks()
{
  // start ADC clock out  fast, at 4MHz.  throttle down after first
  // batch of samples arrive.  the first bunch of samples out of the ADC
  // are garbage, so we want to get them out of there asap.
  // eventually, set  PMC_PCK0 = CSS_MAIN | PRES(MCLKEXP); 

  PMC_PCK2 = CSS_MAIN | PRES(MCLKEXPSTART);
}

inline void plls_off()
{
    CKGR_PLLR = 0;
}

#define SET_CLOCK(reg, value, rdy_bit, delay) \
    if (reg != value) { \
        reg = value; \
        spin(1000); \
        FAST_MSECS(delay); \
    }
// In principle, one should do this instead of the spin(1000) :
//      while ((PMC_SR && rdy_bit) != 0) \
// For some reason, that doesn't seem to work reliably.  The ready
// bits frequently do not come on, even thought the corresponding
// oscillators and PLLs are in fact running.

#ifdef SETUP_CLOCKS_HERE
void oscillator_on()
{
    // Start the main oscillator, CKGR_MOR page 146, PMC_SR page 154
#define MOR_VAL (OSCOUNT(0xff) | MOSCEN)

  // now set in start.S...
  SET_CLOCK (CKGR_MOR, MOR_VAL, MOSCS, 0);
  //  CKGR_MOR = OSCOUNT(0x04) | MOSCEN;

    // Eventually redundant with the test in SET_CLOCK if it ever works
    do{ } while(!(PMC_SR & MOSCS));
}
#endif


void plls_on()
{ // CKGR_PLLAR page ???

#ifdef SETUP_CLOCKS_HERE
    SET_CLOCK (CKGR_PLLR, PLLR_VAL, LOCK, 10);   // Turn on PLL
#else
    CKGR_PLLR = PLLR_VAL;

    do { 
#if 0
      PIO_SODR = TP2;      
      PIO_CODR = TP2;
#endif
    } while (!(PMC_SR & LOCK));
#endif
}

// PMC_MCKR page ???, PMC_SR page ???
#define FAST_CLOCK_VAL (CSS_PLL | PRES(2))
inline void fast_clock()
{
#ifdef SETUP_CLOCKS_HERE
    SET_CLOCK (PMC_MCKR, FAST_CLOCK_VAL, MCKRDY, 50);
#else
    PMC_MCKR = FAST_CLOCK_VAL; 

    do { 
#if 0
      PIO_SODR = TP1;      
      PIO_CODR = TP1;
#endif
    } while (!(PMC_SR & MCKRDY));
#endif
}

#define SLOW_CLOCK_VAL (CSS_SLOW | PRES(0))
#if 0
inline void slow_clock()
{
    SET_CLOCK (PMC_MCKR, SLOW_CLOCK_VAL, MCKRDY);
}
#else
int slow_clock()
{  // PMC_MCKR page 150, PMC_SR page 154
    int slow_chks = 0;
    long old_pres;
    int i;

    old_pres = PMC_MCKR & PRES(7);
    PMC_MCKR = CSS_SLOW | old_pres;  // Run CPU from slow clock
    for (i = 1000; i--; ) {}

    PMC_MCKR = CSS_SLOW | PRES(0);  // Run CPU from slow clock
    while ((PMC_SR & MCKRDY) == 0)
    {
        if (slow_chks++ > 1000) break;
    }
    //?? need to wait 2 ticks before turning off Osc or PLLs
    SLOW_MSECS(1);
    return(slow_chks);
}

// -O1 might be interesting
// asm("nop; nop; nop; nop;");
int slow_clock_debug()
{  // PMC_MCKR page 150, PMC_SR page 154
    int slow_chks = 0;
    PMC_MCKR = CSS_SLOW | PRES(0);  // Run CPU from slow clock
    SLOW_MSECS(1);
    while ((PMC_SR & MCKRDY) == 0)
    {
        if (slow_chks++ > 100) break;
    }
    //?? need to wait 2 ticks before turning off Osc or PLLs
    return(slow_chks);
}
#endif

#define MAIN_CLOCK_VAL CSS_MAIN | PRES(0)
inline void main_clock()
{
    do{ 
#if 0
      PIO_SODR = TP1;      
      PIO_CODR = TP1;
#endif
    } while(!(PMC_SR & MOSCS));

    //    SET_CLOCK (PMC_MCKR, MAIN_CLOCK_VAL, MCKRDY, 0);
    PMC_MCKR = MAIN_CLOCK_VAL;

#if 0
    PIO_SODR = TP1;      
    PIO_CODR = TP1;
#endif
}

void main_clock_off()
{
    CKGR_MOR = 0;
}

void init_clocks()
{
#ifdef SETUP_CLOCKS_HERE
    slow_clock();

    oscillator_on();

    main_clock();
    plls_off();
    FAST_MSECS(10);
    plls_on();
    fast_clock();
#endif
    init_external_clocks();
    external_clocks_on();     // start MCLK running for codec
}
