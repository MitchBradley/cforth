// This converts ADC counts from a MAX31865 temperature sensor
// interface to temperature, using integer arithmetic with a
// Newton-Rhapson iteration to calcute the square root.

// Constants relevant to PT thermistors:
// A is 3.9083 e-3  (1/A = 255.866)
// B is -5.775 e-7  (-1/B = 1731600)
// R0 is the thermistor resistance at 0C

// Applying a lot of algebra to the equations in
// https://www.analog.com/media/en/technical-documentation/application-notes/AN709_0.pdf
// yields a fast way to calculate t from R using integer arithmetic,
// in a single equation (no need for separate segments above and below 0),
// without division.

// t = T0 - isqrt(TSQ + scl * R)

// where
// T0 is -A/2B = (-1/B) / (1/A)
// TSQ is T0*T0 - 1/B
// scl is 1/(R0*B) = (-1/B) / R0

#include <inttypes.h>

#define T0  3384       // This is -A/2B
#define TSQ 13181975L  // This is T0*T0 - 1/B
#define SCL 17316      // This is -1/B/100
uint16_t scl;
uint16_t ref;

// If you have a proper 16x16>32 multiply routine, you can use
// it instead of the following, which wastes a little time
// by doing a 32x32 multiply
uint32_t mul_16x16(uint16_t a, uint16_t b) {
  return a * (uint32_t)b;
}

// Newton-Rhapson iteration for integer SQRT
uint16_t nr_isqrt(uint32_t n, uint16_t guess)
{
  int16_t error;
  while ((error = n - mul_16x16(guess, guess)) != 0) {
    guess += error / guess / 2;
  }
  return guess;
}

// This works for RTDnominal = 100 or 1000.
// It assumes 100 if RTDnominal != 1000
void set_resistances(uint16_t RTDnominal, uint16_t refResistance) {
  // The following doesn't divide at run time, as SCL/10 can be
  // precomputed by the compiler
  scl = RTDnominal == 1000 ? SCL / 10 : SCL;
  ref = refResistance;
}

uint16_t adc_to_ohms(uint16_t counts)
{
  return mul_16x16(counts, ref) >> 15;
}

int16_t ohms_to_degreesC(uint16_t resistance)
{
  return T0 - nr_isqrt(TSQ - mul_16x16(scl, resistance), T0);
}

uint16_t adc_to_degreesC(uint16_t counts)
{
  uint16_t Rt = adc_to_ohms(counts);
  return ohms_to_degreesC(Rt);
}

#include <stdio.h>
main()
{
  uint16_t i;
  set_resistances(100, 430);
  for (i=0; i < 350; i++) {
    printf("%d %d", i, ohms_to_degreesC(i));
  }
}
