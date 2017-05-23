// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include "forth.h"
#include "i2c-bitbang.h"
#include "onewire.h"

// Prototypes

void pinMode(uint8_t pin, uint8_t mode);
void delay(int ms);
uint32_t micros(void);

void delayUs(uint32_t usec)
{
#if F_CPU == 192000000
	uint32_t n = usec * 64;
#elif F_CPU == 180000000
	uint32_t n = usec * 60;
#elif F_CPU == 168000000
	uint32_t n = usec * 56;
#elif F_CPU == 144000000
	uint32_t n = usec * 48;
#elif F_CPU == 120000000
	uint32_t n = usec * 40;
#elif F_CPU == 96000000
	uint32_t n = usec << 5;
#elif F_CPU == 72000000
	uint32_t n = usec * 24;
#elif F_CPU == 48000000
	uint32_t n = usec << 4;
#elif F_CPU == 24000000
	uint32_t n = usec << 3;
#elif F_CPU == 16000000
	uint32_t n = usec << 2;
#elif F_CPU == 8000000
	uint32_t n = usec << 1;
#elif F_CPU == 4000000
	uint32_t n = usec;
#elif F_CPU == 2000000
	uint32_t n = usec >> 1;
#endif
    // changed because a delay of 1 micro Sec @ 2MHz will be 0
	if (n == 0) return;
	__asm__ volatile(
		"L_%=_delayMicroseconds:"		"\n\t"
#if F_CPU < 24000000
		"nop"					"\n\t"
#endif
#ifdef KINETISL
		"sub    %0, #1"				"\n\t"
#else
		"subs   %0, #1"				"\n\t"
#endif
		"bne    L_%=_delayMicroseconds"		"\n"
		: "+r" (n) :
	);
}


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
void analogWriteFrequency(uint8_t pin, float frequency);
void shiftOut_lsbFirst(uint8_t dataPin, uint8_t clockPin, uint8_t value);
void shiftOut_msbFirst(uint8_t dataPin, uint8_t clockPin, uint8_t value);
uint8_t shiftIn_lsbFirst(uint8_t dataPin, uint8_t clockPin);
uint8_t shiftIn_msbFirst(uint8_t dataPin, uint8_t clockPin);
uint32_t pulseIn_high(volatile uint8_t *reg, uint32_t timeout);
uint32_t pulseIn_low(volatile uint8_t *reg, uint32_t timeout);

void serial_putchar(uint32_t c);
int serial_getchar(void);
int serial_available(void);

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
	C(analogWriteFrequency)	//c analogWriteFrequency { f.freq i.pin -- }
	C(shiftOut_lsbFirst)	//c shiftOut_lsbFirst { i.val i.clockPin i.dataPin -- }
	C(shiftOut_msbFirst)	//c shiftOut_msbFirst { i.val i.clockPin i.dataPin -- }
	C(shiftIn_lsbFirst)	//c shiftIn_lsbFirst { i.clockPin i.dataPin -- i.val }
	C(shiftIn_msbFirst)	//c shiftIn_msbFirst { i.clockPin i.dataPin -- i.val }
	C(pulseIn_high)		//c pulseIn_high { i.timeout a.reg -- i.val }
	C(pulseIn_low)		//c pulseIn_low { i.timeout a.reg -- i.val }

	C(i2c_setup)		//c i2c-setup  { i.scl i.sda -- }
	C(i2c_master_start)	//c i2c-start  { -- }
	C(i2c_master_stop)	//c i2c-stop   { -- }
	C(i2c_send)		//c i2c-byte!  { i.byte -- acked? }
	C(i2c_recv)		//c i2c-byte@  { i.nack? -- i.byte }
	C(i2c_start_write)	//c i2c-start-write { i.reg i.slave -- i.err? }
	C(i2c_start_read)	//c i2c-start-read  { i.stop? i.slave -- i.err? }
	C(i2c_rb)		//c i2c-b@     { i.reg i.slave i.stop -- i.b }
	C(i2c_wb)		//c i2c-b!     { i.value i.reg i.slave -- i.error? }
	C(i2c_be_rw)		//c i2c-be-w@  { i.reg i.slave i.stop -- i.w }
	C(i2c_le_rw)		//c i2c-le-w@  { i.reg i.slave i.stop -- i.w }
	C(i2c_be_ww)		//c i2c-be-w!  { i.value i.reg i.slave -- i.error? }
	C(i2c_le_ww)		//c i2c-le-w!  { i.value i.reg i.slave -- i.error? }

	C(onewire_init)		//c ow-init { i.power i.id -- }
	C(onewire_reset)	//c ow-reset  { -- i.present? }
	C(onewire_select)	//c ow-select  { a.romp -- }
	C(onewire_skip)		//c ow-skip  { -- }
	C(onewire_write)	//c ow-b!  { i.byte -- }
	C(onewire_write_bytes)	//c ow-write  { i.len a.adr -- }
	C(onewire_read)		//c ow-b@  { -- }
	C(onewire_read_bytes)	//c ow-read  { i.len a.adr -- }
	C(onewire_depower)	//c ow-depower  { -- }
	C(onewire_reset_search)	//c ow-reset-search  { -- }
	C(onewire_target_search)//c ow-target-search  { i.family -- }
	C(onewire_search)	//c ow-search  { i.mode a.newaddr -- i.ok? }
	C(onewire_crc8)		//c ow-crc8  { i.len a.adr -- i.crc }
	C(onewire_check_crc16)	//c ow-check-crc16  { i.crc a.invcrc i.len a.input -- i.ok? }
	C(onewire_crc16)	//c ow-crc16  { i.crc i.len a.adr -- i.crc }

	C(serial_putchar)       //c uemit { i.char -- }
	C(serial_getchar)       //c ukey  { -- i.char }
	C(serial_available)     //c ukey? { -- i.n }
};
