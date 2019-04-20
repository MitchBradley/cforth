// This converts ADC counts from a MAX31865 temperature sensor
// interface to temperature, using only integer multiplies and adds -
// no floating point, no division, no sqrt - thus yielding a fast and
// compact algorithm on a small microprocessor like an AVR.

//
// The general approach is to solve the quadratic formula, qielding
// an expression involving SQRT, then expand the SQRT as a power series.
// By choosing the form of the equation carefully and using suitable
// scale factors, that power series can then be evaluated with integer
// arithmetic.

// The basic equation relating sensor resistance to temperature is:
// the Callendar-Van Dusen equation:
//   R(t) = R0(1 + A*t + B*t^2)
// where R0 is the sensor resistance at 0 degrees C with parameters:
//   A = 3.9083e-3
//   B = -5.775e-7
//
// The MAX81865 chip gives us a 15-bit ADC count that depends on the
// sensor resistance and a reference resistor, such that
//   R(t) = Rref * ADC / 2^15
// so
//   Rref * ADC / 2^15 = R0(1 + A*t + B*t^2)
// We can solve that for t as a function of ADC with the quadratic
// formula, giving:
//   t = -A/2B - sqrt( (-A/2B)^2 - 1/B + ADC/2^15*Rref/R0/B) )

// We can make that look a bit simpler by defining:
//   T0 = -A/2B = 3383.8
// Giving
//   t = T0 - SQRT( T0^2 - 1/B + ADC/2^15*(Rref/R0)/B )
// A little factoring gives the equivalent:
//   t = T0 - SQRT(T0^2 - 1/B) * SQRT(1 + ADC/2^15*Rref/R0/B/(T0^2 - 1/B) ))
// The first SQRT is a constant that depends only on A and B:
//   T1 = SQRT(T0^2 - 1/B) = 3630.37
// So
//   t = T0 - T1 * SQRT(1 + ADC/2^15*Rref/R0/B/T1^2)
// Let's define:
//   P = Rref/R0/B/T1^2
//   AS = ADC/2^15
// So
//   t = T0 - T1 * SQRT(1 + AS * P)
//
// The only variable in the right hand side is AS.  We can expand the
// SQRT as a McLaurin series in powers of AS. The terms are:
//   1
//  +P   / 2       * AS
//  -P^2 / 8       * AS^2
//  +P^3 / 16      * AS^3
//  -P^4 * 5/128   * AS^4
//  -P^5 * 7/256   * AS^5
//  -P^6 * 21/1024 * AS^6
//  -P^7 * 33/2048 * AS^7
//   ...
//
// With that series, the temperature can be computed with only multiplication
// and addition.  But the coefficients aren't integers, so if we want to
// avoid floating point, we still have some work to do.  Let's find the
// numerical value of P:
//
// R0 is either 100 ohms for a PT100 thermistor or 1000 ohms for a PT1000.
// Rref is typically 4 times R0, giving 4.0 as Rref/R0.  The MAX31865 board
// from Adafruit uses 430 or 4300 ohm Rref, so Rref/R0 is 4.3.  So we have
//   P = -0.564965  (for Rref/R0 = 4.3)
//   P = -0.525541  (for Rref/R0 = 4.0)
// Those values are not convenient for integer arithmetic, especially when
// P is raised to higher powers, but we can take advantage of the fact that
// the SQRT - and thus every term of its series approximation - is multiplied
// by T1, whose value is 3630.37.  For Rref/R0 = 4.3, the coefficients are:
//   T1                 =  3630.37   (k0)
//  -T1 * P / 2         =  1025.50   (k1)
//  +T1 * P^2 / 8       =   144.84   (k2)
//  -T1 * P^3 / 16      =    40.91   (k3)
//  +T1 * P^4 * 5/128   =    14.45   (k4)
//  -T1 * P^5 * 7/256   =     5.71   (k5)
//  +T1 * P^6 * 21/1024 =     2.42   (k6)
//  -T1 * P^7 * 33/2048 =     1.07   (k7)
//
// Those coefficients are reasonable for integer multiplication, but we
// have to account for the fact that the polynomial variable is
//   AS = ADC/2^15
// A very efficient way to do scaled integer multiplication is to
// multiply 16 bits * 16 bits giving 32 bits, and then keep the most
// significant 16 bits of the result.  Mathematically that is
//   X*Y/2^16
// Which we can write as
//   2*X*Y/2^15
// and then substitute AS = ADC/2^15 to give
//   2*X*AS
// So we have to double the coefficients to account for the fact that
// we are dividing by 2^16 instead of 2^15.  (We could instead shift
// right by 15 bits, but simply discarding the low 16 bits is more
// efficient on low-end microprocessors like the AVR's in Arduinos.)

// We are pretty close now, but there is an opportunity for more precision
// at no extra cost.  The large multiplicative coefficient is
//   2*1025.50 = 2051
// We could preserve more fractional bits by scaling that up by the
// largest power of two that doesn't overflow a 16-bit number.  That
// happens to be 2^4=16.  That results in the answer being scaled up
// by the same factor, so the result is in degrees C * 16 instead of
// degrees C.  That scale factor can be removed at the end, or the
// unscaled result can be used directly to give an answer precise to
// 1/16 of degree.
//
// For Rref = 400, k1 is 953.5 instead of 1025.5.  In that case, we could
// scale up by 5 bits instead of 4 to give an answer in 1/32 of a degree,
// but we would have to be more careful to check for overflow in internal
// calculation steps.  So let's stick with scaling by 4.

// Upscaling the coefficients by 2 * 2^4 = 32 and rounding to the nearest
// integer gives (we'll analyze the constant term separately):
//
//   32 *-T1 * P / 2         = 32816  (K1)
//   32 * T1 * P^2 / 8       =  4635  (K2)
//   32 *-T1 * P^3 / 16      =  1309  (K3)
//   32 * T1 * P^4 * 5/128   =   462  (K4)
//   32 *-T1 * P^5 * 7/256   =   183  (K5)
//   32 * T1 * P^6 * 21/1024 =    77  (K6)
//   32 *-T1 * P^7 * 33/2048 =    34  (K7)
//
// That's a great set of coefficients for a 16x16 calculation!

// The constant term 3630.37 can't be scaled up by 32 without 16-bit
// overflow, but the actual equation is
//   t = T0 - T1 * SQRT(1 + AS * P)
// or
//   t = T0 - T1 + k1*AS + k2*AS^2 + (higher terms)
// so we can pre-subtract "K0 = T0 - T1" giving -246.56, which is just fine
// scaled up by 16 (it is -3945).
//
// Now we will do a factoring trick to both make the computation much
// more efficient and eliminate loss of precision when raising AS to
// higher powers.  The polynomial
//   a + bx + cx^2 + dx^3
// can be written as
//   a + x(b + x(c + x(d)))
// and the pattern generalizes to any order.  In that form, the calculation
// is a sequence of simple "multiply then add" steps.
//   Result = Result * x + coefficient
// So for the polynomial above:
//   Result = d
//   Result = Result * x + c
//   Result = Result * x + b
//   Result = Result * x + a
// Thus with the substitution:
//   AI = ADC/2^16
// we are computing
//   K0 + AI(K1 + AI(K2 + AI(K3 + AI(K4 + AI(K5 + AI(K6 + AI(K7))
// in the form:
//   Result = K7
//   Result = Result * AI + K6
//   Result = Result * AI + K5
//   Result = Result * AI + K4
//   Result = Result * AI + K3
//   Result = Result * AI + K2
//   Result = Result * AI + K1
//   Result = Result * AI + K0
//
// Each multiplication is the aforementioned 16x16->32, discard low 16 bits
//
//   or
//   t_32 = K7;
//   t_32 = step(K6, t_32);
//   t_32 = step(K5, t_32);
//   t_32 = step(K4, t_32);
//   t_32 = step(K3, t_32);
//   t_32 = step(K2, t_32);
//   t_32 = step(K1, t_32);
//   t_32 = step(K0, t_32);

#define BRECIP 13181800  /* 1/5.775e-7 */
#define KTIMESTEN 33838  /* -10A/2B */

#define K0 -3945
#define K1 32816
#define K2 4635
#define K3 1309
#define K4 462
#define K5 183
#define K6 77
#define K7 34

#include "stdint.h"
uint16_t adc;
static inline uint16_t mul_16(uint16_t n1, uint16_t n2) {
    uint32_t res = n1 * (uint32_t)n2 / 65536;
    return res;
}
static inline int16_t step(int16_t coef, int16_t last) {
  return mul_16(adc, last) + coef;
}
#include "stdio.h"
int main()
{
    for (adc=0; adc<=32768; adc += 2048) {
//	int16_t t_16 = step(K0, step(K1, step(K2, step(K3, step(K4, step(K5, step(K6, K7)))))));
	volatile int16_t t_16 = step(K0, step(K1, step(K2, step(K3, K4))));
    }
}
// Max temp is 863.6875 at ADC = 32767
// Error in degrees at degrees
// K7 and K6 are identical
// K5 vs K6 1/16 at 788, 1/8 at max
// K4 vs K6 1/16 at 425, 1/4 at 788, 7/16 at max
// K3 vs K6 1/16 at 148, 1+ at 714, 0.5 at ~530, 2.25 at max
// K2 vx K6 1/16 at -51, 1- at 214, 12.5 at max
