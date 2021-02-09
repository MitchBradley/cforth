// Interfaces between ESP8266/FreeRTOS and Forth

typedef int cell;

typedef unsigned char u8_t;

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INCLUDE_vTaskDelay 1
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_log.h"
#include "esp_event.h"
#include "esp_event_loop.h"
#include "nvs_flash.h"

#include "lwip/err.h"
#include "lwip/sys.h"
#include "lwip/netdb.h"

#include "driver/uart.h"
#include "driver/pwm.h"

extern void forth(void);

// This is the routine that is run by main_task() from cpu_start.c,
// i.e. the "call in" from FreeRTOS to Forth.
void app_main(void)
{
    nvs_flash_init();
    forth();
}

// The following routines are used by Forth to invoke functions
// defined by the SDK.  The call signatures should be based on
// simple data types, typically "int" which is the same as Forth's
// "cell" on this processor.  Doing so eliminates include dependencies
// between Forth and the SDK, i.e. we don't need to include forth.h
// herein, and we don't need to include lots of SDK .h files in the
// Forth tree.

// init_uart() sets up UART0 for the Forth console, so key and emit
// can use uart_read_bytes() and uart_write_bytes().  The reason we do
// that instead of just calling getchar() and putchar() is because we
// want a non-blocking key?, and there is no easy way to do so with
// getchar().

#define BUF_SIZE (1024)
void init_uart(void)
{
    int uart_num = UART_NUM_0;

    uart_config_t uart_config = {
       .baud_rate = 115200,
       .data_bits = UART_DATA_8_BITS,
       .parity = UART_PARITY_DISABLE,
       .stop_bits = UART_STOP_BITS_1,
       .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
       .rx_flow_ctrl_thresh = 122,
    };
    uart_param_config(uart_num, &uart_config);

    // No need to set the pins as the defaults are correct for UART0

    // Install driver with a receive buffer but no transmit buffer
    // and no event queue.
    uart_driver_install(uart_num, BUF_SIZE * 2, 0, 0, NULL, 0);
}

// Routines for the ccalls[] table in textend.c.  Add new ones
// as necessary.

void ms(int msecs)
{
    vTaskDelay(msecs/ portTICK_PERIOD_MS);
}

#include "driver/i2c.h"

#define I2C_NUM I2C_NUM_0
#define ACK_CHECK 1
#define ACK_VAL 0
#define NACK_VAL 1

// void i2c_setup(cell sda, cell scl)
cell i2c_open(uint8_t sda, uint8_t scl)
{
    int i2c_master_port = I2C_NUM;
    i2c_config_t conf;
    conf.mode = I2C_MODE_MASTER;
    conf.sda_io_num = sda;
    conf.sda_pullup_en = GPIO_PULLUP_ENABLE;
    conf.scl_io_num = scl;
    conf.scl_pullup_en = GPIO_PULLUP_ENABLE;
    conf.clk_stretch_tick = 300; // 300 ticks, Clock stretch is about 210us, you can make changes according to the actual situation.

    esp_err_t err = i2c_driver_install(i2c_master_port, conf.mode);
    if (err) {
        return err;
    }
    return i2c_param_config(i2c_master_port, &conf);
}
void i2c_close()
{
    i2c_driver_delete(1);
}

#define I2C_FINISH \
    i2c_master_stop(cmd); \
    esp_err_t ret = i2c_master_cmd_begin(I2C_NUM, cmd, 1000 / portTICK_RATE_MS); \
    i2c_cmd_link_delete(cmd);

int i2c_write_read(uint8_t stop, uint8_t slave, uint8_t rsize, uint8_t *rbuf, uint8_t wsize, uint8_t *wbuf)
{
    if (rsize == 0 && wsize == 0) {
        return ESP_OK;
    }

    i2c_cmd_handle_t cmd;
    cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    if (wsize) {
	i2c_master_write_byte(cmd, ( slave << 1 ) | I2C_MASTER_WRITE, ACK_CHECK);
	i2c_master_write(cmd, wbuf, wsize, ACK_CHECK);
	if (!rsize) {
    i2c_master_stop(cmd); \
    esp_err_t ret = i2c_master_cmd_begin(I2C_NUM, cmd, 1000 / portTICK_RATE_MS); \
    i2c_cmd_link_delete(cmd);
//	    I2C_FINISH;
	    return ret;
	}
	if (stop) { // rsize is nonzero
    i2c_master_stop(cmd); \
    esp_err_t ret = i2c_master_cmd_begin(I2C_NUM, cmd, 1000 / portTICK_RATE_MS); \
    i2c_cmd_link_delete(cmd);
//	    I2C_FINISH;
	    if (ret)
		return -1;
	    cmd = i2c_cmd_link_create();
	    i2c_master_start(cmd);
	} else {
	    i2c_master_start(cmd);
	}
	i2c_master_write_byte(cmd, ( slave << 1 ) | I2C_MASTER_READ, ACK_CHECK);
    } else {
	// rsize must be nonzero because of the initial check at the top
	i2c_master_write_byte(cmd, ( slave << 1 ) | I2C_MASTER_READ, ACK_CHECK);
    }

    if (rsize > 1) {
        i2c_master_read(cmd, rbuf, rsize - 1, ACK_VAL);
    }
    i2c_master_read_byte(cmd, rbuf + rsize - 1, NACK_VAL);

    I2C_FINISH;
    return ret;
}

cell i2c_rb(int stop, int slave, int reg)
{
    uint8_t rval[1];
    uint8_t regb[1] = { reg };
    if (i2c_write_read(stop, slave, 1, rval, 1, regb))
	return -1;
    return rval[0];
}

cell i2c_be_rw(cell stop, cell slave, cell reg)
{
    uint8_t rval[2];
    uint8_t regb[1] = { reg };
    if (i2c_write_read(stop, slave, 2, rval, 1, regb))
	return -1;
    return (rval[0]<<8) + rval[1];
}

cell i2c_le_rw(cell stop, cell slave, cell reg)
{
    uint8_t rval[2];
    uint8_t regb[1] = { reg };
    if (i2c_write_read(stop, slave, 2, rval, 1, regb))
	return -1;
    return (rval[1]<<8) + rval[0];
}

cell i2c_wb(cell slave, cell reg, cell value)
{
    uint8_t buf[2] = {reg, value};
    return i2c_write_read(0, slave, 0, 0, 2, buf);
}

cell i2c_be_ww(cell slave, cell reg, cell value)
{
    uint8_t buf[3] = {reg, value >> 8, value & 0xff};
    return i2c_write_read(0, slave, 0, 0, 3, buf);
}

cell i2c_le_ww(cell slave, cell reg, cell value)
{
    uint8_t buf[3] = {reg, value & 0xff, value >> 8};
    return i2c_write_read(0, slave, 0, 0, 3, buf);
}

#include "driver/gpio.h"
cell gpio_pin_fetch(cell gpio_num)
{
    return gpio_get_level(gpio_num) ? -1 : 0;
}

void gpio_pin_store(cell gpio_num, cell level)
{
    gpio_set_level(gpio_num, level);
}

void gpio_toggle(cell gpio_num)
{
    int level = gpio_get_level(gpio_num);
    gpio_set_level(gpio_num, !level);
}

static void gpio_setup(uint32_t gpio_num, gpio_mode_t mode, bool pu, bool pd)
{
    gpio_config_t io_conf;
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = mode;
    io_conf.pin_bit_mask = 1 << gpio_num;
    io_conf.pull_down_en = pd;
    io_conf.pull_up_en = pd;
    gpio_config(&io_conf);
}
void gpio_is_output(cell gpio_num)
{
    gpio_setup(gpio_num, GPIO_MODE_OUTPUT, 0, 0);
}

void gpio_is_output_od(cell gpio_num)
{
    gpio_setup(gpio_num, GPIO_MODE_OUTPUT_OD, 0, 0);
}

void gpio_is_input(cell gpio_num)
{
    gpio_setup(gpio_num, GPIO_MODE_INPUT, 0, 0);
}

void gpio_is_input_pu(cell gpio_num)
{
    gpio_setup(gpio_num, GPIO_MODE_INPUT, 1, 0);
}

void gpio_is_input_pd(cell gpio_num)
{
    gpio_setup(gpio_num, GPIO_MODE_INPUT, 0, 1);
}

// For compatibility with ancient ESP8266 interface
// 1 constant gpio-input
// 2 constant gpio-output
// 6 constant gpio-opendrain
void gpio_mode(cell gpio_num, cell mode, cell pullup)
{
    gpio_setup(gpio_num, mode, pullup, 0);
}

/* FreeRTOS event group to signal when we are connected & ready to make a request */
static EventGroupHandle_t wifi_event_group;

/* The event group allows multiple bits for each event,
   but we only care about one event - are we connected
   to the AP with an IP? */
const int CONNECTED_BIT = BIT0;

/* The event group allows multiple bits for each event, but we only care about two events:
 * - we are connected to the AP with an IP
 * - we failed to connect after the maximum amount of retries */
#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1

static int retry_num = -1;  // -1 retries forever, otherwise retry if nonzero and decrement
static void wifi_sta_event_handler(void* arg, esp_event_base_t event_base,
                                int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT) {
        switch (event_id) {
            case WIFI_EVENT_STA_START:
                esp_wifi_connect();
                break;
            case WIFI_EVENT_STA_DISCONNECTED:
                if (retry_num < 0) {
                    esp_wifi_connect();
                    break;
                }
                if (retry_num) {
                    esp_wifi_connect();
                    --retry_num;
                    break;
                }
                xEventGroupSetBits(wifi_event_group, WIFI_FAIL_BIT);
                break;
        }
    } else if (event_base == IP_EVENT) {
        if (event_id == IP_EVENT_STA_GOT_IP) {
            // ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
            // char *ipaddr = ip4addr_ntoa(&event->ip_info.ip));
            xEventGroupSetBits(wifi_event_group, CONNECTED_BIT);
        }
    }
}

cell wifi_open_station(char *password, char *ssid, cell storage, cell timeout, cell retries)
{
    retry_num = retries;

    wifi_event_group = xEventGroupCreate();

    tcpip_adapter_init();

    esp_err_t err = esp_event_loop_create_default();
    if (err != ESP_OK && err != ESP_ERR_INVALID_STATE) {
        return -2;
    }

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    if (esp_wifi_init(&cfg) ) {
        return -3;
    }
    if (esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_sta_event_handler, NULL)) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return -5;
    }
    if (esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_sta_event_handler, NULL)) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return -6;
    }
    if (esp_wifi_set_storage(storage)) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return -4;
    }

    wifi_config_t wifi_config = {};
    strncpy((char *)wifi_config.sta.ssid, ssid, sizeof(wifi_config.sta.ssid));
    strncpy((char *)wifi_config.sta.password, password, sizeof(wifi_config.sta.password));

    if (strlen(password)) {
        wifi_config.sta.threshold.authmode = WIFI_AUTH_WEP;
        esp_wifi_set_protocol(ESP_IF_WIFI_STA, WIFI_PROTOCOL_11B | WIFI_PROTOCOL_11G | WIFI_PROTOCOL_11N);
    }
    if (esp_wifi_set_mode(WIFI_MODE_STA)) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return -7;
    }
    if (esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config)) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return -8;
    }
    if (esp_wifi_start()) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return -9;
    }

    // Wait until either the connection is established (WIFI_CONNECTED_BIT)
    // or the connection failed for the maximum number of re-tries (WIFI_FAIL_BIT).
    // The bits are set by the event handler)
    EventBits_t bits = xEventGroupWaitBits(wifi_event_group,
                                           WIFI_CONNECTED_BIT | WIFI_FAIL_BIT,
                                           pdFALSE,
                                           pdFALSE,
                                           timeout);

    esp_event_handler_unregister(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_sta_event_handler);
    esp_event_handler_unregister(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_sta_event_handler);
    vEventGroupDelete(wifi_event_group);

    if (!(bits & WIFI_CONNECTED_BIT)) {
        esp_wifi_stop();
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return (bits & WIFI_FAIL_BIT) ? -10 : -11;
    }
    return 0;
}
cell wifi_open_station_compat(char *password, char *ssid, cell timeout)
{
    return wifi_open_station(password, ssid, WIFI_STORAGE_RAM, timeout, -1);
}
cell wifi_open_ap(char *password, char *ssid, cell storage, cell max_connections)
{
    int pwlen = strlen(password);
    if (pwlen && pwlen < 8) {
        return -5;
    }

    tcpip_adapter_init();

    esp_err_t err = esp_event_loop_create_default();
    if (err != ESP_OK && err != ESP_ERR_INVALID_STATE) {
        return -2;
    }

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    if (esp_wifi_init(&cfg) ) {
        esp_event_loop_delete_default();
        return -3;
    }
    if (esp_wifi_set_storage(storage)) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return -4;
    }

    wifi_config_t wifi_config = {};
    strncpy((char *)wifi_config.ap.ssid, ssid, sizeof(wifi_config.ap.ssid));
    // wifi_config.ap.ssid_len = 0;  // String is null-terminated

    strncpy((char *)wifi_config.ap.password, password, sizeof(wifi_config.ap.password));

    // wifi_config.ap.channel = 1;
    wifi_config.ap.authmode = strlen(password) ? WIFI_AUTH_WPA_WPA2_PSK : WIFI_AUTH_OPEN;
    wifi_config.ap.max_connection = max_connections;
    wifi_config.ap.beacon_interval = 100;

    if (esp_wifi_set_mode(WIFI_MODE_AP)) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return -7;
    }
    err = esp_wifi_set_config(ESP_IF_WIFI_AP, &wifi_config);
    if (err) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return err;
    }
    if (esp_wifi_start()) {
        esp_wifi_deinit();
        esp_event_loop_delete_default();
        return -9;
    }

    return 0;
}

cell wifi_off(void)
{
    esp_err_t err;
    err = esp_wifi_stop();
    if (err) {
        return err;
    }
    err = esp_wifi_deinit();
    if (err) {
        return err;
    }
    err = esp_event_loop_delete_default();
    if (err) {
        return err;
    }
    return 0;
}

cell get_wifi_mode(void)
{
    wifi_mode_t mode;
    esp_wifi_get_mode(&mode);
    return mode;
}

void set_log_level(char *component, int level)
{
    esp_log_level_set(component, level);
}

int client_socket(char *host, char *portstr, cell protocol)
{
    char *endptr;
    uint16_t port = strtol(portstr, &endptr, 10);
    if (endptr != (portstr + strlen(portstr))) {
        return -8;
    }

    struct hostent * hostent = gethostbyname(host);
    if (hostent == NULL) {
        return -7;
    }
    struct in_addr **addr_list = (struct in_addr **)hostent->h_addr_list;
    if (addr_list[0] == NULL) {
        return -6;
    }

    struct sockaddr_in destAddr = {};
    destAddr.sin_family = AF_INET;
    destAddr.sin_port = htons(port);
    memcpy(&destAddr.sin_addr, addr_list[0], sizeof(destAddr.sin_addr));

    int s = socket(AF_INET, protocol, IPPROTO_IP);
    if (s < 0) {
        return -5;
    }
    if (connect(s, (struct sockaddr *)&destAddr, sizeof(destAddr)) < 0) {
        close(s);
        return -4;
    }
    return s;
}

cell udp_client(char *host, char *portstr)
{
    return client_socket(host, portstr, SOCK_DGRAM);
}

int stream_connect(char *host, char *portstr, int timeout_msecs)
{

    int s = client_socket(host, portstr, SOCK_STREAM);
    if (s < 0) {
        return s;
    }

    struct timeval recv_timeout;
    recv_timeout.tv_sec = timeout_msecs / 1000;
    recv_timeout.tv_usec = (timeout_msecs % 1000) * 1000;

    int error = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &recv_timeout, sizeof(recv_timeout));
    if (error) {
        perror("unable to set receive timeout.");
        return -3;
    }
    return s;
}

cell bound_socket(cell port, cell protocol)
{
    struct sockaddr_in addr;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    addr.sin_addr.s_addr = 0;

    int listenfd = socket(AF_INET, protocol, IPPROTO_IP);
    if (listenfd < 0) {
        return -2;
    }

    int err = bind(listenfd, (struct sockaddr *)&addr, sizeof(addr));
    if (err != 0) {
        return -3;
    }
    return listenfd;
}

cell start_server(cell port)
{
    int listenfd = bound_socket(port, SOCK_STREAM);
    if (listenfd < 0) {
        return listenfd;
    }

    // listen for incoming connections
    if (listen(listenfd, 1000000) != 0) {
	close(listenfd);
	return -3;
    }
    return listenfd;
}

cell start_udp_server(cell port)
{
    return bound_socket(port, SOCK_DGRAM);
}

cell my_select(cell maxfdp1, void *reads, void *writes, void *excepts, cell msecs)
{
    struct timeval to = { .tv_sec = msecs/1000, .tv_usec = (msecs%1000)*1000 };
    return (cell)lwip_select((int)maxfdp1, (fd_set *)reads, (fd_set *)writes, (fd_set *)excepts, &to);
}

cell dhcpc_status(void)
{
    tcpip_adapter_dhcp_status_t status;
    tcpip_adapter_dhcpc_get_status(TCPIP_ADAPTER_IF_STA, &status);
    return status;
}

void ip_info(void *buf)
{
    tcpip_adapter_get_ip_info(TCPIP_ADAPTER_IF_STA, (tcpip_adapter_ip_info_t *)buf);
}

cell my_lwip_write(cell handle, cell len, void *adr)
{
    return (cell)lwip_write((int)handle, adr, (size_t)len);
}

cell my_lwip_read(cell handle, cell len, void *adr)
{
    return (cell)lwip_read((int)handle, adr, (size_t)len);
}

#include <errno.h>
#include <sys/fcntl.h>
#include "esp_vfs.h"
#include "esp_spiffs.h"

void init_filesystem(void)
{
    esp_log_level_set("[SPIFFS]", 0);
    esp_vfs_spiffs_conf_t conf = {
        .base_path = "/spiffs",
        .partition_label = NULL,
        .max_files = 3,
        .format_if_mount_failed = 1,
    };
    esp_vfs_spiffs_register(&conf);
}

char *expand_path(char *name)
{
    static char path[256];
    strcpy(path, "/spiffs/");
    strncat(path, name, 256 - strlen("/spiffs/"));
    return path;
}

void *open_dir(void)
{
    return opendir(expand_path(""));
}

void *next_file(void *dir)
{
    struct dirent *ent;

    while ((ent = readdir((DIR *)dir)) != NULL) {
	if (ent->d_type == DT_REG) {
	    return ent;
	}
    }
    return NULL;
}

char *dirent_name(void *ent)
{
    return ((struct dirent *)ent)->d_name;
}

cell dirent_size(void *ent)
{
    struct stat statbuf;
    if (stat(expand_path(((struct dirent *)ent)->d_name), &statbuf)) {
	return -1;
    }
    return statbuf.st_size;
}

void rename_file(char *new, char *old)
{
    static char path[256];
    strcpy(path, "/spiffs/");
    strncat(path, new, 256 - strlen("/spiffs/"));

    rename(expand_path(old), path);
}

cell fs_avail(void)
{
  u32_t total, used;
  esp_spiffs_info("/spiffs", &total, &used);
  return (cell)(total - used);
}

void delete_file(char *name)
{
    remove(expand_path(name));
}

void restart(void)
{
    esp_restart();
}

void pwm_set_frequency(cell frequency)
{
    pwm_set_period(1000000/frequency);
}

cell pwm_duty_fetch(cell channel)
{
    uint32_t duty;
    return pwm_get_duty(channel, &duty) != ESP_OK ? -1 : duty;
}

cell pwm_frequency_fetch()
{
    uint32_t period;
    err_t err = pwm_get_period(&period);
    return  err != ESP_OK ? 0 : (period ? 1000000/period : 0);
}

cell pwm_period_fetch()
{
    uint32_t period;
    return pwm_get_period(&period) != ESP_OK ? -1 : period;
}

void pwm_stop0(void)
{
    pwm_stop(0);
}
void pwm_phase_store(cell channel, cell phase)
{
    pwm_set_phase(channel, (float)phase);
}

#include "esp_timer.h"

static esp_timer_handle_t alarm_timer;

extern void alarm_callback(void* arg);

static void create_timer() {
    if (alarm_timer) {
        return;
    }
    const esp_timer_create_args_t alarm_timer_args = {
            .callback = &alarm_callback,
    };
    esp_timer_create(&alarm_timer_args, &alarm_timer);
}

typedef cell xt_t;
extern xt_t alarm_xt;

void alarm_us_64(uint64_t us, xt_t xt)
{
    create_timer();
    alarm_xt = xt;
    if (xt && us) {
        esp_timer_start_once(alarm_timer, us);
    } else {
        esp_timer_stop(alarm_timer);
    }
}
void alarm_us(uint32_t us, xt_t xt)
{
    alarm_us_64((uint64_t)us, xt);
}
void alarm_ms(uint32_t ms, xt_t xt)
{
    alarm_us((uint64_t)ms * 1000, xt);
}

void repeat_alarm_us_64(uint64_t us, xt_t xt)
{
    create_timer();
    alarm_xt = xt;
    if (xt && us) {
        esp_timer_start_periodic(alarm_timer, us);
    } else {
        esp_timer_stop(alarm_timer);
    }
}
void repeat_alarm_us(uint32_t us, xt_t xt)
{
    repeat_alarm_us_64((uint64_t)us, xt);
}
void repeat_alarm(uint32_t ms, xt_t xt)
{
    repeat_alarm_us((uint64_t)ms * 1000, xt);
}

#include <rom/ets_sys.h>
void us(cell us)
{
    ets_delay_us(us);
}

#include "driver/adc.h"
cell adc_init_args(cell mode, cell divisor)
{
    adc_config_t config = {mode, divisor};
    return adc_init(&config);
}

cell adc_fetch(void)
{
    uint16_t data;
    return adc_read(&data) != ESP_OK ? -1 : data;
}
