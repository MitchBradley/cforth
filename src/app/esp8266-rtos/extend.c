// Forth interfaces to platform-specific C routines
// See "ccalls" below.

#include "forth.h"
#include "compiler.h"
//#include "i2c-ifce.h"
#include "interface.h"

extern cell *callback_up;


cell ICACHE_FLASH_ATTR version_adr(void)
{
    extern char version[];
    return (cell)version;
}


cell ICACHE_FLASH_ATTR build_date_adr(void)
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

// It would be nice to pass this through the timer callback arg,
// but to do that, you must set it when the timer is created.
// It is a lot of trouble to create and destroy timers based on
// when the argument changes.  It is easer to use this variable.
xt_t alarm_xt;

void alarm_callback(void* arg)
{
  switch_stacks(&alarm_stacks_save, &alarm_stacks, callback_up);
  execute_xt(alarm_xt, callback_up);
  switch_stacks(NULL, &alarm_stacks_save, callback_up);
}

// ------------ Jos: Added
void ICACHE_FLASH_ATTR ExecuteTask_callback(void* pvParameters)
{
  execute_xt((xt_t)pvParameters, callback_up);
}

void ICACHE_FLASH_ATTR task_callback(int stack_size, void* pvParameters)
{
  xt_t pvParam = pvParameters;
  xTaskCreate(ExecuteTask_callback, "NAME", 2048, (void*) pvParameters, 1, NULL );
}

QueueHandle_t GpioQueue;

static void gpio_qhandler(void *arg)
{
  int xHigherPriorityTaskWokenByPost;
  int qitem=sys_now();
  xQueueGenericSendFromISR(GpioQueue, &qitem, &xHigherPriorityTaskWokenByPost, 0);
}

void gpio_isr_qhandler_add(int gpio_num, QueueHandle_t hQueue)
{
  GpioQueue = hQueue;
  int gpio_num1 = gpio_num;
  gpio_isr_handler_add(gpio_num1, gpio_qhandler, (void *) gpio_num1);
}


QueueHandle_t GpioQueue2;
int gpio_num_int2;

static void pulse_qhandler(void *arg)
{
  int xHigherPriorityTaskWokenByPost;
  int qitem[2];
  qitem[1] = rtc_time_get();
  qitem[2] = gpio_pin_fetch(gpio_num_int2);
  xQueueGenericSendFromISR(GpioQueue2, &qitem, &xHigherPriorityTaskWokenByPost, 0);
}

void ICACHE_FLASH_ATTR pulse_isr_qhandler_add(int gpio_num, QueueHandle_t hQueue)
{
  GpioQueue2 = hQueue;
  gpio_num_int2 = gpio_num;
  gpio_isr_handler_add(gpio_num_int2, pulse_qhandler, (void *) gpio_num_int2);
}

// SPI write data, maximal 64 bytes at one time.
void spi_master_write64(int size, uint32_t* data)
{
  spi_trans_t trans;
  uint16_t cmd;
  uint32_t addr = 0x0;
  trans.bits.val = 0;
  trans.bits.cmd = 8;
  trans.bits.addr = 8;
  trans.cmd = &cmd;
  cmd = SPI_MASTER_WRITE_DATA_TO_SLAVE_CMD;
  trans.addr = &addr;
  memset(&trans, 0x0, sizeof(trans));
  trans.bits.mosi = 8 * size;
  trans.mosi = data;
  spi_trans(HSPI_HOST, &trans);
}


// ------------ End Additions

cell ((* const ccalls[])()) = {
	C(build_date_adr)   //c 'build-date     { -- a.value }
	C(version_adr)      //c 'version        { -- a.value }
	C(ms)               //c ms              { i.ms -- }
	C(sys_now)          //c get-msecs       { -- i.ms }
	C(restart)          //c restart         { -- }

        // divisor is 8..32 (80MHz/divisor), mode is 0 for TOUT, 1 for VDD
	C(adc_init_args)	//c adc-init  { i.divisor i.mode -- i.err? }
	C(adc_deinit)		//c adc-deinit  { -- }
	C(adc_read_fast)	//c adc-read-fast  { i.len a.data -- i.err? }
	C(adc_fetch)		//c adc0@  { -- i.voltage }

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
	C(wifi_open_ap)         //c wifi-open-ap { i.storage i.max-connections $ssid $password -- i.error? }
	C(wifi_open_station)    //c wifi-open-station { i.storage i.retries i.timeout $ssid $password -- i.error? }
	C(wifi_open_station_compat)  //c wifi-open { $ssid $password i.timeout -- i.error? }
        C(wifi_off)             //c wifi-off { -- i.error? }

	C(set_log_level)	//c log-level! { i.level $component -- }

  // LWIP sockets
  // Like Posix sockets but the socket descriptor space is not
  // merged with the file descriptor space, so you cannot
  // do a select that encompasses both
	C(lwip_socket)		//c socket         { i.proto i.type i.family -- i.handle }
	C(lwip_bind)		//c bind           { i.len a.addr i.handle -- i.error }
	C(lwip_setsockopt)	//c setsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
	C(lwip_getsockopt)	//c getsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
	C(lwip_connect)		//c connect        { i.len a.adr i.handle -- i.error }
	C(stream_connect)	//c stream-connect { i.timeout $.portname $.hostname -- i.handle }
	C(udp_client)		//c udp-connect    { $.portname $.hostname -- i.handle }
	C(my_lwip_write)	//c lwip-write     { a.buf i.size i.handle -- i.count }
	C(my_lwip_read)		//c lwip-read      { a.buf i.size i.handle -- i.count }
	C(lwip_close)		//c lwip-close     { i.handle -- }
	C(lwip_listen)		//c lwip-listen    { i.backlog i.handle -- i.handle }
	C(lwip_accept)		//c lwip-accept    { a.addrlen a.addr i.handle -- i.error }
	C(start_server)		//c start-server   { i.port -- i.error }
	C(start_udp_server)	//c start-udp-server { i.port -- i.error }
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

        C(raw_emit)             //c m-emit  { i.char -- }

        C(errno_val)		//c errno          { -- i.errno }
        C(strerror)		//c strerror       { i.errno -- $.msg }

        C(pwm_init)             //c pwm-init  { a.pin#s i.nchannels a.duties i.period -- i.err? }
	C(pwm_deinit)           //c pwm-deinit  { -- i.err? }
	C(pwm_set_duty)         //c pwm-duty!  { i.duty i.channel# -- }
	C(pwm_set_frequency)    //c pwm-frequency!  { i.frequency -- }
	C(pwm_duty_fetch)       //c pwm-duty@  { i.channel# -- i.duty }
	C(pwm_frequency_fetch)  //c pwm-frequency@  { -- i.frequency }
	C(pwm_set_period)       //c pwm-period!  { i.period -- }
	C(pwm_period_fetch)     //c pwm-period@  { -- i.period }
	C(pwm_start)            //c pwm-start { -- }
	C(pwm_stop)             //c pwm-stop-mask { i.mask -- }
	C(pwm_stop0)            //c pwm-stop { -- }
	C(pwm_phase_store)      //c pwm-phase! { i.phase i.channel -- }

        C(alarm_ms)              //c set-alarm      { i.xt i.ms -- }
        C(repeat_alarm)          //c repeat-alarm   { i.xt i.ms -- }
        C(alarm_us)              //c set-alarm-us   { i.xt i.us -- }
        C(repeat_alarm_us)       //c repeat-alarm-us   { i.xt i.us -- }
        C(us)                    //c us { i.us -- }

// Jos: Added the lines below
	C(esp_clk_cpu_freq)          //c esp_clk_cpu_freq  { -- i.freq }
	C(esp_set_cpu_freq)          //c esp_set_cpu_freq  { i.esp_cpu_freq_t i.freq -- }
	C(esp_deep_sleep)            //c esp_deep_sleep    { i.uint64_t i.time_in_us -- }
	C(esp_get_free_heap_size)    //c esp_get_free_heap_size     { -- i.size }

// Preemptive multitasking
 	C(task_callback)             //c task                       { a.xt i.stack_size -- }
	C(xTaskGetCurrentTaskHandle) //c xTaskGetCurrentTaskHandle  { -- i.htask }
	C(vTaskDelay)                //c vTaskDelay                 { i.TicksToDelay -- }
 	C(vTaskResume)               //c vTaskResume                { i.htask -- }
 	C(vTaskSuspend)              //c vTaskSuspend               { i.htask -- }
 	C(vTaskDelete)               //c vTaskDelete                { i.htask -- }
 	C(vTaskPrioritySet)          //c vTaskPrioritySet           { a.prio i.handle -- }
        C(uxTaskPriorityGet)         //c uxTaskPriorityGet          { i.handle  -- i.prio }
 	C(vTaskSuspendAll)           //c vTaskSuspendAll            { -- }
 	C(xTaskResumeAll)            //c xTaskResumeAll             { -- }

// Queues
        C(xQueueGenericCreate)       //c xQueueGenericCreate        { i.type i.itemsize i.qlength  -- i.handle }
 	C(xQueueGenericSend)         //c xQueueGenericSend          { i.front_back i.xTicksToWait i.pvItemToQueue i.qHandle -- i.res }
        C(xQueueReceive)             //c xQueueReceive              { i.xTicksToWait i.pxRxedMessage i.qHandle -- i.res }

// Interrupts
 	C(gpio_set_intr_type)        //c gpio_set_intr_type         { i.intr_type i.gpio_num -- i.res }
 	C(gpio_isr_qhandler_add)     //c gpio_isr_qhandler_add      { i.hqueue i.gpio_num --  i.res }
 	C(pulse_isr_qhandler_add)    //c pulse_isr_qhandler_add     { i.hqueue i.gpio_num --  i.res }

// Spi
 	C(spi_init)                  //c spi_init                   { a.config i.host  -- i.res }
 	C(spi_master_write64)        //c spi_master_write64         { a.data i.size -- }


// Rtc
	C(rtc_time_get)              //c rtc_time_get               { -- i.us }
	C(pm_rtc_clock_cali_proc)    //c pm_rtc_clock_cali_proc     { -- i.cali }
};
