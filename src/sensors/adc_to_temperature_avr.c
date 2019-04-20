// See adcToTemperature.c for the purpose of this code.
// This version is optimized for AVR microprocessors using
// hand-coded assembly for the multiply-accumulate step
#define K0 -3945
#define K1 32816
#define K2 4635
#define K3 1309
#define K4 462
#define K5 183
#define K6 77
#define K7 34
#define MAXCOEF 5
#include "stdint.h"

#include "stdio.h"
uint16_t coefs[] = { K0, K1, K2, K3, K4, K5, K6 };
int main()
{
    uint16_t adc;
    for (adc=0; adc<=32768; adc += 2048) {
        int i;
        uint16_t acc = 0;
        for(i=MAXCOEF; i>=1; i--) {
            uint16_t coef;
            coef = coefs[i];
            uint16_t factor;
            uint8_t zero = 0;
            asm volatile(
                "add %A0, %A1 /* ADC += COEF */\n\t"
                "adc %B0, %B1\n\t"
                "mul %A0, %A2 /*low * low*/\n\t"
                "mov __tmp_reg__, r1\n\t"
                "mul %B0, %B2 /*high * high*/\n\t"
                "movw %3,r0\n\t"
                "mul %A0, %B2 /*low * high*/\n\t"
                "add __tmp_reg__, r0\n\t"
                "adc %A3, r1\n\t"
                "adc %B3, %4\n\t"
                "mul %B0, %A2 /*high * low*/\n\t"
                "add __tmp_reg__, r0\n\t"
                "adc %A3, r1\n\t"
                "adc %B3, %4\n\t"
                "movw %0, %3\n\t"
                : "=r" (acc)
                : "r" (coef), "r" (adc), "r"(factor), "r"(zero)
            );
        }
        volatile int16_t ttimes16 = acc + K0;
//	int16_t t_16 = step(K0, step(K1, step(K2, step(K3, step(K4, step(K5, step(K6, K7)))))));
	//volatile int16_t t_16 = step(K0, step(K1, step(K2, step(K3, K4))));
    }
}
