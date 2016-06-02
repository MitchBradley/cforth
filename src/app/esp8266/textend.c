// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include "forth.h"
#include "user_interface.h"

// Prototypes

#include "platform.h"

cell deep_sleep(cell us, cell type)
{
  // XXX need to save the state in the user area
  system_deep_sleep_set_option((u_char)type);
  system_deep_sleep((uint32_t)us);
}

#include "flash_api.h"

// For rtc_get_reset_reason()
// Also has SHA, MD5, base65, cycle counter
#include "rom.h"

#include "driver/i2c_master.h"
#include "driver/onewire.h"

void node_restore(void)
{
  flash_init_data_default();
  flash_init_data_blank();
  system_restore();
}

#include "espconn.h"

extern sint8 espconn_tcp_set_buf_count(struct espconn *espconn, uint8 num);

typedef struct callbacks
{
  xt_t connected;
  xt_t reconnected;
  xt_t disconnected;
  xt_t received;
  xt_t sent;
  xt_t dns_found;
} callbacks_t;

// callback dispatchers

// XXX set me!
extern cell *callback_up;

static void connected(void *arg)
{
  callbacks_t *cb = ((struct espconn *)arg)->reverse;

  if(!cb->connected)
    return;

  cell *up = callback_up;
  spush(arg, up);
  execute_xt((xt_t)cb->connected, up);
}

static void disconnected(void *arg)
{
  callbacks_t *cb = ((struct espconn *)arg)->reverse;

  if(!cb->disconnected)
    return;

  cell *up = callback_up;
  spush(arg, up);
  execute_xt((xt_t)cb->disconnected, up);
}

static void reconnected(void *arg, sint8 err)
{
  callbacks_t *cb = ((struct espconn *)arg)->reverse;

  if(!cb->reconnected)
    return;

  cell *up = callback_up;
  spush(arg, up);
  execute_xt((xt_t)cb->reconnected, up);
}

static void received(void *arg, char *pdata, unsigned short len)
{
  callbacks_t *cb = ((struct espconn *)arg)->reverse;

  if (!cb->received)
    return;

  cell *up = callback_up;
  spush(pdata, up);
  spush(len, up);
  spush(arg, up);
  execute_xt((xt_t)cb->received, up);
}

static void sent(void *arg)
{
  callbacks_t *cb = ((struct espconn *)arg)->reverse;

  if (!cb->sent)
    return;

  cell *up = callback_up;
  spush(arg, up);
  execute_xt((xt_t)cb->sent, up);
}

static void dns_found(const char *name, ip_addr_t *ipaddr, void *arg)
{
  callbacks_t *cb = ((struct espconn *)arg)->reverse;

  if (!cb->dns_found)
    return;

  cell *up = callback_up;
  spush(ipaddr, up);
  spush(arg, up);
  execute_xt((xt_t)cb->dns_found, up);
}

// end of callback dispatchers

static struct espconn *new_conn(int type, xt_t rx_xt, xt_t tx_xt)
{
  struct espconn *pesp_conn = (struct espconn *)pvPortZalloc(sizeof(struct espconn), "", 0);
  pesp_conn->proto.tcp = (esp_tcp *)pvPortZalloc(sizeof(esp_tcp), "", 0);  // Size is 32
  pesp_conn->type = type;
  pesp_conn->state = ESPCONN_NONE;

  callbacks_t *cb = (callbacks_t *)pvPortZalloc(sizeof(callbacks_t), "", 0);
  pesp_conn->reverse = cb;
  cb->sent = tx_xt;
  cb->received = rx_xt;
  espconn_regist_recvcb(pesp_conn, received);
  espconn_regist_sentcb(pesp_conn, sent);

  return pesp_conn;
}

static struct espconn *listen_start(unsigned type, const char *domain, unsigned port,
                             xt_t rx_xt, xt_t tx_xt)
{
  //  ets_delay_us(10*1000);
  struct espconn *pesp_conn = new_conn(type, rx_xt, tx_xt);
  pesp_conn->proto.tcp->local_port = port;

  ip_addr_t ipaddr;
  ipaddr.addr = ipaddr_addr(domain ? domain : "0.0.0.0");
  ets_memcpy(pesp_conn->proto.tcp->local_ip, &ipaddr.addr, 4);
  return pesp_conn;
}

static void register_tcp_callbacks(struct espconn *pesp_conn,
                                   xt_t conn_xt, xt_t disconn_xt, xt_t reconn_xt)
{
  callbacks_t *cb = (callbacks_t *)pesp_conn->reverse;
  cb->connected = conn_xt;
  cb->disconnected = disconn_xt;
  cb->reconnected = reconn_xt;

  espconn_regist_connectcb(pesp_conn, connected);
  espconn_regist_disconcb(pesp_conn, disconnected);
  espconn_regist_reconcb(pesp_conn, reconnected);
}

struct espconn *tcp_listen(int timeout,
                           unsigned port, const char *domain,
                           xt_t rx_xt, xt_t tx_xt,
                           xt_t conn_xt, xt_t disconn_xt, xt_t reconn_xt)
{
  struct espconn *pesp_conn = listen_start(ESPCONN_TCP, domain, port, rx_xt, tx_xt);

  register_tcp_callbacks(pesp_conn, conn_xt, disconn_xt, reconn_xt);

  espconn_accept(pesp_conn);
  espconn_regist_time(pesp_conn, timeout, 0);
  return pesp_conn;
}

struct espconn *udp_listen(unsigned port, const char *domain,
                           xt_t rx_xt, xt_t tx_xt)
{
  struct espconn *pesp_conn = listen_start(ESPCONN_UDP, domain, port, rx_xt, tx_xt);

  espconn_create(pesp_conn);  // Setup a new UDP listener
  return pesp_conn;
}

static void free_espconn(struct espconn *pesp_conn)
{
  if (pesp_conn->reverse)
    vPortFree(pesp_conn->reverse, "", 0);

  if (pesp_conn->proto.tcp)
    vPortFree(pesp_conn->proto.tcp, "", 0);

  vPortFree(pesp_conn, "", 0);
}

void unlisten(struct espconn *pesp_conn)
{
  if (!pesp_conn)
    return;
  espconn_delete(pesp_conn);
  free_espconn(pesp_conn);
}

static ip_addr_t host_ip; // for dns

static dns_reconn_count = 0;
static void socket_connect(struct espconn *pesp_conn)
{
  if( pesp_conn->type == ESPCONN_TCP )  {
    espconn_connect(pesp_conn);
  } else if (pesp_conn->type == ESPCONN_UDP)   {
    espconn_create(pesp_conn);
  }
}

static void socket_dns_found(const char *name, ip_addr_t *ipaddr, void *arg)
{
  struct espconn *pesp_conn = (struct espconn *)arg;
  if(ipaddr == NULL) {
    dns_reconn_count++;
    if( dns_reconn_count >= 5 ){
      return;
    }
    host_ip.addr = 0;
    espconn_gethostbyname(pesp_conn, name, &host_ip, socket_dns_found);
    return;
  }

  if(ipaddr->addr != IPADDR_NONE)  {
    dns_reconn_count = 0;
    ets_memcpy(pesp_conn->proto.tcp->remote_ip, &(ipaddr->addr), 4);
    socket_connect(pesp_conn);
  }
}

static struct espconn *connect_start(unsigned type, const char *domain, unsigned port,
                                     xt_t rx_xt, xt_t tx_xt)
{

  struct espconn *pesp_conn = new_conn(type, rx_xt, tx_xt);
  pesp_conn->proto.tcp->remote_port = port;
  pesp_conn->proto.tcp->local_port = espconn_port();

  *((uint32_t *)pesp_conn->proto.tcp->remote_ip) = ipaddr_addr(domain ? domain : "127.0.0.1");

  return pesp_conn;
}

static void connect_end(struct espconn *pesp_conn, const char *domain)
{
  if (*(uint32_t *)(pesp_conn->proto.tcp->remote_ip) == IPADDR_NONE &&
     (!domain || (ets_memcmp(domain,"255.255.255.255",16) != 0))) {
    host_ip.addr = 0;
    dns_reconn_count = 0;
    if(ESPCONN_OK == espconn_gethostbyname(pesp_conn, domain, &host_ip, socket_dns_found)){
      socket_dns_found(domain, &host_ip, pesp_conn);  // ip is returned in host_ip.
    }
  } else {
    socket_connect(pesp_conn);
  }
}

struct espconn *my_tcp_connect(unsigned port, const char *domain, xt_t rx_xt, xt_t tx_xt,
                            xt_t conn_xt, xt_t disconn_xt, xt_t reconn_xt)
{
  struct espconn *pesp_conn = connect_start(ESPCONN_TCP, domain, port, rx_xt, tx_xt);

  register_tcp_callbacks(pesp_conn, conn_xt, disconn_xt, reconn_xt);

  if (pesp_conn->proto.tcp->remote_port || pesp_conn->proto.tcp->local_port) {
    espconn_disconnect(pesp_conn);
  }

  connect_end(pesp_conn, domain);
  return pesp_conn;
}

struct espconn *my_udp_connect(unsigned port, const char *domain, xt_t rx_xt, xt_t tx_xt)
{
  struct espconn *pesp_conn = connect_start(ESPCONN_UDP, domain, port, rx_xt, tx_xt);

  if(pesp_conn->proto.udp->remote_port || pesp_conn->proto.udp->local_port)
    espconn_delete(pesp_conn);

  connect_end(pesp_conn, domain);
  return pesp_conn;
}

void my_tcp_disconnect(struct espconn *pesp_conn)
{
  if (!pesp_conn)
    return;
  espconn_disconnect(pesp_conn);
  //  free_espconn(pesp_conn);
}

cell send(struct espconn *pesp_conn, uint16 len, uint8 *adr)
{
  // XXX this doesn't work for the UDP server case; for that
  // we need to look up the remote IP and port number as in net.c
  return espconn_send(pesp_conn, adr, len);
}

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
  platform_gpio_init(gpio_callback);
}

void disarm_timer(timer_t *tp)
{
  ets_timer_disarm(&(tp->os_timer));
}

void i2c_setup(cell sda, cell scl)
{
  platform_i2c_setup(0, sda, scl, 100000);
}

#include "spiffs.h"
extern spiffs fs;

void rename_file(char *new, char *old)
{
  myspiffs_rename(old, new);
}
cell fs_avail(void)
{
  uint32_t total, used;
  SPIFFS_info(&fs, &total, &used);
  return (cell)(total - used);
}

void delete_file(char *path)
{
  SPIFFS_remove(&fs, path);
}

static struct spiffs_dirent dirent;
static spiffs_DIR dir;
static struct spiffs_dirent *next_file(void)
{
  struct spiffs_dirent *dp = &dirent;
  while ((dp = SPIFFS_readdir(&dir, dp)) != NULL) {
    if (dp->type == SPIFFS_TYPE_FILE) {
      return dp;
    }
  }
  return 0;
}
static struct spiffs_dirent *first_file(void)
{
  if (SPIFFS_opendir(&fs, "", &dir))
    return next_file();
  return 0;
}

static cell dirent_size(struct spiffs_dirent *d)
{
  return d->size;
}

static cell dirent_name(struct spiffs_dirent *d)
{
  return (cell)(d->name);
}

int myspiffs_format(void);

extern void SPIRead(void);
extern void raw_putchar(unsigned char c);

cell ((* const ccalls[])()) = {
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

  C(onewire_init) //c ow-init { i.id -- }
  C(onewire_reset) //c ow-reset  { i.id -- i.present? }
  C(onewire_select) //c ow-select  { a.romp i.id -- }
  C(onewire_skip) //c ow-skip  { i.id -- }
  C(onewire_write) //c ow-b!  { i.power i.byte i.id -- }
  C(onewire_write_bytes) //c ow-write  { i.power i.len a.adr i.id -- }
  C(onewire_read) //c ow-b@  { i.id -- }
  C(onewire_read_bytes) //c ow-read  { i.len a.adr i.id -- }
  C(onewire_depower) //c ow-depower  { i.id -- }
  C(onewire_reset_search) //c ow-reset-search  { i.id -- }
  C(onewire_target_search) //c ow-target-search  { i.family i.id -- }
  C(onewire_search) //c ow-search  { a.newaddr i.id -- i.ok? }
  C(onewire_crc8) //c ow-crc8  { i.len a.adr -- i.crc }
  C(onewire_check_crc16) //c ow-check-crc16  { i.crc a.invcrc i.len a.input -- i.ok? }
  C(onewire_crc16) //c ow-crc16  { i.crc i.len a.adr -- i.crc }

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
  //  X(system_set_os_print)    //x system_set_os_print { i.on/off -- }
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

  C(system_get_sdk_version) //c sdk-version$ { -- $.vers }
  C(system_get_boot_version) //c boot-version@ { -- i.version }
  C(system_get_userbin_addr) //c userbin-addr@ { -- i.addr }
  C(system_get_boot_mode) //c boot-mode@ { -- i.mode }
  C(system_restart_enhance) //c restart-enhance { uint8 bin_type, uint32 bin_addr -- i.stat }
  C(system_update_cpu_freq) //c cpu-freq! { uint8 freq -- i.stat }
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
  C(system_show_malloc) //c show_malloc { -- }

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

  C(spi_flash_get_id)       //c flash-id    { -- i.id }
  C(spi_flash_erase_sector) //c flash-erase { i.sector -- i.result }
  C(spi_flash_write)        //c flash-write { i.len a.adr i.offset -- i.result }
  C(spi_flash_read)         //c flash-read  { i.len a.adr i.offset -- i.result }

  C(rtc_get_reset_reason)   //c reset-reason { -- i.reason }
  C(xthal_get_ccount)       //c xthal_get_ccount  { -- i.count }
  C(node_restore)           //c node-restore { -- }

  C(tcp_listen)             //c tcp-listen  { i.reconn_xt i.disconn_xt i.conn_xt i.tx_xt i.rx_xt $.domain i.port i.timeout -- a.handle }
  C(udp_listen)             //c udp-listen  { i.tx_xt i.rx_xt $.domain i.port -- a.handle }
  C(unlisten)               //c unlisten    { a.handle -- }
  C(my_tcp_connect)         //c tcp-connect { i.reconn_xt i.disconn_xt i.conn_xt i.tx_xt i.rx_xt $.domain i.port -- a.handle }
  C(my_udp_connect)         //c udp-connect { i.tx_xt i.rx_xt $.domain i.port -- a.handle }
  C(my_tcp_disconnect)      //c tcp-disconnect  { a.handle -- }
  C(espconn_tcp_set_buf_count) //c tcp-bufcnt!  { i.num a.handle -- }
  C(send)                   //c send  { a.buf i.len a.handle -- i.stat }
};

#if 0
struct station_config {
    uint8 ssid[32];
    uint8 password[64];
    uint8 bssid_set;	// Note: If bssid_set is 1, station will just connect to the router
                        // with both ssid[] and bssid[] matched. Please check about this.
    uint8 bssid[6];
};


struct scan_config {
    uint8 *ssid;	// Note: ssid == NULL, don't filter ssid.
    uint8 *bssid;	// Note: bssid == NULL, don't filter bssid.
    uint8 channel;	// Note: channel == 0, scan all channels, otherwise scan set channel.
    uint8 show_hidden;	// Note: show_hidden == 1, can get hidden ssid routers' info.
};

struct softap_config {
    uint8 ssid[32];
    uint8 password[64];
    uint8 ssid_len;	// Note: Recommend to set it according to your ssid
    uint8 channel;	// Note: support 1 ~ 13
    AUTH_MODE authmode;	// Note: Don't support AUTH_WEP in softAP mode.
    uint8 ssid_hidden;	// Note: default 0
    uint8 max_connection;	// Note: default 4, max 4
    uint16 beacon_interval;	// Note: support 100 ~ 60000 ms, default 100
};

struct station_info {
	STAILQ_ENTRY(station_info)	next;

	uint8 bssid[6];
	struct ip_addr ip;
};

struct dhcps_lease {
	bool enable;
	struct ip_addr start_ip;
	struct ip_addr end_ip;
};

enum dhcps_offer_option{
	OFFER_START = 0x00,
	OFFER_ROUTER = 0x01,
	OFFER_END
};

#define STATION_IF      0x00
#define SOFTAP_IF       0x01

/** Get the absolute difference between 2 u32_t values (correcting overflows)
 * 'a' is expected to be 'higher' (without overflow) than 'b'. */
#define ESP_U32_DIFF(a, b) (((a) >= (b)) ? ((a) - (b)) : (((a) + ((b) ^ 0xFFFFFFFF) + 1)))

typedef void (* wifi_promiscuous_cb_t)(uint8 *buf, uint16 len);

enum phy_mode {
	PHY_MODE_11B	= 1,
	PHY_MODE_11G	= 2,
	PHY_MODE_11N    = 3
};

enum sleep_type {
	NONE_SLEEP_T	= 0,
	LIGHT_SLEEP_T,
	MODEM_SLEEP_T
};

enum {
    EVENT_STAMODE_CONNECTED = 0,
    EVENT_STAMODE_DISCONNECTED,
    EVENT_STAMODE_AUTHMODE_CHANGE,
    EVENT_STAMODE_GOT_IP,
    EVENT_STAMODE_DHCP_TIMEOUT,
    EVENT_SOFTAPMODE_STACONNECTED,
    EVENT_SOFTAPMODE_STADISCONNECTED,
    EVENT_SOFTAPMODE_PROBEREQRECVED,
    EVENT_MAX
};

enum {
	REASON_UNSPECIFIED              = 1,
	REASON_AUTH_EXPIRE              = 2,
	REASON_AUTH_LEAVE               = 3,
	REASON_ASSOC_EXPIRE             = 4,
	REASON_ASSOC_TOOMANY            = 5,
	REASON_NOT_AUTHED               = 6,
	REASON_NOT_ASSOCED              = 7,
	REASON_ASSOC_LEAVE              = 8,
	REASON_ASSOC_NOT_AUTHED         = 9,
	REASON_DISASSOC_PWRCAP_BAD      = 10,  /* 11h */
	REASON_DISASSOC_SUPCHAN_BAD     = 11,  /* 11h */
	REASON_IE_INVALID               = 13,  /* 11i */
	REASON_MIC_FAILURE              = 14,  /* 11i */
	REASON_4WAY_HANDSHAKE_TIMEOUT   = 15,  /* 11i */
	REASON_GROUP_KEY_UPDATE_TIMEOUT = 16,  /* 11i */
	REASON_IE_IN_4WAY_DIFFERS       = 17,  /* 11i */
	REASON_GROUP_CIPHER_INVALID     = 18,  /* 11i */
	REASON_PAIRWISE_CIPHER_INVALID  = 19,  /* 11i */
	REASON_AKMP_INVALID             = 20,  /* 11i */
	REASON_UNSUPP_RSN_IE_VERSION    = 21,  /* 11i */
	REASON_INVALID_RSN_IE_CAP       = 22,  /* 11i */
	REASON_802_1X_AUTH_FAILED       = 23,  /* 11i */
	REASON_CIPHER_SUITE_REJECTED    = 24,  /* 11i */

	REASON_BEACON_TIMEOUT           = 200,
	REASON_NO_AP_FOUND              = 201,
	REASON_AUTH_FAIL				= 202,
	REASON_ASSOC_FAIL				= 203,
	REASON_HANDSHAKE_TIMEOUT		= 204,
};

typedef struct {
	uint8 ssid[32];
	uint8 ssid_len;
	uint8 bssid[6];
	uint8 channel;
} Event_StaMode_Connected_t;

typedef struct {
	uint8 ssid[32];
	uint8 ssid_len;
	uint8 bssid[6];
	uint8 reason;
} Event_StaMode_Disconnected_t;

typedef struct {
	uint8 old_mode;
	uint8 new_mode;
} Event_StaMode_AuthMode_Change_t;

typedef struct {
	struct ip_addr ip;
	struct ip_addr mask;
	struct ip_addr gw;
} Event_StaMode_Got_IP_t;

typedef struct {
	uint8 mac[6];
	uint8 aid;
} Event_SoftAPMode_StaConnected_t;

typedef struct {
	uint8 mac[6];
	uint8 aid;
} Event_SoftAPMode_StaDisconnected_t;

typedef struct {
	int rssi;
	uint8 mac[6];
} Event_SoftAPMode_ProbeReqRecved_t;

typedef union {
	Event_StaMode_Connected_t			connected;
	Event_StaMode_Disconnected_t		disconnected;
	Event_StaMode_AuthMode_Change_t		auth_change;
	Event_StaMode_Got_IP_t				got_ip;
	Event_SoftAPMode_StaConnected_t		sta_connected;
	Event_SoftAPMode_StaDisconnected_t	sta_disconnected;
	Event_SoftAPMode_ProbeReqRecved_t   ap_probereqrecved;
} Event_Info_u;

typedef struct _esp_event {
    uint32 event;
    Event_Info_u event_info;
} System_Event_t;

typedef void (* wifi_event_handler_cb_t)(System_Event_t *event);

struct ip_info {
    struct ip_addr ip;
    struct ip_addr netmask;
    struct ip_addr gw;
};
#endif
