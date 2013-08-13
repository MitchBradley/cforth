// Sine wave generation by table lookup, with frequency selection
// limited to multiples of the FFT bin size.
//
// For example, assume that the sampling frequency is 16 KHz, and the
// results will ultimately be processed with a 512-point FFT.  The
// frequency bins are thus at multiples of 16000/512 = 31.25, i.e
// 0, 31.25, 62.5, 96.75, 125, ...
//
// If we generate test tones at only those frequencies, we won't have
// any spectral leakage.  Generating such test tones requires sampling
// a sinusoid at multiples of one cycle / FFTLEN , so we can do table
// lookup on a table of FFTLEN/4 points (the factor of 4 reduction comes
// from  symmetries of sinusoids).

// We further assume that FFTLEN is a power of two, thus allowing us to
// use efficient bit-masking operations to calculate phase intervals.

#include "types.h"

#define PI 3.14159265357987

#define LOG2FFTLEN 9

#define FFTLEN (1<<LOG2FFTLEN)

// We calculate the table to twice the resolution so we can generate
// clean tones at the boundaries between FFT bins
#define CYCLE (FFTLEN * 2)
#define CYCLE_MASK (CYCLE-1)

#define HALF_CYCLE (CYCLE/2)
#define HALF_MASK (HALF_CYCLE-1)

#define QUARTER_CYCLE (CYCLE/4)
#define QUARTER_MASK (QUARTER_CYCLE-1)

#ifdef GENERATE_TABLE

main()
{
    int i;
    double phaseinc = (2 * PI / CYCLE);
    printf("/* Automatically generated */\n");
    printf("const unsigned short sin_table[] = {\n");
    for (i = 0; i <= QUARTER_CYCLE; i++) {
      printf("0x%04x,\n", (short)(sin(phaseinc * i) * 32767 + 0.5));
    }
    printf("};\n");
    return 0;
}

#else

extern unsigned short sin_table[QUARTER_CYCLE+1];

short phase_to_sin(unsigned int phase)
{
    int negate;
    unsigned int index;
    unsigned int residue;
    unsigned int diff;
    unsigned short result;

    phase &= CYCLE_MASK;  // Reduce to the range 0..2pi

    if (negate = (phase & HALF_CYCLE)) {  // symmetry:  sin(pi + n) = -sin(n)
        phase &= HALF_MASK;
    }

    if (phase > QUARTER_CYCLE) {          // symmetry:  sin(pi - n) = sin(n)
        phase = HALF_CYCLE - phase;
    }

    result = sin_table[phase];

    return (negate ? -(short)result : (short)result);
}

typedef struct {
    unsigned short phase;
    unsigned short stride;
} tone_t;

#define SAMPLE_RATE 16000
#define FREQ_NUM 16000
#define FREQ_DEN 512  // FFT lenth, i.e. number of bins

void
tone_setup(unsigned int bin, tone_t *tone)
{
    // Shift the phase by a quarter cycle thus generating cos() instead of
    // sin().  This makes things work better if bin=FFTLEN/2 .  We could
    // have stored the table as cos() instead of sin(), but then the
    // symmetry calculations would have been slightly more difficult.
    tone->phase = QUARTER_CYCLE;
    tone->stride = bin;
}

short next_sample(tone_t *tone)
{
    short retval;

    retval = phase_to_sin(tone->phase);
    tone->phase += tone->stride;
    return retval;
}

#define MAXTONES 30
static int ntones;
static tone_t tones[30];

void setup_tones(int nbins, u_short *bins) {
    int i;
    if (nbins > MAXTONES) {
        nbins = MAXTONES;
    }
    ntones = nbins;
    for (i = 0; i < nbins; i++) {
        tone_setup((unsigned int)bins[i], &tones[i]);
    }
}

short tones_next()
{
    int i;
    int accum;

    if (ntones == 1) {  // Pointless Optimization
        return next_sample(&tones[0]);
    }

    accum = 0;
    for (i=0; i<ntones; i++) {
        accum += (int)next_sample(&tones[i]);
    }
    accum /= ntones;
    return (short)accum;
}


#ifdef TEST_ME

#include <math.h>
double round(double);
double cos(double);

main()
{
    int bin;
    int i, where;
    double max_error;
    double t1, t2, diff;

    double phase = 0;
    double phaseinc;
    tone_t t;

    bin = 3;
    tone_setup(bin, &t);

    phase = 0.0;
    phaseinc = (2 * PI * bin / FFTLEN);

    where = 0;
    max_error = 0;

    for (i = 0; i < FFTLEN; i++ ) {
        t1 = next_sample(&t);
        t2 = round(cos(phase) * 32767);
        diff = t2 - t1;
        if (diff < 0)
            diff = -diff;
        printf("%d %.1f %.1f %.2f\n", i, t1, t2, diff); 
        if (diff > max_error) {
            where = i;
            max_error = diff;
        }
        phase += phaseinc;
    }
    printf("Max error = %f at %d\n", max_error, where);
}
#endif

#endif
