// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include "forth.h"
#include "systick.h"

// Prototypes

void gpio_open();
void gpio_set();
void gpio_clr();
void gpio_write();
void gpio_read();

cell ((* const ccalls[])()) = {
	C(delay_1ms)    //c ms         { i.nmsecs -- }
	C(gpio_open)    //c gpio-open  { i.mode i.pin i.port -- i.portpin }
	C(gpio_set)     //c gpio-set   { i.portpin -- }
	C(gpio_clr)     //c gpio-clr   { i.portpin -- }
	C(gpio_write)   //c gpio-pin!  { i.value i.portpin -- }
	C(gpio_read)    //c gpio-pin@  { i.portpin -- i.value }
};
