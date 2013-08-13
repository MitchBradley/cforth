XXX The tone generation code is currently unfinished.  The sine wave lookup
and interpolation does work.

// Sine wave generation by table lookup and linear interpolation

// We choose our units in phase space so that one full cycle is 64K points,
// making it easy to calculate quadrants.   We store a quarter cycle.

// The vertical scale factor is 1.0 = 32767

// POINTSBITS = 6 => max error = 3.12  table size 128 bytes
// POINTSBITS = 7 => max error = 1.46  table size 256 bytes
// POINTSBITS = 8 => max error = 1.03  table size 512 bytes
// POINTSBITS = 9 => max error = 0.98  table size 1024 bytes
// Inherent error due to round-to-integer >= 0.5

#define CYCLEPOINTS 65536

#define PHASEBITS 14
#define POINTSBITS 7

#define NPOINTS (1<<POINTSBITS)

#define RESIDUEBITS (PHASEBITS - POINTSBITS)
#define MAXRESIDUE  (1 << RESIDUEBITS)
#define RESIDUE_MASK (MAXRESIDUE - 1)

#ifdef GENERATE_TABLE
#define PI 3.14159265357987

main()
{
    int i;
    double phaseinc = (PI / (2 * NPOINTS));
    printf("/* Automatically generated */\n");
    printf("const unsigned short sin_table[] = {\n");
    for (i = 0; i <= NPOINTS; i++) {
      printf("0x%04x,\n", (short)(sin(phaseinc * i) * 32767 + 0.5));
    }
    printf("};\n");
    return 0;
}

#else

extern unsigned short sin_table[NPOINTS+1];

short phase_to_sin(unsigned int phase)
{
    int negate;
    unsigned int index;
    unsigned int residue;
    unsigned int diff;
    unsigned short result;

    phase &= 0xffff;
    if (negate = (phase >= 0x8000)) {
        phase &= 0x7fff;
    }
    if (phase > 0x4000) {
        phase = 0x8000 - phase;
    }

    index = phase >> RESIDUEBITS;   // top bits
    result = sin_table[index];
#ifdef INTERPOLATE
    residue = phase & RESIDUE_MASK;  // bottom bits
    if (residue) {
        diff = sin_table[index+1] - result;
        diff = (residue * diff) + (MAXRESIDUE/2);
        diff /= MAXRESIDUE;
        result += diff ;
    }
#endif

    return (negate ? -(short)result : (short)result);
}

typedef struct {
    unsigned short phase;
    unsigned short residue;
    unsigned short stride_int;
    unsigned short stride_remainder;
    unsigned short denominator;
} tone_t;

#define SAMPLE_RATE 8000
#define FREQ_NUM 8000
#define FREQ_DEN 256  // FFT lenth, i.e. number of bins

void
tone_setup(unsigned int num, unsigned int den, tone_t *tone)
{
xxx need to compute the fraction too
    phaseinc = num * CYCLEPOINTS / SAMPLE_RATE / den;

    tone->phase = 0;
    tone->residue = 0;
    tone->stride_int = integer;
    tone->stride_remainder = rem;
    tone->denominator = FREQ_DEN;
}

void
bin_to_tone(int bin, tone_t *tone)
{
    unsigned int f1;
    f1 = bin * FREQ_NUM;
    tone_setup(bin * FREQ_NUM, FREQ_DEN, tone);
}

void
hz_to_tone(int hz, tone_t *tone)
{
    tone_setup(hz, 1, tone);
}

unsigned short next_sample(tone_t *tone)
{
    unsigned short phase;

    tone->phase

    return phase_to_sin(phase);
}

#ifdef TEST_ME

#define PI 3.14159265357987

main()
{
    int i, where;
    double max_error;
    double t1, t2, diff;

    double phase = 0;
    double phaseinc = (2 * PI / 65536);

    where = 0;
    max_error = 0;

    for (i = 0; i < 65536; i++ ) {
//    for (i = 16383; i < 65536; i++ ) {
        t1 = phase_to_sin(i);
        t2 = sin(phase) * 32767;
        diff = t2 - t1;
        if (diff < 0)
            diff = -diff;
        printf("%d %f %f %f\n", i, t1, t2, diff); 
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
