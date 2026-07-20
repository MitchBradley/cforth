/* extend_idf_compat.c - Compatible with IDF v5.5.1 */
/* Uses real IDF headers, not local typedefs */

#pragma GCC diagnostic ignored "-Wcast-function-type"

#include "forth_esp32.h"
#include "../../cforth/compiler.h"
#include "esp_sleep.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "driver/gpio.h"
#include "esp_err.h"
#include <string.h>

// Many of the routines cited below are defined either directly
// in the ESP32 SDK or in sdk_build/main/interface.c. It is best
// to avoid putting the definition of ESP-specific routines in
// this file, because doing so typically requires including a
// lot of .h files here, and that introduces a dependency on the
// SDK configurator, which greatly complicates the Makefile
// dependencies for the CForth portion of the build.
//
// We avoid that by just referring to the names of the routines
// we want to include in the ccalls[] table. The actual function
// signatures are defined in interface.c, which is compiled after
// the SDK configurator has run.
//
// NOTE: For ESP32-C3 compatibility, functions may have parameters.
// The ABI handles parameter order reversal automatically.

extern void interrupt_disable(void);
extern void interrupt_restore(void);
extern portMUX_TYPE global_int_mux;

extern esp_err_t wifi_start(void);
extern esp_err_t wifi_stop(void);

extern void my_adc_oneshot_new_unit(void);
extern void my_adc_create_calibration_scheme(void);
extern void my_adc_delete_calibration_scheme(void);
extern void my_adc_oneshot_config_channel(void);
extern void my_esp_sleep_enable_ext0_wakeup(void);
extern uint32_t esp_clk_cpu_freq(void);
extern void get_tick_rate_hz(void);
extern void get_system_time(void);
extern void set_system_time(void);
extern void my_lfs_unmount(void);
extern void sd_unmount(void);

extern void mcpwm_config(void);
extern void mcpwm_set_comparator(void);
extern void mcpwm_timer_control(void);

extern void software_reset(void);
extern void open_dir(void);
extern void dirent_size(void);
extern void rtc_fast(void);

extern void mysetvbuf(void);
extern void myfsync(void);
extern void my_uart_param_config(void);

extern void get_mem_size(void);
extern void spi_device_add_master(void);
extern void spi_master_data(void);

extern void my_spi_bus_init(void);
extern void my_spi_free(void);

extern TickType_t xTaskGetTickCount(void);
extern void my_vTaskDelay(void);
extern void raw_emit(void);

extern void us(void);
extern void set_log_level(void);

// See also i2c_legacy.fth
extern void i2c_bus_init(void);
extern void i2c_device_del(void);
extern void i2c_bus_del(void);
extern void i2c_device_add(void);
extern void i2c_master_readbyte(void);
extern void i2c_master_writebyte(void);
extern void i2c_master_readword(void);
extern void i2c_master_writeword(void);
extern void i2c_write_read(void);

extern void gpio_toggle(void);
extern void gpio_is_output(void);
extern void gpio_is_output_od(void);
extern void gpio_is_input(void);
extern void gpio_is_input_pu(void);
extern void gpio_is_input_pd(void);
extern void gpio_mode(void);

extern void ssid_available(void);
extern void wifi_is_connected(void);
extern void wifi_open(void);

extern void lwip_socket(void);
extern void lwip_bind_r(void);
extern void lwip_setsockopt_r(void);
extern void lwip_getsockopt_r(void);
extern void lwip_connect_r(void);
extern void try_receive(void);
extern void stream_connect(void);
extern void udp_client(void);
extern void udp_sendto_func(void);
extern void my_lwip_write(void);
extern void my_lwip_read(void);
extern void lwip_close_r(void);
extern void lwip_listen_r(void);
extern void lwip_accept_r(void);
extern void start_server(void);
extern void dhcpc_status(void);
extern void my_select(void);
extern void tcpip_adapter_get_ip_info(void);

extern void my_closedir(void);
extern void next_file(cell dir);
extern void dirent_name(cell dir);
extern void rename_file(void);
extern void delete_file(void);
extern void fs_avail(void);
extern void errno_val(void);
extern void gpio_matrix_out(void);
extern void gpio_matrix_in(void);
extern void xQueueGenericReceive(void);
extern void esp_now_open(void);
extern void esp_now_open_receiver(void);
extern void esp_now_get_data(void);
extern void esp_now_release_buffer(void);
extern void esp_now_listen(void);
extern void my_esp_now_add_peer(void);
extern void my_esp_now_del_peer(void);
extern void my_esp_now_send(void);
extern void i2c_write_read(void);
extern void sd_mount(void);
extern void scankey(void);

// Next direct calls to ESP-IDF SDK functions - thin wrappers only
// No additional logic or abstraction layers
extern void adc_oneshot_del_unit();
extern void adc_oneshot_read();
extern void adc_cali_raw_to_voltage();
extern void uart_write_bytes();
extern void uart_read_bytes();
extern void uart_set_pin();
extern void uart_driver_install();

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

extern void *callback_up;

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

// ------------ End Additions

cell ((* const ccalls[])()) = {
        C(build_date_adr)       //c 'build-date     { -- a.value }
        C(version_adr)          //c 'version        { -- a.value }
        C(us)                   //c us              { i.us -- }
        C(set_system_time)      //c set-system-time { i.seconds -- }
        C(get_system_time)      //c get-system-time! { a.2var_timeval -- }
        C(xTaskGetTickCount)    //c get-ticks       { -- i.ticks }
        C(software_reset)       //c restart         { -- }
        C(set_log_level)        //c log-level!      { i.level $component -- }

  C(my_adc_oneshot_new_unit)          //c adc-new-unit  { i.clk_src i.unit_id -- handle|0 }
  C(my_adc_oneshot_config_channel)    //c adc-config-channel { i.bitwidth i.atten i.channel i.handle -- i.error }
  C(my_adc_create_calibration_scheme) //c adc-create-calibration-scheme { i.bitwidth i.atten i.unit -- i.handle }
  C(my_adc_delete_calibration_scheme) //c adc-delete-calibration-scheme { i.handle -- }
  C(adc_oneshot_del_unit)             //c adc-del-unit  { i.handle -- i.error }
  C(adc_oneshot_read)                 //c adc-read-raw  { a.out_raw i.channel i.handle -- i.error }
  C(adc_cali_raw_to_voltage)          //c adc-raw-to-mv { a.out_mv i.raw i.handle -- i.error }


        C(my_uart_param_config) //c uart-param-config   { i.flow i.stop i.par i.#bits i.baud i.uart_num -- i.err }
        C(uart_write_bytes)     //c uart-write-bytes    { i.size a.src i.uart_num -- i.res }
        C(uart_read_bytes)      //c uart-read-bytes     { i.wait i.size a.buf i.uart_num -- i.#bytes }
        C(uart_set_pin)         //c uart-set-pin        { i.cts i.rts i.rx i.tx i.uart_num -- i.error? }
        C(uart_driver_install)  //c uart-driver-install { i.flags a.queue i.q_size i.tx_size i.rx_size i.uart_num -- i.error? }

        C(i2c_bus_init)         //c i2c-bus-init      { i.pullup i.scl i.sda i.glitch -- i.bus-handle }
        C(i2c_device_del)       //c i2c-device-delete { i.device-handle --  }
        C(i2c_bus_del)          //c i2c-bus-delete    { i.bus-handle --  }
        C(i2c_device_add)       //c i2c-device-add    { i.bus-handle i.tenbit i.addr i.speed i.wait -- i.device-handle }
        C(i2c_master_readbyte)  //c i2c-master-read-byte  { i.reg i.device-handle  -- byte }
        C(i2c_master_writebyte) //c i2c-master-write-byte { i.value  i.reg  i.device-handle -- i.error }
        C(i2c_master_readword)  //c i2c-master-read-word  { i.reg i.device-handle  -- byte }
        C(i2c_master_writeword) //c i2c-master-write-word { i.value  i.reg  i.device-handle -- i.error }
        C(i2c_write_read)       //c i2c-master-write-read { a.wbuf i.wsize a.rbuf i.rsize i.device-handle -- i.error }

        C(gpio_get_level)       //c gpio-pin@  { i.gpio# -- i.flag }
        C(gpio_set_level)       //c gpio-pin!  { i.level i.gpio# -- }
        C(gpio_toggle)          //c gpio-toggle { i.gpio# -- }
        C(gpio_is_output)       //c gpio-is-output { i.gpio# -- }
        C(gpio_is_output_od)    //c gpio-is-output-open-drain { i.gpio# -- }
        C(gpio_is_input)        //c gpio-is-input { i.gpio# -- }
        C(gpio_is_input_pu)     //c gpio-is-input-pullup { i.gpio# -- }
        C(gpio_is_input_pd)     //c gpio-is-input-pulldown { i.gpio# -- }
        C(gpio_mode)            //c gpio-mode { i.pullup? i.direction i.gpio# -- }

        C(gpio_deep_sleep_hold_en)  //c gpio-deep-sleep-hold-en { -- }
        C(gpio_deep_sleep_hold_dis) //c gpio-deep-sleep-hold-dis { -- }
        C(my_esp_sleep_enable_ext0_wakeup) //c esp-sleep-enable-ext0-wakeup { i.level i.pin -- i.error? }
        C(gpio_hold_dis)        //c gpio-hold-dis { i.gpio# -- }
        C(gpio_hold_en)         //c gpio-hold-en { i.gpio# -- }

        C(gpio_set_intr_type)        //c gpio_set_intr_type         { i.intr_type i.gpio_num -- i.res }
        C(gpio_install_isr_service)  //c gpio_install_isr_service   { i.no_use -- i.res }
        C(gpio_isr_qhandler_add)     //c gpio_isr_qhandler_add      { i.hqueue i.gpio_num --  i.res }
        C(gpio_intr_enable)          //c gpio_intr_enable           { i.handle -- i.err }
        C(gpio_intr_disable)         //c gpio_intr_disable          { i.handle -- i.err }

        C(ssid_available)       //c ssid_available { $.ssid i.timeout -- i.flag }
        C(wifi_is_connected)    //c wifi-connected@ { -- i.flag }
        C(wifi_open)            //c wifi-open { $ssid $password i.timeout i.auth_mod  -- ior }
        C(wifi_start)           //c esp-wifi-start             { -- }
        C(wifi_stop)            //c esp-wifi-stop              { -- }

  // LWIP sockets
  // Like Posix sockets but the socket descriptor space is not
  // merged with the file descriptor space, so you cannot
  // do a  that encompasses both
        C(lwip_socket)          //c socket         { i.proto i.type i.family -- i.handle }
        C(lwip_bind_r)          //c bind           { i.len a.addr i.handle -- i.error }
        C(lwip_setsockopt_r)    //c setsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
        C(lwip_getsockopt_r)    //c getsockopt     { i.len a.addr i.optname i.level i.handle -- i.error }
        C(lwip_connect_r)       //c connect        { i.len a.adr i.handle -- i.error }
        C(try_receive)          //c try-receive    { a.adr i.len i.socket -- i.length }
        C(stream_connect)       //c stream-connect { i.timeout $.portname $.hostname -- i.handle }
        C(udp_client)           //c udp-connect    { $.portname $.hostname -- i.handle }
        C(udp_sendto_func)      //c udp-sendto     { a.data i.len $.port $.host -- i.bytes-sent }
        C(my_lwip_write)        //c lwip-write     { a.buf i.size i.handle -- i.count }
        C(my_lwip_read)         //c lwip-read      { a.buf i.size i.handle -- i.count }
        C(lwip_close_r)         //c lwip-close     { i.handle -- }
        C(lwip_listen_r)        //c lwip-listen    { i.backlog i.handle -- i.handle }
        C(lwip_accept_r)        //c lwip-accept    { a.addrlen a.addr i.handle -- i.error }

        C(start_server)         //c start-server   { i.port -- i.error }
        C(dhcpc_status)         //c dhcp-status    { -- i.status }
        C(my_select)            //c lwip-select    { i.sec a.exc a.wr a.rd i.n -- i.cnt }
        C(tcpip_adapter_get_ip_info) //c ip-info@  { a.buf i.adapter# -- i.error }

        C(open_dir)             //c open-dir       { $.base_path -- a.dir }
        C(my_closedir)          //c close-dir      { a.dir -- }
        C(next_file)            //c next-file      { a.dir -- a.dirent }
        C(dirent_size)          //c file-bytes     { $.name-full a.dir -- i.size }
        C(dirent_name)          //c file-name      { a.dir -- a.name }
        C(rename_file)          //c rename-file    { $.full-old $.full-new -- i.ior }
        C(delete_file)          //c delete-file    { $.full-name -- i.ior }
        C(fs_avail)             //c fs-avail       { a.free64b $.volume -- }
        C(my_lfs_unmount)       //c lfs_unmount	   { -- i.res }

        C(raw_emit)             //c m-emit         { i.char -- }
        C(scankey)              //c scankey        { -- i.scan_code }

        C(errno_val)            //c errno          { -- i.errno }
        C(strerror)             //c strerror       { i.errno -- $.msg }

        C(gpio_matrix_out)      //c gpio-matrix-out { i.inven i.invout i.fun i.pin -- }
        C(gpio_matrix_in)       //c gpio-matrix-in  { i.invert i.fun i.pin -- }

        C(mcpwm_config)         //c mcpwm-config     { i.gpio i.pwn_i.freq i.resolution_hz i.timer i.unit a.hndl_ret  -- i.error }
        C(mcpwm_set_comparator) //c mcpwm-set-comparator  { i.compare_ticks i.hnl_cmpr -- i.err }
        C(mcpwm_timer_control)  //c mcpwm-timer-control   { i.flag i.hndl_timer -- i.err }

        C(alarm)                 //c set-alarm   { i.xt i.ms -- }
        C(repeat_alarm)          //c repeat-alarm   { i.xt i.ms -- }
        C(alarm_us)              //c set-alarm-us   { i.xt i.us -- }
        C(repeat_alarm_us)       //c repeat-alarm-us   { i.xt i.us -- }

        C(sec_deep_sleep)            //c deep-sleep                 { i.sec -- }
        C(ms_light_sleep)            //c light-sleep                { i.ms -- }
        C(get_mem_size)              //c get-mem-size               { i.memtype a.buffer -- }

        C(xTaskGetCurrentTaskHandle) //c xTaskGetCurrentTaskHandle  { -- i.htask }
        C(my_vTaskDelay)             //c vTaskDelay                 { i.ms -- }
        C(vTaskPrioritySet)          //c vTaskPrioritySet           { a.prio i.handle -- }
        C(uxTaskPriorityGet)         //c uxTaskPriorityGet          { i.handle  -- i.prio }

        C(xQueueGenericCreate)       //c xQueueGenericCreate        { i.type i.itemsize i.qlength  -- i.handle }
        C(xQueueGenericSend)         //c xQueueGenericSend          { i.front_back i.xTicksToWait i.pvItemToQueue i.qHandle -- i.res }
        C(xQueueGenericReceive)      //c xQueueReceive              { i.xTicksToWait a.pxRxedMessage i.qHandle -- i.res }
        C(xQueueGenericReset)        //c xQueueGenericReset         { i.type i.handle -- }
        C(uxQueueMessagesWaiting)    //c uxQueueMessagesWaiting     { i.handle -- i.waiting }
        C(vQueueDelete)              //c vQueueDelete               { i.handle  -- }

        C(esp_clk_cpu_freq)          //c esp-clk-cpu-freq           { -- i.hz }
        C(get_tick_rate_hz)          //c get-tick-rate-hz           { -- i.hz }

        C(esp_now_open)              //c esp-now-open               { i.channel -- i.error? }
        C(esp_now_open_receiver)     //c esp-now-open-receiver      { i.channel a.buffer -- i.error? }

        C(esp_now_listen)            //c esp-now-listen             { -- i.flag }
        C(esp_now_get_data)          //c esp-now-get-data           { -- a.buffer }
        C(esp_now_release_buffer)    //c esp-now-release-buffer     { -- }
        C(my_esp_now_add_peer)       //c esp-now-add-peer           { i.channel i.encryption i.mac -- }
        C(my_esp_now_del_peer)       //c esp-now-del-peer           { a.mac -- i.res }
        C(my_esp_now_send)           //c esp-now-send               { i.timeout_ms a.data i.size a.peer  -- i.error? }

        C(rtc_fast)                  //c rtc-fast                    { i.offset -- a.rtc_fast }

 C(spi_device_add_master) //c spi-device-add { i.host_id i.clock_speed i.mode i.cs_pin i.queue_size i.flags a.handle_ptr -- i.error }
        C(spi_master_data)      //c spi-master-data  { i.len a.send a.receive i.handle -- i.res }
        C(my_spi_bus_init)      //c spi-bus-init     { i.max-transfer  i.host_id i.mosi i.miso i.sclk -- i.error }
        C(my_spi_free)          //c spi-free         { i.dev_handle i.bus_handle -- i.error }
        C(sd_mount)             //c mount-sd-card    { i.cs i.format_if_fail i.speed_khz i.host -- i.ior }
        C(sd_unmount)           //c sd-unmount       { i.handle -- i.res }
        C(mysetvbuf)            //c setvbuf          { i.handle i.method a.buf i.blksize -- i.res }
        C(myfsync)              //c fsync            { i.handle -- i.res }
};
