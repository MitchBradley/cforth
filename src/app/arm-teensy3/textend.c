// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include "forth.h"

// Prototypes

void pinMode(uint8_t pin, uint8_t mode);
void delay(int ms);
uint32_t micros(void);

uint32_t get_msecs(void)
{
	extern uint32_t systick_millis_count;
	return systick_millis_count;
}

void analogReference(uint8_t type);
void analogReadRes(unsigned int bits);
void analogReadAveraging(unsigned int num);
int analogRead(uint8_t pin);
void analogWriteDAC0(int val);
// void analogWriteDAC1(int val);

unsigned long rtc_get(void);
void rtc_set(unsigned long t);
void rtc_compensate(int adjust);
void analogWrite(uint8_t pin, int val);
void analogWriteRes(uint32_t bits);
void analogWrite(uint8_t pin, int val);
void analogWriteFrequency(uint8_t pin, float frequency);
void shiftOut_lsbFirst(uint8_t dataPin, uint8_t clockPin, uint8_t value);
void shiftOut_msbFirst(uint8_t dataPin, uint8_t clockPin, uint8_t value);
uint8_t shiftIn_lsbFirst(uint8_t dataPin, uint8_t clockPin);
uint8_t shiftIn_msbFirst(uint8_t dataPin, uint8_t clockPin);
uint32_t pulseIn_high(volatile uint8_t *reg, uint32_t timeout);
uint32_t pulseIn_low(volatile uint8_t *reg, uint32_t timeout);


cell ((* const ccalls[])()) = {
	C(pinMode)              //c gpio-mode  { i.mode i.pin# -- }
	C(delay)                //c ms  { i.#ms -- }
	C(micros)               //c get-usecs  { -- i.us }
	C(get_msecs)            //c get-msecs  { -- i.ms }
	C(analogReference)	//c analogReference  { i.int? -- }
	C(analogReadRes)	//c analogReadRes   { i.bits -- }
	C(analogReadAveraging)  //c analogReadAveraging  { i.nsamples -- }
	C(analogRead)		//c analogRead  { i.pin -- i.val }
	C(analogWriteDAC0)	//c analogWriteDAC0 { i.val -- }
	C(rtc_get)		//c rtc_get { -- i.val }
	C(rtc_set)		//c rtc_set { i.val -- }
	C(rtc_compensate)	//c rtc_compensate { i.adjust -- }
	C(analogWrite)		//c analogWrite  { i.val i.pin -- }
	C(analogWriteRes)	//c analogWriteRes  { i.bits -- }
	C(analogWrite)		//c analogWrite  { i.val i.pin -- }
//	C(analogWriteFrequency)	//c analogWriteFrequency { f.freq i.pin -- }
	C(shiftOut_lsbFirst)	//c shiftOut_lsbFirst { i.val i.clockPin i.dataPin -- }
	C(shiftOut_msbFirst)	//c shiftOut_msbFirst { i.val i.clockPin i.dataPin -- }
	C(shiftIn_lsbFirst)	//c shiftIn_lsbFirst { i.clockPin i.dataPin -- i.val }
	C(shiftIn_msbFirst)	//c shiftIn_msbFirst { i.clockPin i.dataPin -- i.val }
	C(pulseIn_high)		//c pulseIn_high { i.timeout a.reg -- i.val }
	C(pulseIn_low)		//c pulseIn_low { i.timeout a.reg -- i.val }
};
