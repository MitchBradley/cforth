// Forth interfaces to platform-specific C routines
// See "ccalls" below.

#include "forth.h"
#include "compiler.h"
//#include "i2c-ifce.h"
#include "interface.h"

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

#include <errno.h>
cell errno_val(void) {  return (cell)errno;  }
#include <string.h>
// Above gets us strerror()

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

extern void mcpwm_gpio_init(void);
extern void mcpwm_init(void);
extern void mcpwm_set_frequency(void);
extern void mcpwm_set_duty_in_us(void);
extern void mcpwm_set_duty_type(void);
extern void mcpwm_get_frequency(void);
extern void mcpwm_set_signal_high(void);
extern void mcpwm_set_signal_low(void);
extern void mcpwm_start(void);
extern void mcpwm_stop(void);

int xTaskGetTickCount(void);
void raw_emit(char c);

#define ALARM_DATA_CELLS 100
#define ALARM_RETURN_CELLS 50
cell alarm_data_stack[ALARM_DATA_CELLS];
cell alarm_return_stack[ALARM_RETURN_CELLS];
struct stacks alarm_stacks_save;
struct stacks alarm_stacks = {
  (cell)&alarm_data_stack[ALARM_DATA_CELLS-2],
  (cell)&alarm_data_stack[ALARM_DATA_CELLS-2],
  (cell)&alarm_return_stack[ALARM_RETURN_CELLS],
  (cell)&alarm_return_stack[ALARM_RETURN_CELLS]
};

#include "esp_timer.h"

static esp_timer_handle_t alarm_timer;

// It would be nice to pass this through the timer callback arg,
// but to do that, you must set it when the timer is created.
// It is a lot of trouble to create and destroy timers based on
// when the argument changes.  It is easer to use this variable.
xt_t alarm_xt;

extern cell *callback_up;

static void alarm_callback(void* arg)
{
  switch_stacks(&alarm_stacks_save, &alarm_stacks, callback_up);
  execute_xt(alarm_xt, callback_up);
  switch_stacks(NULL, &alarm_stacks_save, callback_up);
}

static esp_timer_handle_t alarm_timer;

static void create_timer() {
    if (alarm_timer) {
        return;
    }
    const esp_timer_create_args_t alarm_timer_args = {
            .callback = &alarm_callback,
    };
    esp_timer_create(&alarm_timer_args, &alarm_timer);
}

static void alarm_us_64(uint64_t us, xt_t xt)
{
    create_timer();
    alarm_xt = xt;
    if (xt && us) {
        esp_timer_start_once(alarm_timer, us);
    } else {
        esp_timer_stop(alarm_timer);
    }
}
static void alarm_us(uint32_t us, xt_t xt)
{
    alarm_us_64((uint64_t)us, xt);
}
static void alarm(uint32_t ms, xt_t xt)
{
    alarm_us((uint64_t)ms * 1000, xt);
}

static void repeat_alarm_us_64(uint64_t us, xt_t xt)
{
    create_timer();
    alarm_xt = xt;
    if (xt && us) {
        esp_timer_start_periodic(alarm_timer, us);
    } else {
        esp_timer_stop(alarm_timer);
    }
}
static void repeat_alarm_us(uint32_t us, xt_t xt)
{
    repeat_alarm_us_64((uint64_t)us, xt);
}
static void repeat_alarm(uint32_t ms, xt_t xt)
{
    repeat_alarm_us((uint64_t)ms * 1000, xt);
}

cell ((* const ccalls[])()) = {
	C(build_date_adr)       //c 'build-date     { -- a.value }
	C(version_adr)          //c 'version        { -- a.value }
	C(ms)                   //c ms              { i.ms -- }
	C(xTaskGetTickCount)    //c get-msecs       { -- i.ms }
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
	C(gpio_mode)    	//c gpio-mode { i.pullup? i.direction i.gpio# -- }

	C(get_wifi_mode)	//c wifi-mode@ { -- i.mode }
	C(wifi_open)		//c wifi-open { $ssid $password i.timeout -- i.error? }

	C(set_log_level)	//c log-level! { i.level $component -- }

  // LWIP sockets
  // Like Posix sockets but the socket descriptor space is not
  // merged with the file descriptor space, so you cannot
  // do a select that encompasses both
	C(lwip_socket)		//c socket         { i.proto i.type i.family -- i.handle }
	C(lwip_bind_r)		//c bind           { i.len a.addr i.handle -- i.error }
	C(lwip_setsockopt_r)	//c setsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
	C(lwip_getsockopt_r)	//c getsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
	C(lwip_connect_r)	//c connect        { i.len a.adr i.handle -- i.error }
	C(stream_connect)	//c stream-connect { i.timeout $.portname $.hostname -- i.handle }
	C(my_lwip_write)	//c lwip-write     { a.buf i.size i.handle -- i.count }
	C(my_lwip_read)		//c lwip-read      { a.buf i.size i.handle -- i.count }
	C(lwip_close_r)		//c lwip-close     { i.handle -- }
	C(lwip_listen_r)	//c lwip-listen    { i.backlog i.handle -- i.handle }
	C(lwip_accept_r)	//c lwip-accept    { a.addrlen a.addr i.handle -- i.error }
	C(start_server)		//c start-server   { i.port -- i.error }
	C(dhcpc_status)		//c dhcp-status    { -- i.status }
	C(ip_info)		//c ip-info        { a.info -- }

	C(my_select)		//c lwip-select    { i.sec a.exc a.wr a.rd i.n -- i.cnt }
	C(tcpip_adapter_get_ip_info) //c ip-info@  { a.buf i.adapter# -- i.error }

	C(open_dir)		//c open-dir       { -- a.dir }
	C(closedir)		//c close-dir      { a.dir -- }
	C(next_file)		//c next-file      { a.dir -- a.dirent }
	C(dirent_size)		//c file-bytes     { a.dir -- i.size }
	C(dirent_name)		//c file-name      { a.dir -- a.name }
	C(rename_file)		//c rename-file    { $.old $.new -- }
	C(delete_file)		//c delete-file    { $.name -- }
	C(fs_avail)		//c fs-avail       { -- i.bytes }

	C(raw_emit)		//c m-emit         { i.char -- }

	C(errno_val)		//c errno          { -- i.errno }
	C(strerror)		//c strerror       { i.errno -- $.msg }

        C(gpio_matrix_out)      //c gpio-matrix-out { i.inven i.invout i.fun i.pin -- }
        C(gpio_matrix_in)       //c gpio-matrix-in  { i.invert i.fun i.pin -- }

        C(mcpwm_gpio_init)       //c mcpwm_gpio_init  { i.gpio# i.io_signal i.pwm# -- e.err? }
        C(mcpwm_init)            //c mcpwm_init  { a.conf i.timer# i.pwm# -- e.err? }
        C(mcpwm_set_frequency)   //c mcpwm_set_frequency  { i.freq i.timer# i.pwm# -- e.err? }
        C(mcpwm_set_duty_in_us)  //c mcpwm_set_duty_in_us  { i.duty i.op# i.timer# i.pwm# -- e.err? }
C(mcpwm_set_duty_type)           //c mcpwm_set_duty_type { i.duty# i.op# i.timer# i.pwm# -- i.err? }
C(mcpwm_get_frequency)           //c mcpwm_get_frequency { i.timer# i.pwm# -- i.freq }
        C(mcpwm_set_signal_high) //c mcpwm_set_signal_high { i.op# i.timer# i.pwm# -- i.err? }
        C(mcpwm_set_signal_low)  //c mcpwm_set_signal_low { i.op# i.timer# i.pwm# -- i.err? }
        C(mcpwm_start)           //c mcpwm_start { i.timer# i.pwm# -- i.err? }
        C(mcpwm_stop)            //c mcpwm_stop { i.timer# i.pwm# -- i.err? }

        C(alarm)                 //c set-alarm   { i.xt i.ms -- }
        C(repeat_alarm)          //c repeat-alarm   { i.xt i.ms -- }
        C(alarm_us)              //c set-alarm-us   { i.xt i.us -- }
        C(repeat_alarm_us)       //c repeat-alarm-us   { i.xt i.us -- }
        C(us)                    //c us { i.us -- }
};
