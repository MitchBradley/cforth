// Forth interfaces to platform-specific C routines
// See "ccalls" below.

#include "forth.h"
//#include "i2c-ifce.h"
#include "interface.h"

extern cell *callback_up;

cell version_adr(void)
{
    extern char version[];
    return (cell)version;
}

cell build_date_adr(void)
{
    extern char build_date[];
    return (cell)build_date;
}

// Many of the routines cited below are defined either directly
// in the ESP32 SDK or in sdk_build/main/interface.c .  It is best
// to avoid putting the definition of ESP-specific routines in
// this file, because doing so typically requires including a
// lot of .h files here, and that introduces a dependency on the
// SDK configurator, which greatly complicates the Makefile
// dependencies for the CForth portion of the build.  We avoid that
// by just referring to the names of the routines we want to include
// in the ccalls[] table, with fake call signatures "void xxx(void)".
// sdk_build/main/interface.c is compiled after the SDK configurator
// has run, so it can include whatever it needs.

extern void software_reset(void);
extern void ms(void);

extern void adc1_config_width(void);
extern void adc1_config_channel_atten(void);
extern void adc1_get_voltage(void);
extern void hall_sensor_read(void);

cell ((* const ccalls[])()) = {
	C(build_date_adr)       //c 'build-date     { -- a.value }
	C(version_adr)          //c 'version        { -- a.value }
	C(ms)                   //c ms              { i.ms -- }
	C(software_reset)       //c restart         { -- }

	C(adc1_config_width)    //c adc-width!  { i.width -- }
	C(adc1_config_channel_atten)  //c adc-atten!  { i.attenuation i.channel# -- }
	C(adc1_get_voltage)     //c adc@        { i.channel# -- i.voltage }
	C(hall_sensor_read)     //c hall@       { -- i.voltage }

	C(i2c_open)		//c i2c-open  { i.scl i.sda -- i.error? }
	C(i2c_close)		//c i2c-close  { -- }
	C(i2c_write_read)	//c i2c-write-read { a.wbuf i.wsize a.rbuf i.rsize i.slave i.stop -- i.err? }
	C(i2c_rb)		//c i2c-b@     { i.reg i.slave i.stop -- i.b }
	C(i2c_wb)		//c i2c-b!     { i.value i.reg i.slave -- i.error? }
	C(i2c_be_rw)		//c i2c-be-w@  { i.reg i.slave i.stop -- i.w }
	C(i2c_le_rw)		//c i2c-le-w@  { i.reg i.slave i.stop -- i.w }
	C(i2c_be_ww)		//c i2c-be-w!  { i.value i.reg i.slave -- i.error? }
	C(i2c_le_ww)		//c i2c-le-w!  { i.value i.reg i.slave -- i.error? }

	C(gpio_pin_fetch)	//c gpio-pin@  { i.gpio# -- i.flag }
	C(gpio_pin_store)	//c gpio-pin!  { i.level i.gpio# -- }
	C(gpio_toggle)		//c gpio-toggle { i.gpio# -- }
	C(gpio_is_output)	//c gpio-is-output { i.gpio# -- }
	C(gpio_is_output_od)	//c gpio-is-output-open-drain { i.gpio# -- }
	C(gpio_is_input)	//c gpio-is-input { i.gpio# -- }
	C(gpio_is_input_pu)	//c gpio-is-input-pullup { i.gpio# -- }
	C(gpio_is_input_pd)	//c gpio-is-input-pulldown { i.gpio# -- }
};
