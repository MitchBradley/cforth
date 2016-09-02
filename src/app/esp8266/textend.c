// Forth interfaces to platform-specific C routines
// See "ccalls" below.

#include "forth.h"

extern cell *callback_up;

#include "esp_stdint.h"
#include "platform.h"

cell deep_sleep(cell us, cell type)
{
  // XXX need to save the state in the user area
  system_deep_sleep_set_option((u_char)type);
  system_deep_sleep((uint32_t)us);
}

// For rtc_get_reset_reason()
// Also has SHA, MD5, base65, cycle counter
#include "rom.h"

#include "lwip/err.h"

struct tcp_pcb *tcp_new(void);
void tcp_arg(struct tcp_pcb *pcb, void* arg);
struct tcp_pcb *tcp_listen_with_backlog(struct tcp_pcb *pcb, uint8_t backlog);
err_t tcp_bind(struct tcp_pcb *pcb, struct ip_addr *ipaddr, uint16_t port);
void tcp_accepted1(struct tcp_pcb *pcb);
uint16_t tcp_sndbuf1(struct tcp_pcb *pcb);
err_t tcp_output(struct tcp_pcb *pcb);
void tcp_recved(struct tcp_pcb *pcb, uint16_t len);
err_t tcp_close(struct tcp_pcb *pcb);
void tcp_abort(struct tcp_pcb *pcb);
uint8_t pbuf_free(void *p);  // void* is really struct pbuf*
void tcp_sent_continues(struct tcp_pcb *pcb);

// From lwip.c.  We punt on the argument templates to avoid too many include files
cell tcp_write_sw();
void tcp_accept1();
void tcp_connect1();
void tcp_sent1();
void tcp_recv1();
void tcp_poll1();
void tcp_err1();

#include "driver/i2c_master.h"
cell i2c_send(cell byte)
{
  i2c_master_writeByte((uint8_t)byte);
  uint8_t r = i2c_master_getAck();
  if (r)
    i2c_master_stop();
  return r;
}
cell i2c_recv(cell nack)
{
  uint8_t r = i2c_master_readByte();
  i2c_master_setAck(nack);
  if (nack)
    i2c_master_stop();
  return r;
}

// Start + slave address + reg#
cell i2c_start_write(cell slave, cell reg)
{
  i2c_master_start();
  if (i2c_send(slave<<1))
    return -1;
  if (i2c_send(reg))
    return -1;

  return 0;
}

cell i2c_start_read(cell slave, cell stop)
{
  if (stop)
    i2c_master_stop();
  i2c_master_start();
  return i2c_send((slave<<1) | 1);
}

cell i2c_rb(cell stop, cell slave, cell reg)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_start_read(slave, stop))
    return -1;
  return i2c_recv(1);
}

cell i2c_wb(cell slave, cell reg, cell value)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_send(value))
    return -1;
  i2c_master_stop();
  return 0;
}

cell i2c_be_rw(cell stop, cell slave, cell reg)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_start_read(slave, stop))
    return -1;
  cell val = i2c_recv(0);
  val = (val<<8) + i2c_recv(1);
  return val;
}

cell i2c_le_rw(cell stop, cell slave, cell reg)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_start_read(slave, stop))
    return -1;
  cell val = i2c_recv(0);
  val += i2c_recv(1)<<8;
  return val;
}

cell i2c_be_ww(cell slave, cell reg, cell value)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_send(value>>8))
    return -1;
  if (i2c_send(value&0xff))
    return -1;
  i2c_master_stop();
  return 0;
}

cell i2c_le_ww(cell slave, cell reg, cell value)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_send(value&0xff))
    return -1;
  if (i2c_send(value>>8))
    return -1;
  i2c_master_stop();
  return 0;
}

extern void ets_timer_arm_new(os_timer_t* t, uint32_t milliseconds, uint32_t repeat_flag, uint32_t isMstimer);
extern void ets_timer_disarm(os_timer_t* t);
extern void ets_timer_setfn(os_timer_t* t, os_timer_func_t *f, void *arg);
extern void ets_delay_us(uint32_t us);

static os_timer_t delay_timer;

static void delay_callback(void *arg)
{
  inner_interpreter(callback_up);
}

static void start_ms(cell ms)
{
  ets_timer_setfn(&delay_timer, delay_callback, NULL);
  ets_timer_arm_new(&delay_timer, ms, 0, 1);
}

static os_timer_t alarm_timer;

static void alarm_callback(void *arg)
{
  execute_xt((xt_t)arg, callback_up);
}

static void alarm(cell ms, cell xt)
{
  ets_timer_setfn(&alarm_timer, alarm_callback, (void *)xt);
  ets_timer_arm_new(&alarm_timer, ms, 0, 1);
}

#if 0  // Doesn't work; counts milliseconds despite the 0 final argument
static void start_us(cell us)
{
  ets_timer_setfn(&delay_timer, delay_callback, NULL);
  ets_timer_arm_new(&delay_timer, us, 0, 0);
}
#endif

typedef struct {
  os_timer_t os_timer;
  xt_t cb_xt;
  uint32_t interval;
  uint32_t isms;
  uint32_t repeat;
} timer_t;

static void timer_callback(void *arg)
{
  timer_t *tp = (timer_t *)arg;

  if (!tp->cb_xt)
    return;

  cell *up = callback_up;
  execute_xt((xt_t)tp->cb_xt, up);
}

timer_t *new_timer(xt_t cb_xt)
{
  timer_t *tp = (timer_t *)pvPortZalloc(sizeof(timer_t), "", 0);
  ets_timer_setfn(&(tp->os_timer), timer_callback, (void *)tp);
  tp->cb_xt = cb_xt;
  return tp;
}

void rearm_timer(timer_t *tp)
{
  ets_timer_arm_new(&(tp->os_timer), tp->interval, tp->repeat, tp->isms);
}

// This argument order is better for Forth
void arm_timer(timer_t *tp, uint32_t repeat, uint32_t isms, uint32_t interval)
{
  tp->interval = interval;
  tp->isms = isms;
  tp->repeat = repeat;
  rearm_timer(tp);
}

xt_t gpio_callback_xt[NUM_GPIO];

#include "pin_map.h"

static void platform_gpio_intr_dispatcher(void *arg) {
  void (*cb)(unsigned, unsigned) = arg;
  uint32 gpio_status = GPIO_REG_READ(GPIO_STATUS_ADDRESS);
  uint8_t i, level;
  for (i = 0; i < GPIO_PIN_NUM; i++) {
    if (pin_int_type[i] && (gpio_status & BIT(pin_num[i])) ) {
      //disable interrupt
      gpio_pin_intr_state_set(GPIO_ID_PIN(pin_num[i]), GPIO_PIN_INTR_DISABLE);
      //clear interrupt status
      GPIO_REG_WRITE(GPIO_STATUS_W1TC_ADDRESS, gpio_status & BIT(pin_num[i]));
      level = 0x1 & GPIO_INPUT_GET(GPIO_ID_PIN(pin_num[i]));
      if(cb){
        cb(i, level);
      }
      gpio_pin_intr_state_set(GPIO_ID_PIN(pin_num[i]), pin_int_type[i]);
    }
  }
}

void gpio_callback(unsigned pin, unsigned level)
{
  if (!gpio_callback_xt[pin])
    return;
  cell *up = callback_up;
  spush(level, up);
  execute_xt((xt_t)gpio_callback_xt[pin], up);
}

void gpio_set_callback(unsigned pin, xt_t cb_xt)
{
  if (pin >= NUM_GPIO)
    return;
  gpio_callback_xt[pin] = cb_xt;
  ETS_GPIO_INTR_ATTACH(platform_gpio_intr_dispatcher, (void *)gpio_callback);
}

void disarm_timer(timer_t *tp)
{
  ets_timer_disarm(&(tp->os_timer));
}

void i2c_setup(cell sda, cell scl)
{
  platform_i2c_setup(0, sda, scl, 100000);
}


// Defined in fileio.c
void myspiffs_format(void);
void rename_file(char *new, char *old);
cell fs_avail(void);
void delete_file(char *path);
void *next_file(void);
void *first_file(void);
cell dirent_size(void *);
cell dirent_name(void *);

// extern void SPIRead(void);
extern void raw_putchar(unsigned char c);

#include "driver/onewire.h"

uint8_t owpin;
uint8_t owpower;
void ow_init(uint8_t pin, int power) { owpin = pin; owpower = power; onewire_init(owpin); };
uint8_t ow_reset() { return onewire_reset(owpin); };
void ow_select(const uint8_t rom[8]) { onewire_select(owpin, rom); };
void ow_skip() { onewire_skip(owpin); };
void ow_write(uint8_t v) { onewire_write(owpin, v, owpower); };
void ow_write_bytes(const uint8_t *buf, uint16_t count) { onewire_write_bytes(owpin, buf, count, owpower); };
uint8_t ow_read() { return onewire_read(owpin); };
void ow_read_bytes(uint8_t *buf, uint16_t count) { onewire_read_bytes(owpin, buf, count); };
void ow_depower() { onewire_depower(owpin); };
void ow_reset_search() { onewire_reset_search(owpin); };
void ow_target_search(uint8_t family_code) { onewire_target_search(owpin, family_code); };
uint8_t ow_search(uint8_t *newAddr) { onewire_search(owpin, newAddr); };

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

cell ((* const ccalls[])()) = {
  C(build_date_adr)   //c 'build-date     { -- a.value }
  C(version_adr)      //c 'version        { -- a.value }
  C(raw_putchar)      //c m-emit  { i.char -- }

  C(myspiffs_format)  //c fs-format  { -- }
  C(rename_file)      //c rename-file  { $.old $.new -- }
  C(delete_file)      //c delete-file  { $.name -- }
  C(fs_avail)         //c fs-avail  { -- i.bytes }
  C(first_file)       //c first-file { -- a.dirp }
  C(next_file)        //c next-file  { -- a.dirp' }
  C(dirent_size)      //c file-bytes { a.dirp -- i.size }
  C(dirent_name)      //c file-name  { a.dirp -- a.name }

  C(SPIRead) //c spi-read { i.len a.buf i.id -- }

  C(ow_init)		//c ow-init { i.power i.id -- }
  C(ow_reset)		//c ow-reset  { -- i.present? }
  C(ow_select)		//c ow-select  { a.romp -- }
  C(ow_skip)		//c ow-skip  { -- }
  C(ow_write)		//c ow-b!  { i.byte -- }
  C(ow_write_bytes)	//c ow-write  { i.len a.adr -- }
  C(ow_read)		//c ow-b@  { -- }
  C(ow_read_bytes)	//c ow-read  { i.len a.adr -- }
  C(ow_depower)		//c ow-depower  { -- }
  C(ow_reset_search)	//c ow-reset-search  { -- }
  C(ow_target_search)	//c ow-target-search  { i.family -- }
  C(ow_search)		//c ow-search  { a.newaddr -- i.ok? }
  C(onewire_crc8)	//c ow-crc8  { i.len a.adr -- i.crc }
  C(onewire_check_crc16)//c ow-check-crc16  { i.crc a.invcrc i.len a.input -- i.ok? }
  C(onewire_crc16)	//c ow-crc16  { i.crc i.len a.adr -- i.crc }

  C(i2c_setup)                //c i2c-setup     { i.scl i.sda -- }
  C(i2c_master_start)         //c i2c-start     { -- }
  C(i2c_master_stop)          //c i2c-stop      { -- }
  C(i2c_send)                 //c i2c-byte!     { i.byte -- acked? }
  C(i2c_recv)                 //c i2c-byte@     { i.nack? -- i.byte }
  C(i2c_start_write)          //c i2c-start-write { i.reg i.slave -- i.err? }
  C(i2c_start_read)           //c i2c-start-read  { i.stop? i.slave -- i.err? }
  C(i2c_rb)                   //c i2c-b@     { i.reg i.slave i.stop -- b }
  C(i2c_wb)                   //c i2c-b!     { i.value i.reg i.slave -- error? }
  C(i2c_be_rw)                //c i2c-be-w@  { i.reg i.slave i.stop -- w }
  C(i2c_le_rw)                //c i2c-le-w@  { i.reg i.slave i.stop -- w }
  C(i2c_be_ww)                //c i2c-be-w!  { i.value i.reg i.slave -- error? }
  C(i2c_le_ww)                //c i2c-le-w!  { i.value i.reg i.slave -- error? }

  C(platform_gpio_mode)     //c gpio-mode  { i.pull i.mode i.pin -- }
  C(platform_gpio_write)    //c gpio-pin!  { i.level i.pin -- }
  C(platform_gpio_read)     //c gpio-pin@  { i.pin -- i.level }
  C(platform_gpio_intr_init)//c gpio-enable-interrupt  { i.type i.pin -- }
  C(gpio_set_callback)      //c gpio-callback!  { i.cb_xt i.pin -- }

  C(platform_pwm_setup)     //c pwm-setup   { i.duty i.frequency i.pin -- }
  C(platform_pwm_get_clock) //c pwm-clock@  { i.pin -- i.frequency }
  C(platform_pwm_set_clock) //c pwm-clock!  { i.frequency i.pin -- }
  C(platform_pwm_get_duty)  //c pwm-duty@   { i.pin -- i.duty-cycle }
  C(platform_pwm_set_duty)  //c pwm-duty!   { i.duty-cycle i.pin -- }
  C(platform_pwm_close)     //c pwm-close   { i.pin -- }
  C(platform_pwm_start)     //c pwm-start   { i.pin -- }
  C(platform_pwm_stop)      //c pwm-stop    { i.pin -- }

  C(platform_spi_setup)     //c spi-setup  { i.div i.phase i.polarity i.mode i.id -- i.status }
  C(platform_spi_send_recv) //c spi-send-recv  { a.data i.bitlen i.id -- i.status }
  C(platform_spi_set_mosi)  //c spi-set-mosi   { a.data i.bitlen i.id -- i.status }
  C(platform_spi_get_miso)  //c spi-get-miso   { a.bitlen i.offset i.id -- i.status }
  C(platform_spi_transaction) //c spi-transaction   { i.misobits i.dummy i.mosibits a.adrdata i.adrbits a.cdata i.cbits i.id -- i.status }

  C(system_get_rst_info)    //c reset-info { -- a.rst_info }
  C(system_restore)         //c restore  { -- }
  C(system_restart)         //c restart  { -- }
  C(system_deep_sleep_set_option)  //c deep-sleep-option! { i.option -- }
  C(system_deep_sleep)      //c deep-sleep  { i.us -- }
  C(system_timer_reinit)    //c reinit-timer { -- }
  C(system_get_time)        //c timer@ { -- i.counter }
  C(system_os_post)         //c post-event { i.param i.sig i.prio -- i.stat }
  //  X(system_print_meminfo)   //x .meminfo     { -- }
  C(system_get_free_heap_size) //c heap-size { -- i.size }
  //  X(system_get_os_print)    //x system_get_os_print { -- i.on/off }
  C(system_set_os_print)    //c set-printf  { i.on/off -- }
  C(system_mktime)          //c mktime       { i.sec i.min i.hr i.day i.mon i.yr -- i.time }
  C(system_get_chip_id)     //c chip-id@    { -- i.id }
  C(system_rtc_clock_cali_proc) //c rtc-clock-cal  { -- i.val }
  C(system_get_rtc_time)    //c rtc-time@   { -- i.time }

  C(system_rtc_mem_read)    //c rtc-mem-read { i.len a.buf i.offset -- i.stat }
  C(system_rtc_mem_write)   //c rtc-mem-write  { i.len a.buf i.offset -- i.stat }

  C(system_uart_swap)       //c system_uart_swap { -- }
  C(system_uart_de_swap)    //c system_uart_de_swap { -- }

  C(system_adc_read)        //c adc@ { -- n }
  C(system_get_vdd33)       //c vdd33@ { -- n }

  C(system_get_sdk_version) //c sdk-version$ { -- a.vers }
  C(system_get_boot_version) //c boot-version@ { -- i.version }
  C(system_get_userbin_addr) //c userbin-addr@ { -- i.addr }
  C(system_get_boot_mode) //c boot-mode@ { -- i.mode }
  C(system_restart_enhance) //c restart-enhance { i.bin_type i.bin_addr -- i.stat }
  C(system_update_cpu_freq) //c cpu-freq! { i.freq -- i.stat }
  C(system_get_cpu_freq) //c cpu-freq@ { -- i.mhz }
  C(system_get_flash_size_map) //c flash-size-map@ { -- i.enum }
  C(system_phy_set_max_tpw) //c phy-max-tpw! { i.max -- }
  C(system_phy_set_tpw_via_vdd33) //c phy-tpw-via-vdd33! { i.vdd33 -- }
  C(system_phy_set_rfoption) //c phy-rfoption! { i.option -- }
  C(system_phy_set_powerup_option) //c phy-powerup-option! { i. option -- }
  C(system_param_save_with_protect) //c save-param-with-protect { i.len a.param i.start_sec -- i.stat }
  C(system_param_load) //c load-param { i.len a.param i.offset -- i.stat }
  C(system_soft_wdt_stop) //c soft-wdt-stop { -- }
  C(system_soft_wdt_restart) //c soft-wdt-restart { -- }
  C(system_soft_wdt_feed) //c soft-wdt-feed { -- }
  C(system_show_malloc) //c show-malloc { -- }

  C(wifi_set_phy_mode)      //c wifi-phymode!  { i.mode -- }
  C(wifi_get_phy_mode)      //c wifi-phymode@  { -- i.mode }
  C(wifi_set_sleep_type)    //c wifi-sleeptype! { i.type -- }
  C(wifi_get_sleep_type)    //c wifi-sleeptype@ { -- i.type }
  C(wifi_set_opmode)        //c wifi-opmode!  { i.mode -- }
  C(wifi_get_opmode)        //c wifi-opmode@  { -- i.mode }
  C(wifi_set_broadcast_if)  //c wifi-broadcast-if!  { i.mode -- i.stat }
  C(wifi_get_broadcast_if)  //c wifi-broadcast-if@  { -- i.mode }

  C(wifi_station_get_config) //c wifi-sta-config@  { a.buf -- i.stat }
  C(wifi_station_set_config) //c wifi-sta-config!  { a.buf -- i.stat }

  C(wifi_station_connect)    //c wifi-sta-connect    { -- i.stat }
  C(wifi_station_disconnect) //c wifi-sta-disconnect { -- i.stat }

  C(wifi_station_get_rssi)   //c wifi-sta-get-rssi   { -- i.rssi }

  C(wifi_station_scan)       //c wifi-sta-scan  { i.done-cb a.config -- i.stat }
  C(wifi_station_get_auto_connect)  //c wifi-sta-auto-connect@  { -- i.on? }
  C(wifi_station_set_auto_connect)  //c wifi-sta-auto-connect!  { i.on? -- i.stat }
  C(wifi_station_set_reconnect_policy) //c wifi-sta-reconnect!  { i.on? -- i.stat }
  C(wifi_station_get_connect_status) //c wifi-sta-connect@  { -- i.status }
  C(wifi_station_get_current_ap_id) //c wifi-sta-ap-id@ { -- i.id }
  C(wifi_station_ap_change) //c wifi-sta-ap-id!  { i.id -- i.stat }
  C(wifi_station_ap_number_set) //c wifi-sta-ap-number!  { i.ap# -- i.stat }
  C(wifi_station_get_ap_info) //c wifi-sta-ap-info@  { a.buf -- i.n }
  C(wifi_station_dhcpc_start) //c wifi-sta-dhcpc-start  { -- i.stat }
  C(wifi_station_dhcpc_stop) //c wifi-sta-dhcpc-stop   { -- i.stat }
  C(wifi_station_dhcpc_status) //c wifi-sta-dhcpc-status  { -- i.dhcpstat }
  C(wifi_station_dhcpc_set_maxtry) //c wifi-sta-dhcpc-retry!  { i.#retries -- i.stat }
  C(wifi_station_get_hostname) //c wifi-sta-hostname@  { -- $.hostname }
  C(wifi_station_set_hostname) //c wifi-sta-hostname!  { $.hostname -- i.stat }
  C(wifi_softap_get_config) //c wifi-ap-config@ { a.config -- i.stat }
  C(wifi_softap_set_config) //c wifi-ap-config! { a.config -- i.stat }
  C(wifi_softap_set_config_current) //c wifi-ap-config-current! { a.config -- i.stat }
  C(wifi_softap_get_station_num) //c wifi-ap-station-num@ { -- i.# }
  C(wifi_softap_get_station_info) //c wifi-ap-station-info@ { -- a.info }
  C(wifi_softap_free_station_info) //c wifi-ap-free-station-info { -- }
  C(wifi_softap_dhcps_start) //c wifi-ap-dhcps-start { -- i.stat }
  C(wifi_softap_dhcps_stop) //c wifi-ap-dhcps-stop { -- i.stat }
  C(wifi_softap_set_dhcps_lease) //c wifi-ap-dhcps-lease! { a.lease -- i.stat }
  C(wifi_softap_get_dhcps_lease) //c wifi-ap-dhcps-lease@ { a.lease -- i.stat }
  C(wifi_softap_get_dhcps_lease_time) //c wifi-ap-dhcps-lease-time@ { -- i.time }
  C(wifi_softap_set_dhcps_lease_time) //c wifi-ap-dhcps-lease-time! { i.minutes -- i.stat }
  C(wifi_softap_reset_dhcps_lease_time) //c wifi-ap-reset-dhcps-lease-time { -- i.stat }
  C(wifi_softap_dhcps_status) //c wifi-ap-dhcps-status { -- i.dhcpstat }
  C(wifi_softap_set_dhcps_offer_option) //c wifi-ap-dhcps-offer-option! { a.optarg i.level -- i.stat }
  C(wifi_get_ip_info) //c wifi-ip-info@ { a.ip_info i.if# -- i.stat }
  C(wifi_set_ip_info) //c wifi-ip-info! { a.ip_info i.if# -- i.stat }
  C(wifi_get_macaddr) //c wifi-macaddr@ { a.mac i.if# -- i.stat }
  C(wifi_set_macaddr) //c wifi-macaddr! { a.mac i.if# -- i.stat }
  C(wifi_get_channel) //c wifi-channel@ { -- i.ch# }
  C(wifi_set_channel) //c wifi-channel! { i.channel -- i.stat }
  C(wifi_status_led_install) //c wifi-status-led-install { i.func i.gpioname i.gpioid -- }
  C(wifi_status_led_uninstall) //c wifi-status-led-uninstall { -- }
  C(wifi_promiscuous_enable) //c wifi-promiscuous-enable { i.promiscuous) -- }
  C(wifi_set_promiscuous_rx_cb) //c wifi-promiscuous-rx-cb! { i.cb_xt -- }
  C(wifi_promiscuous_set_mac) //c wifi-promiscuous-mac! { a.mac -- }
  C(wifi_fpm_open) //c wifi-fpm-open { -- }
  C(wifi_fpm_close) //c wifi-fpm-close { -- }
  C(wifi_fpm_do_wakeup) //c wifi-fpm-do-wakeup { -- }
  C(wifi_fpm_do_sleep) //c wifi-fpm-do-sleep { i.us -- i.res }
  C(wifi_fpm_set_sleep_type) //c wifi-fpm-sleep-type! { i.sleeptype -- }
  C(wifi_fpm_get_sleep_type) //c wifi-fpm-sleep-type@ { -- i.sleeptype }
  C(wifi_set_event_handler_cb) //c wifi-set-event-handler-cb { i.cbxt -- }

  C(flash_rom_get_mode)     //c flash-mode  { -- i.mode }
  C(flash_rom_get_speed)    //c flash-speed { -- i.speed }
  C(flash_rom_get_size_byte)//c flash-size  { -- i.size }

  C(new_timer)              //c new-timer    { i.cb_xt -- a.timer }
  C(arm_timer)              //c arm-timer    { i.interval i.isms i.repeat a.timer -- }
  C(rearm_timer)            //c rearm-timer  { a.timer -- }
  C(disarm_timer)           //c disarm-timer { a.timer -- }

  C(start_ms)               //c start-ms    { i.ms -- }
  C(ets_delay_us)           //c us          { i.usecs -- }

  C(alarm)                  //c set-alarm   { i.xt i.ms -- }

  C(spi_flash_get_id)       //c flash-id    { -- i.id }
  C(spi_flash_erase_sector) //c flash-erase { i.sector -- i.result }
  C(spi_flash_write)        //c flash-write { i.len a.adr i.offset -- i.result }
  C(spi_flash_read)         //c flash-read  { i.len a.adr i.offset -- i.result }

  C(rtc_get_reset_reason)   //c reset-reason { -- i.reason }
  C(xthal_get_ccount)       //c xthal_get_ccount  { -- i.count }

  C(tcp_write_sw)           //c tcp-write  { a.adr i.len a.pcb -- i.stat }
  C(tcp_new)                //c tcp-new  { -- a.pcb }
  C(tcp_arg)                //c tcp-arg  { a.arg a.pcb -- }
  C(tcp_bind)               //c tcp-bind  { i.port a.ipaddr a.pcb -- i.stat }
  C(tcp_listen_with_backlog)//c tcp-listen-backlog  { i.backlog a.pcb1 -- a.pcb2 }
  C(tcp_accept1)            //c tcp-accept  { i.xt a.pcb -- }
  C(tcp_accepted1)          //c tcp-accepted  { a.pcb -- }
  C(tcp_connect1)           //c tcp-connect  { i.xt i.port a.ipaddr a.pcb -- i.stat }
  C(tcp_sent1)              //c tcp-sent  { i.xt a.pcb -- }
  C(tcp_recv1)              //c tcp-recv  { i.xt a.pcb -- }
  C(tcp_poll1)              //c tcp-poll  { i.interval i.xt a.pcb -- }
  C(tcp_err1)               //c tcp-err   { i.xt a.pcb -- }
  C(tcp_sndbuf1)            //c tcp-sendbuf  { a.pcb -- i.#bytes }
  C(tcp_output)             //c tcp-output  { a.pcb -- i.stat }
  C(tcp_recved)             //c tcp-recved  { i.len a.pcb -- }
  C(tcp_close)              //c tcp-close   { a.pcb -- i.stat }
  C(tcp_abort)              //c tcp-abort   { a.pcb -- }
  C(pbuf_free)              //c pbuf-free   { a.pbuf -- i.#freed }
  C(tcp_sent_continues)     //c tcp-sent-continues  { a.pcb -- }
};
