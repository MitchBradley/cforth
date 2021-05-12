// Interfaces between ESP32/FreeRTOS and Forth

typedef int cell;

#include <string.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_event_loop.h"
#include "esp_log.h"
#include "esp_event.h"
#include "nvs_flash.h"

#include "lwip/err.h"
#include "lwip/sys.h"
#include "lwip/netdb.h"

#include "driver/uart.h"

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

#define I2C_NUM 1
#define ACK_CHECK 1
#define ACK_VAL 0
#define NACK_VAL 1

// void i2c_setup(cell sda, cell scl)
cell i2c_open(uint8_t sda, uint8_t scl)
{
    int i2c_master_port = 1;
    i2c_config_t conf;
    conf.mode = I2C_MODE_MASTER;
    conf.sda_io_num = sda;
    conf.sda_pullup_en = GPIO_PULLUP_ENABLE;
    conf.scl_io_num = scl;
    conf.scl_pullup_en = GPIO_PULLUP_ENABLE;
    conf.master.clk_speed = 100000;
    i2c_param_config(i2c_master_port, &conf);
    return i2c_driver_install(i2c_master_port, conf.mode,
                       0, 0, 0  // No Rx buf, No Tx buf, no intr flags
                       );
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

void gpio_is_output(cell gpio_num)
{
    gpio_set_direction(gpio_num, GPIO_MODE_OUTPUT);
}

void gpio_is_output_od(cell gpio_num)
{
    gpio_set_direction(gpio_num, GPIO_MODE_OUTPUT_OD);
}

void gpio_is_input(cell gpio_num)
{
    gpio_set_pull_mode(gpio_num, GPIO_FLOATING);
    gpio_set_direction(gpio_num, GPIO_MODE_INPUT);
}

void gpio_is_input_pu(cell gpio_num)
{
    gpio_set_pull_mode(gpio_num, GPIO_PULLUP_ONLY);
    gpio_set_direction(gpio_num, GPIO_MODE_INPUT);
}

void gpio_is_input_pd(cell gpio_num)
{
    gpio_set_pull_mode(gpio_num, GPIO_PULLDOWN_ONLY);
    gpio_set_direction(gpio_num, GPIO_MODE_INPUT);
}

// For compatibility with ESP8266 interface
// 1 constant gpio-input
// 2 constant gpio-output
// 6 constant gpio-opendrain
void gpio_mode(cell gpio_num, cell direction, cell pull)
{
    gpio_set_direction(gpio_num, direction);
    if (pull) {
        gpio_pullup_en(gpio_num);
    } else {
        gpio_pullup_dis(gpio_num);
    }
}

/* FreeRTOS event group to signal when we are connected & ready to make a request */
static EventGroupHandle_t wifi_event_group;

/* The event group allows multiple bits for each event,
   but we only care about one event - are we connected
   to the AP with an IP? */
const int CONNECTED_BIT = BIT0;

static esp_err_t wifi_event_handler(void *ctx, system_event_t *event)
{
    switch(event->event_id) {
    case SYSTEM_EVENT_STA_START:
        esp_wifi_connect();
        break;
    case SYSTEM_EVENT_STA_GOT_IP:
        xEventGroupSetBits(wifi_event_group, CONNECTED_BIT);
        break;
    case SYSTEM_EVENT_STA_DISCONNECTED:
        /* This is a workaround as ESP32 WiFi libs don't currently
           auto-reassociate. */
        esp_wifi_connect();
        xEventGroupClearBits(wifi_event_group, CONNECTED_BIT);
        break;
    default:
        break;
    }
    return ESP_OK;
}

cell wifi_open(cell timeout, char *password, char *ssid)
{
    tcpip_adapter_init();
    wifi_event_group = xEventGroupCreate();
    if (esp_event_loop_init(wifi_event_handler, NULL)) return -1;
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    if (esp_wifi_init(&cfg) ) return -2;
    if (esp_wifi_set_storage(WIFI_STORAGE_RAM)) return -3;
    wifi_config_t wifi_config = { };
    strncpy((char *)wifi_config.sta.ssid, ssid, sizeof(wifi_config.sta.ssid));
    strncpy((char *)wifi_config.sta.password, password, sizeof(wifi_config.sta.password));
    if(esp_wifi_set_mode(WIFI_MODE_STA)) return -4;
    if(esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config)) return -5;
    if(esp_wifi_start()) return -6;
    if (xEventGroupWaitBits(wifi_event_group, CONNECTED_BIT, false, true, timeout) != CONNECTED_BIT) return -7;
    return 0;
}

void set_log_level(char *component, int level)
{
    esp_log_level_set(component, level);
}

int stream_connect(char *host, char *portstr, int timeout_msecs)
{
    struct addrinfo hints, *res, *res0;
    int error;
    int s;
    const char *cause = NULL;

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    error = getaddrinfo(host, portstr, &hints, &res0);
    if (error) {
        perror("getaddrinfo");
        return -1;
    }
    s = -1;
    for (res = res0; res; res = res->ai_next) {
        s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (s < 0) {
            cause = "socket";
            continue;
        }

        if (connect(s, res->ai_addr, res->ai_addrlen) < 0) {
            cause = "connect";
            close(s);
            s = -1;
            continue;
        }
        break;  /* okay we got one */
    }
    freeaddrinfo(res0);
    if (s < 0) {
        printf("%s", cause);
        return -2;
    }

    struct timeval recv_timeout;
    recv_timeout.tv_sec = timeout_msecs / 1000;
    recv_timeout.tv_usec = (timeout_msecs % 1000) * 1000;

    error = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &recv_timeout, sizeof(recv_timeout));
    if (error) {
        perror("unable to set receive timeout.");
        return -3;
    }
    return s;
}

cell start_server(cell port)
{
    struct addrinfo hints, *res, *p;
    char portstr[10];
    snprintf(portstr, 10, "%d", port);
    int listenfd = -1;

    // getaddrinfo for host
    memset (&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    if (getaddrinfo( NULL, portstr, &hints, &res) != 0)
	return -1;
    // socket and bind
    for (p = res; p!=NULL; p=p->ai_next)
    {
        listenfd = socket (p->ai_family, p->ai_socktype, 0);
        if (listenfd == -1) continue;

        if (bind(listenfd, p->ai_addr, p->ai_addrlen) == 0) break;
    }
    if (p==NULL)
	return -2;

    freeaddrinfo(res);

    // listen for incoming connections
    if ( listen (listenfd, 1000000) != 0 ) {
	close(listenfd);
	return -3;
    }
    return listenfd;
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
    return (cell)lwip_write_r((int)handle, adr, (size_t)len);
}

cell my_lwip_read(cell handle, cell len, void *adr)
{
    return (cell)lwip_read_r((int)handle, adr, (size_t)len);
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

#include <rom/ets_sys.h>
void us(cell us)
{
    ets_delay_us(us);
}
