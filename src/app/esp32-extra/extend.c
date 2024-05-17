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

extern void adc1_config_width(void);
extern void adc1_config_channel_atten(void);
extern void adc1_get_voltage(void);
extern void esp_adc_cal_raw_to_voltage(void);
extern void esp_adc_cal_characterize(void);
extern void esp_adc_cal_check_efuse(void);
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
extern void esp_deep_sleep_start(void);
extern void esp_sleep_enable_ext0_wakeup(void);
extern void esp_wifi_restore(void);
extern void esp_clk_cpu_freq(void);
extern void rtc_clk_cpu_freq_set(void);
extern void esp_wifi_start(void);
extern void esp_wifi_stop(void);
extern void esp_wifi_disconnect(void);
extern void adc_power_on(void);
extern void adc_power_off(void);
extern void gpio_intr_enable(void);
extern void gpio_intr_disable(void);
extern void my_uart_param_config(void);
extern void uart_set_pin(void);
extern void uart_driver_install(void);
extern void uart_write_bytes(void);
extern void uart_read_bytes(void);
extern void get_system_time(void);
extern void set_system_time(void);
extern void my_spiffs_unmount(void);
extern void spi_bus_init(void);
extern void spi_bus_setup(void);
extern void spi_master_data(void);
extern void spi_slave_data(void);
extern void spi_bus_init_slave(void);

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


static void ExecuteTask_callback(void* pvParameters)
{
  execute_xt((xt_t)pvParameters, callback_up);
}

// Can't use core 1.
void task(int stack_size, void* pvParameters)
{
  xTaskCreatePinnedToCore(ExecuteTask_callback, "NAME", stack_size, (void*) pvParameters, 5, NULL, 0);
}

static QueueHandle_t GpioQueue;

void IRAM_ATTR gpio_qhandler(void *arg)
{
  interrupt_disable();
  int xHigherPriorityTaskWokenByPost=0;
  int qitem=xTaskGetTickCount();
  xQueueGenericSendFromISR(GpioQueue, &qitem, &xHigherPriorityTaskWokenByPost, 0);
  interrupt_restore();
}

static void gpio_isr_qhandler_add(int gpio_num, QueueHandle_t hQueue)
{
  GpioQueue = hQueue;
  int gpio_num1 = gpio_num;
  gpio_isr_handler_add(gpio_num1, gpio_qhandler, (void *) gpio_num1);
}

void sec_deep_sleep(uint32_t sec)
{
  esp_sleep_enable_timer_wakeup((uint64_t)sec * 1000000);
  esp_deep_sleep_start();
}

void ms_light_sleep(uint32_t ms)
{
  esp_sleep_enable_timer_wakeup((uint64_t)ms * 1000);
  esp_light_sleep_start();
}

void add_my_peer(int *to_mac, int encryption, int channel )
{
    esp_now_peer_info_t peerInfo;
    memcpy(peerInfo.peer_addr, to_mac, ESP_NOW_ETH_ALEN);
    peerInfo.channel = channel;
    peerInfo.ifidx   = ESPNOW_WIFI_IF;
    peerInfo.encrypt = encryption;
    ESP_ERROR_CHECK( esp_now_add_peer(&peerInfo) );
}

static QueueHandle_t espnow_queue;

#define max_payload_size 20

int get_max_payload_size()
{
return max_payload_size;
}

void q_data_cb(const uint8_t *mac, const uint8_t *data, int len)
{
        if (len <= max_payload_size) {
           struct Qdata{
           char   Qmac[8];
           int    QLen;
           char   Qdata[max_payload_size];
           };
           struct Qdata Qs = {
           .QLen= len
           };
           memcpy(Qs.Qmac,(int*)mac,6);
           memcpy(Qs.Qdata,(int*)data,len);
           xQueueGenericSend(espnow_queue, &Qs, 5, 0);
        }
}

cell set_esp_now_callback_rcv(QueueHandle_t hQueue)
{
    espnow_queue = hQueue;
    ESP_ERROR_CHECK( esp_now_register_recv_cb(q_data_cb) );
}

// ------------ End Additions

cell ((* const ccalls[])()) = {
	C(build_date_adr)       //c 'build-date     { -- a.value }
	C(version_adr)          //c 'version        { -- a.value }
        C(us)                   //c us		    { i.us -- }
	C(set_system_time)      //c set-system-time { i.seconds -- }
	C(get_system_time)      //c get-system-time! { a.2var_timeval -- }
	C(xTaskGetTickCount)    //c get-ticks       { -- i.ticks }
	C(software_reset)       //c restart         { -- }
	C(set_log_level)	//c log-level!	    { i.level $component -- }

	C(adc1_config_width)    //c adc-width!        { i.width -- }
	C(adc1_config_channel_atten)  //c adc-atten!  { i.attenuation i.channel# -- }
 	C(adc_power_on)         //c adc-power-on      { -- }
 	C(adc_power_off)        //c adc-power-off     { -- }
	C(adc1_get_voltage)     //c adc@          { i.channel# -- i.voltage }
 C(esp_adc_cal_characterize)    //c get-adc-chars { a.adc_chars i.vref i.bi_width i.atten i.adc_num -- i.res }
 C(esp_adc_cal_raw_to_voltage)  //c adc-mv        { a.adc_chars i.reading -- i.voltage }
 C(esp_adc_cal_check_efuse)     //c check-efuse   { i.type -- i.res }
	C(hall_sensor_read)     //c hall@         { -- i.voltage }

	C(my_uart_param_config)	//c uart-param-config	{ i.flow i.stop i.par i.#bits i.baud i.uart_num -- i.err }
	C(uart_write_bytes)	//c uart-write-bytes	{ i.size a.src i.uart_num -- i.res }
	C(uart_read_bytes)	//c uart-read-bytes	{ i.wait i.size i.buf i.uart_num -- i.#bytes }
	C(uart_set_pin)		//c uart-set-pin	{ i.cts i.rts i.rx i.tx i.uart_num -- i.error? }
	C(uart_driver_install)	//c uart-driver-install	{ i.flags a.queue i.q_size i.tx_size i.rx_size i.uart_num -- i.error? }

	C(i2c_open)		//c i2c-open   { i.scl i.sda -- i.error? }
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
	C(gpio_deep_sleep_hold_en) //c gpio-deep-sleep-hold-en { -- }
	C(gpio_deep_sleep_hold_dis) //c gpio-deep-sleep-hold-dis { -- }
        C(esp_sleep_enable_ext0_wakeup) //c esp-sleep-enable-ext0-wakeup { i.level i.pin -- i.error? }
	C(gpio_hold_dis)	//c gpio-hold-dis { i.gpio# -- }
        C(gpio_hold_en)		//c gpio-hold-en { i.gpio# -- }
	C(get_wifi_mode)	//c wifi-mode@ { -- i.mode }
	C(wifi_open)		//c wifi-open { $ssid $password i.timeout -- i.error? }
 	C(esp_wifi_start)       //c esp-wifi-start             { -- }
 	C(esp_wifi_stop)        //c esp-wifi-stop              { -- }
 	C(esp_wifi_disconnect)  //c esp-wifi-disconnect        { -- }

  // LWIP sockets
  // Like Posix sockets but the socket descriptor space is not
  // merged with the file descriptor space, so you cannot
  // do a  that encompasses both
	C(lwip_socket)		//c socket         { i.proto i.type i.family -- i.handle }
	C(lwip_bind_r)		//c bind           { i.len a.addr i.handle -- i.error }
	C(lwip_setsockopt_r)	//c setsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
	C(lwip_getsockopt_r)	//c getsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
	C(lwip_connect_r)	//c connect        { i.len a.adr i.handle -- i.error }

	C(stream_connect)	//c stream-connect { i.timeout $.portname $.hostname -- i.handle }
	C(udp_client)		//c udp-connect    { $.portname $.hostname -- i.handle }
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
        C(my_spiffs_unmount)	//c spiffs-unmount { -- }


	C(raw_emit)		//c m-emit         { i.char -- }

	C(errno_val)		//c errno          { -- i.errno }
	C(strerror)		//c strerror       { i.errno -- $.msg }

        C(gpio_matrix_out)      //c gpio-matrix-out { i.inven i.invout i.fun i.pin -- }
        C(gpio_matrix_in)       //c gpio-matrix-in  { i.invert i.fun i.pin -- }

        C(mcpwm_gpio_init)       //c mcpwm_gpio_init  { i.gpio# i.io_signal i.pwm# -- e.err? }
        C(mcpwm_init)            //c mcpwm_init  { a.conf i.timer# i.pwm# -- e.err? }
        C(mcpwm_set_frequency)   //c mcpwm_set_frequency  { i.freq i.timer# i.pwm# -- e.err? }
        C(mcpwm_set_duty_in_us)  //c mcpwm_set_duty_in_us  { i.duty i.op# i.timer# i.pwm# -- e.err? }
	C(mcpwm_set_duty_type)	 //c mcpwm_set_duty_type { i.duty# i.op# i.timer# i.pwm# -- i.err? }
	C(mcpwm_get_frequency)	 //c mcpwm_get_frequency { i.timer# i.pwm# -- i.freq }
        C(mcpwm_set_signal_high) //c mcpwm_set_signal_high { i.op# i.timer# i.pwm# -- i.err? }
        C(mcpwm_set_signal_low)  //c mcpwm_set_signal_low { i.op# i.timer# i.pwm# -- i.err? }
        C(mcpwm_start)           //c mcpwm_start { i.timer# i.pwm# -- i.err? }
        C(mcpwm_stop)            //c mcpwm_stop { i.timer# i.pwm# -- i.err? }

        C(alarm)                 //c set-alarm   { i.xt i.ms -- }
        C(repeat_alarm)          //c repeat-alarm   { i.xt i.ms -- }
        C(alarm_us)              //c set-alarm-us   { i.xt i.us -- }
        C(repeat_alarm_us)       //c repeat-alarm-us   { i.xt i.us -- }

	C(sec_deep_sleep)            //c deep-sleep                 { i.sec -- }
 	C(ms_light_sleep)            //c light-sleep                { i.ms -- }

	C(esp_get_free_heap_size)    //c esp_get_free_heap_size     { -- i.size }

 	C(task)                      //c task                       { a.xt i.stack_size -- }
	C(xTaskGetCurrentTaskHandle) //c xTaskGetCurrentTaskHandle  { -- i.htask }
	C(vTaskDelay)                //c vTaskDelay                 { i.TicksToDelay -- }
 	C(vTaskResume)               //c vTaskResume                { i.htask -- }
 	C(vTaskSuspend)              //c vTaskSuspend               { i.htask -- }
 	C(vTaskDelete)               //c vTaskDelete                { i.htask -- }
 	C(vTaskPrioritySet)          //c vTaskPrioritySet           { a.prio i.handle -- }
        C(uxTaskPriorityGet)         //c uxTaskPriorityGet          { i.handle  -- i.prio }
 	C(vTaskSuspendAll)           //c vTaskSuspendAll            { -- }
 	C(xTaskResumeAll)            //c xTaskResumeAll             { -- }

        C(xQueueGenericCreate)       //c xQueueGenericCreate        { i.type i.itemsize i.qlength  -- i.handle }
 	C(xQueueGenericSend)         //c xQueueGenericSend          { i.front_back i.xTicksToWait i.pvItemToQueue i.qHandle -- i.res }
        C(xQueueGenericReceive)      //c xQueueReceive              { i.xTicksToWait a.pxRxedMessage i.qHandle -- i.res }
 	C(xQueueGenericReset)        //c xQueueGenericReset         { i.type i.handle -- }
 	C(uxQueueMessagesWaiting)    //c uxQueueMessagesWaiting     { i.handle -- i.waiting }
        C(vQueueDelete)              //c vQueueDelete               { i.handle  -- }

 	C(gpio_set_intr_type)        //c gpio_set_intr_type         { i.intr_type i.gpio_num -- i.res }
        C(gpio_install_isr_service)  //c gpio_install_isr_service   { i.no_use -- i.res }
 	C(gpio_isr_qhandler_add)     //c gpio_isr_qhandler_add      { i.hqueue i.gpio_num --  i.res }
 	C(gpio_intr_enable)          //c gpio_intr_enable           { i.handle -- i.err }
 	C(gpio_intr_disable)         //c gpio_intr_disable          { i.handle -- i.err }

 	C(esp_clk_cpu_freq)          //c esp-clk-cpu-freq           { -- i.hz }
 	C(rtc_clk_cpu_freq_set)      //c rtc-clk-cpu-freq-set       { i.freq123 -- }

	C(esp_now_open)		     //c esp-now-open               { i.channel -- i.error? }
	C(esp_now_init)		     //c esp-now-init               { -- i.error? }
	C(esp_now_deinit)            //c esp-now-deinit             { -- i.error? }
	C(add_my_peer)               //c esp-now-add-peer           { i.channel i.encryption i.to_mac -- }
	C(esp_now_send)              //c esp-now-send               { i.size a.data a.peer  -- i.error? }
 	C(get_max_payload_size)      //c get-max-payload-size       { -- i.max-payload-size-enow }
	C(set_esp_now_callback_rcv)  //c set-esp-now-callback-rcv   { i.HQueueEnow -- }
	C(esp_now_unregister_recv_cb) //c esp-now-unregister-recv_cb { -- }

// Spi master
 	C(spi_bus_init)              //c spi-bus-init               { i.dma, i.sclk i.miso, i.mosi --  i.res }
 	C(spi_bus_setup)             //c spi-bus-setup              { i.qsize, i.mode i.clkspeed --  i.handle }
 	C(spi_master_data)           //c spi-master-data            { i.len, a.send, a.receive, i.handle -- res }

// Spi slave
 	C(spi_bus_init_slave)  //c spi-bus-init-slave    { i.qsize, i.dma, i.mode, i.spics, i.sclk, i.miso, i.mosi -- i.res }
 	C(spi_slave_data)      //c spi-slave-data        { a.recvbuf, a.sendbuf, i.size i.ticks_to_wait -- i.res }
};
