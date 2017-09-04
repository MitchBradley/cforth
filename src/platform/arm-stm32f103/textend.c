// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include "forth.h"

// Prototypes

cell get_msecs();
cell wfi();
cell spins();
cell ms();
void gpio_open();
void gpio_set();
void gpio_clr();
void gpio_write();
void gpio_read();
void adc_open();
void adc_start();
void adc_done();
void adc_read();

cell ((* const ccalls[])()) = {
    C(spins)        //c spins     { i.nsxfpins -- }
    C(wfi)          //c wfi       { -- }
    C(get_msecs)    //c get-msecs { -- i.msecs }
    C(ms)	    //c ms        { i.nmsecs -- }
    C(gpio_open)    //c gpio-open  { i.mode i.pin i.port -- i.portpin }
    C(gpio_set)     //c gpio-set   { i.portpin -- }
    C(gpio_clr)     //c gpio-clr   { i.portpin -- }
    C(gpio_write)   //c gpio-pin!  { i.value i.portpin -- }
    C(gpio_read)    //c gpio-pin@  { i.portpin -- i.value }
    C(adc_open)     //c adc-open   { i.adc# -- i.handle }
    C(adc_start)    //c adc-start  { i.time i.channel i.handle -- }
    C(adc_done)     //c adc-done?  { i.handle -- i.flag }
    C(adc_read)     //c adc-get    { i.handle -- i.value }
};
