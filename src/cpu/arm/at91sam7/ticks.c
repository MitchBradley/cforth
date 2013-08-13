#include "regs.h"

// The ticker runs at 32kHz, so we can shift 5 one way to get about 1 ms,
// and 5 the other way to get about 1 us.
#define MSECS_SHIFT 5
#define USECS_SHIFT 5

inline void init_rtt()
{
// Setup RTT as a ticker
    RTT_MR = RTTRST | RTPRES(1);     // Divide by 1; resolution 1/32 ms
}

// Don't call this when slow clock is in effect; it may never return.
int get_ticks()
{
    unsigned int n1, n2;

    // The counter is updated asynchronously with respect to the processor
    // clock, so any given sample can give a wrong answer.  Reread until
    // we get a consistent pair of samples.
    n1 = RTT_VR;
    while((n2 = RTT_VR) != n1) {
        n1 = n2;
    }
    return (int)n1;
}

void delay_usecs(int us)
{
	register int endtime;

    endtime = get_ticks() + ((us >> USECS_SHIFT) + 1);
    
    do {
    } while ((endtime - get_ticks()) > 0);
}


void delay_msecs(int ms)
{
	register int endtime;

    endtime = get_ticks() + (ms << MSECS_SHIFT);
    
    do {
    } while ((endtime - get_ticks()) > 0);
}

void safe_delay_msecs(int ms)
{
	register int endtime;
    unsigned char b;

    endtime = get_ticks() + (ms << MSECS_SHIFT);
    
    do {
        int now;
        if ( dbgu_mayget(&b) ) {
            now = get_ticks();
            dotn(now); dotn(endtime);
            return;
        }
    } while ((endtime - get_ticks()) > 0);
}

int ticks_to_msecs(int t)
{
    return (t >> MSECS_SHIFT);
}

int msecs_to_ticks(int m)
{
    return (m << MSECS_SHIFT);
}

// 1,000,000 / 32768 = 30.518  or about 61/2
unsigned int ticks_to_usecs(unsigned int t)
{
    t *= 61;
    return (t/2);
}
