// Interfaces between ESP32/FreeRTOS and Forth - UPDATED FOR IDF 5.5.1

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include "lwip/sockets.h"
#include "esp_netif.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_log.h"
#include "esp_event.h"
#include "nvs_flash.h"
#include "esp_littlefs.h"
#include "lwip/err.h"
#include "lwip/sys.h"
#include "lwip/netdb.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include "driver/uart.h"
#include <sys/fcntl.h>
#include "esp_vfs.h"
#include "esp_vfs_fat.h"
#include "driver/spi_master.h"
#include "driver/spi_slave.h"
#include "wear_levelling.h"
#include "esp_timer.h"
#include "esp_adc/adc_oneshot.h"
#include "esp_adc/adc_cali.h"
#include "esp_adc/adc_cali_scheme.h"
#include "esp_sleep.h"
#include "driver/rtc_io.h"
#include "driver/gpio.h"
#include "driver/i2c_master.h"
#include "esp_now.h"
#include "sdmmc_cmd.h"
#include "esp_rom_sys.h"
#include "freertos/semphr.h"
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>

typedef int cell;

extern void forth(void);

#ifdef CONFIG_IDF_TARGET_ESP32C3
#define ESP32_C3 1
#elif defined(CONFIG_IDF_TARGET_ESP32)
#define ESP32 1
#endif


// This is the routine that is run by main_task() from cpu_start.c,
// i.e. the "call in" from FreeRTOS to Forth.

void app_main(void) {
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);
    forth();
}

/*
 * Interface functions between ESP32/FreeRTOS and Forth.
 * 
 * This file uses a MIXED approach for parameter types:
 * 
 * 1. NATIVE ESP-IDF TYPES (e.g., adc_unit_t, gpio_num_t, i2c_master_dev_handle_t) to avoid
 *    unnecessary casting for ESP-IDF API calls
 *    - Used where the ESP-IDF API expects specific types
 *    - Eliminates casting inside C functions
 *    - Provides compile-time type checking
 *    Benefit: No casts, type safety
 * 
 * 2. Optional 'cell' TYPE (typedef int cell) for generic parameters that don't have a specific ESP-IDF type
 *    - Used for generic integer values (counts, flags, timeouts, error codes)
 *    - Used for pointers/handles that are cast to/from ESP-IDF types
 *    - Maintains compatibility with Forth's stack cell size
 *    - Used where the exact ESP-IDF type is not critical (e.g., boolean flags, sizes)
 *
 * init_uart() sets up UART0 for the Forth console, so key and emit
 * can use uart_read_bytes() and uart_write_bytes().  The reason we do
 * that instead of just calling getchar() and putchar() is because we
 * want a non-blocking key?, and there is no easy way to do so with  getchar().
 */

#define BUF_SIZE (1024)
void init_uart(void) {
    int uart_num = UART_NUM_0;
    uart_config_t uart_config = {
       .baud_rate = 115200,
       .data_bits = UART_DATA_8_BITS,
       .parity = UART_PARITY_DISABLE,
       .stop_bits = UART_STOP_BITS_1,
       .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
       .rx_flow_ctrl_thresh = 122,
       .source_clk = UART_SCLK_APB,
    };
    uart_param_config(uart_num, &uart_config);
    // No need to set the pins as the defaults are correct for UART0

    // Install driver with a receive buffer but no transmit buffer
    // and no event queue.
    uart_driver_install(uart_num, BUF_SIZE * 2, 0, 0, NULL, 0);
}

cell my_uart_param_config(int uart_num, int baud, int bits, int par, int stop, int flow) {
    uart_config_t uart_config = {
       .baud_rate = baud,
       .data_bits = bits-5,
       .parity = par,
       .stop_bits = stop,
       .flow_ctrl = flow,
       .rx_flow_ctrl_thresh = 122,
       .source_clk = UART_SCLK_APB,
    };
   return uart_param_config(uart_num, &uart_config);
}

int *errno_val(void) {
    return &errno;
}

cell get_tick_rate_hz(void) {
    return (cell)configTICK_RATE_HZ;
}

cell my_adc_oneshot_new_unit(adc_unit_t unit_id, adc_oneshot_clk_src_t clk_src) {
    adc_oneshot_unit_handle_t handle = NULL;
    adc_oneshot_unit_init_cfg_t init_config = {
        .unit_id = unit_id,
        .clk_src = clk_src,
    };
    esp_err_t err = adc_oneshot_new_unit(&init_config, &handle);
    return (err != ESP_OK) ? 0 : (cell)handle;
}

cell my_adc_oneshot_config_channel(adc_oneshot_unit_handle_t handle, adc_channel_t channel, adc_atten_t atten, adc_bitwidth_t bitwidth) {
    adc_oneshot_chan_cfg_t config = {
        .atten = atten,
        .bitwidth = bitwidth,
    };
    return adc_oneshot_config_channel(handle, channel, &config);
}

#ifndef ESP32
cell my_adc_create_calibration_scheme(adc_unit_t unit_id, adc_atten_t atten, adc_bitwidth_t bitwidth) {
    adc_cali_curve_fitting_config_t cfg = {
        .unit_id = unit_id,
        .atten = atten,
        .bitwidth = bitwidth,
    };
    adc_cali_handle_t handle;
    esp_err_t ret = adc_cali_create_scheme_curve_fitting(&cfg, &handle);
    return (ret == ESP_OK) ? (cell)handle : 0;
}
cell my_adc_delete_calibration_scheme(adc_cali_handle_t handle) {
    return adc_cali_delete_scheme_curve_fitting(handle);
}
#else
cell my_adc_create_calibration_scheme(adc_unit_t unit, adc_atten_t atten, adc_bitwidth_t bitwidth) {
    adc_cali_line_fitting_config_t config = {
        .unit_id = unit,
        .atten = atten,
        .bitwidth = bitwidth,
        .default_vref = 1100,
    };
    adc_cali_handle_t handle;
    esp_err_t ret = adc_cali_create_scheme_line_fitting(&config, &handle);
    return (ret == ESP_OK) ? (cell)handle : 0;
}
void my_adc_delete_calibration_scheme(adc_cali_handle_t handle) {
    adc_cali_delete_scheme_line_fitting(handle);
}
int spi_bus_init(int sclk, int miso, int mosi, spi_host_device_t host_id, size_t max_transfer_sz) {
    spi_bus_config_t buscfg = {
        .mosi_io_num = mosi,
        .miso_io_num = miso,
        .sclk_io_num = sclk,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = max_transfer_sz,
        .flags = 0,
        .intr_flags = 0,
    };
    return spi_bus_initialize(host_id, &buscfg, SPI_DMA_CH_AUTO);
}
#endif

#ifdef ESP32_C3
esp_err_t my_esp_sleep_enable_ext0_wakeup(int level, gpio_num_t gpio_num) {
    gpio_config_t io_conf = { .pin_bit_mask = (1ULL << gpio_num), .mode = GPIO_MODE_INPUT,
        .pull_up_en = !level, .pull_down_en = level };
    gpio_config(&io_conf);
    gpio_deep_sleep_hold_en();
    return esp_deep_sleep_enable_gpio_wakeup(1ULL << gpio_num,
           level ? ESP_GPIO_WAKEUP_GPIO_HIGH : ESP_GPIO_WAKEUP_GPIO_LOW);
}
#else
esp_err_t my_esp_sleep_enable_ext0_wakeup(int level, gpio_num_t gpio_num) {
    return esp_sleep_enable_ext0_wakeup(gpio_num, level);
}
#endif

int lwip_bind_r(int s, const struct sockaddr *name, socklen_t namelen) {
    return bind(s, name, namelen);
}

int lwip_connect_r(int s, const struct sockaddr *name, socklen_t namelen) {
    return connect(s, name, namelen);
}


int lwip_setsockopt_r(int s, int level, int optname, const void *optval, socklen_t optlen) {
    return lwip_setsockopt(s, level, optname, optval, optlen);
}

int lwip_getsockopt_r(int s, int level, int optname, void *optval, socklen_t *optlen) {
    return lwip_getsockopt(s, level, optname, optval, optlen);
}

int lwip_close_r(int s) {
    shutdown(s, SHUT_RDWR); 
    return close(s);
}

int lwip_listen_r(int s, int backlog) {
    return listen(s, backlog);
}

int lwip_accept_r(int s, struct sockaddr *addr, socklen_t *addrlen) {
    return accept(s, addr, addrlen);
}

typedef struct {
    esp_ip4_addr_t ip;
    esp_ip4_addr_t netmask;
    esp_ip4_addr_t gw;
} tcpip_adapter_ip_info_t;

typedef enum {
    TCPIP_ADAPTER_IF_STA = 0,
    TCPIP_ADAPTER_IF_AP,
    TCPIP_ADAPTER_IF_ETH,
    TCPIP_ADAPTER_IF_MAX
} tcpip_adapter_if_t;

cell tcpip_adapter_get_ip_info(tcpip_adapter_if_t adapter, void *buf) {
    if (!buf) return -1;
    const char *ifkey = NULL;
    switch (adapter) {
        case 0: ifkey = "WIFI_STA_DEF"; break;
        case 1: ifkey = "WIFI_AP_DEF"; break;
        case 2: ifkey = "ETH_DEF"; break;
        default: return -1;
    }
    esp_netif_t *netif = esp_netif_get_handle_from_ifkey(ifkey);
    if (!netif) {
        memset(buf, 0, 12);
        return -1;
    }
    esp_netif_ip_info_t ip_info;
    if (esp_netif_get_ip_info(netif, &ip_info) != ESP_OK) {
        memset(buf, 0, 12);
        return -1;
    }
    uint32_t *buf_u32 = (uint32_t *)buf;
    buf_u32[0] = ip_info.ip.addr;
    buf_u32[1] = ip_info.netmask.addr;
    buf_u32[2] = ip_info.gw.addr;
    return 0;
}

void my_vTaskDelay(int msecs) {
    vTaskDelay(msecs / portTICK_PERIOD_MS);
}

#ifndef ESP32_C3
#include "driver/mcpwm_prelude.h"

int mcpwm_config(void *handles_buffer, int unit, int timer_id,  int freq_hz, int resolution_hz,  int gpio) {
//    fprintf(stderr, "DEBUG mcpwm_config: buf=%p unit=%d timer=%d freq=%d res=%d gpio=%d\n", 
//            handles_buffer, unit, timer_id, freq_hz, resolution_hz, gpio);
    uint32_t period = resolution_hz / freq_hz;
    mcpwm_timer_handle_t timer;
    mcpwm_oper_handle_t oper;
    mcpwm_gen_handle_t gen;
    mcpwm_cmpr_handle_t cmpr;
    mcpwm_timer_config_t timer_config = {
        .group_id = unit,
        .clk_src = MCPWM_TIMER_CLK_SRC_DEFAULT,
        .resolution_hz = resolution_hz,
        .period_ticks = period,
        .count_mode = MCPWM_TIMER_COUNT_MODE_UP,
    };
    esp_err_t ret = mcpwm_new_timer(&timer_config, &timer);
    if (ret != ESP_OK) return ret;
    mcpwm_operator_config_t oper_config = { .group_id = unit };
    ret = mcpwm_new_operator(&oper_config, &oper);
    if (ret != ESP_OK) {
        mcpwm_del_timer(timer);
        return ret;
    }
    mcpwm_operator_connect_timer(oper, timer);
    mcpwm_generator_config_t gen_config = { .gen_gpio_num = gpio };
    ret = mcpwm_new_generator(oper, &gen_config, &gen);
    if (ret != ESP_OK) {
        mcpwm_del_operator(oper);
        mcpwm_del_timer(timer);
        return ret;
    }
    mcpwm_comparator_config_t cmpr_config = {
        .flags = { .update_cmp_on_tez = true }
    };
    ret = mcpwm_new_comparator(oper, &cmpr_config, &cmpr);
    if (ret != ESP_OK) {
        mcpwm_del_generator(gen);
        mcpwm_del_operator(oper);
        mcpwm_del_timer(timer);
        return ret;
    }
    // Actions: HIGH at start, LOW at compare
    mcpwm_generator_set_action_on_timer_event(gen,
        MCPWM_GEN_TIMER_EVENT_ACTION(MCPWM_TIMER_DIRECTION_UP, MCPWM_TIMER_EVENT_EMPTY, MCPWM_GEN_ACTION_HIGH));
    mcpwm_generator_set_action_on_compare_event(gen,
        MCPWM_GEN_COMPARE_EVENT_ACTION(MCPWM_TIMER_DIRECTION_UP, cmpr, MCPWM_GEN_ACTION_LOW));
    mcpwm_comparator_set_compare_value(cmpr, 0);
    mcpwm_timer_enable(timer);
    // Write handles to buffer
    uint32_t *dest = (uint32_t *)handles_buffer;
    dest[0] = (uint32_t)timer;
    dest[1] = (uint32_t)oper;
    dest[2] = (uint32_t)gen;
    dest[3] = (uint32_t)cmpr;
    dest[4] = period;
    return 0;
}

int mcpwm_set_comparator(mcpwm_cmpr_handle_t cmpr, int compare_ticks) {
    return mcpwm_comparator_set_compare_value(cmpr, compare_ticks);
}
int mcpwm_timer_control(mcpwm_timer_handle_t timer, int start) {
    mcpwm_timer_start_stop_cmd_t cmd = start ? MCPWM_TIMER_START_NO_STOP : MCPWM_TIMER_STOP_EMPTY;
    return mcpwm_timer_start_stop(timer, cmd);
}

#else
#define NO_PWM { printf(" No hardware for mcpwm\n"); return -1; }
cell mcpwm_config(int unit, int timer_id, uint32_t freq, int gpio, int chan) NO_PWM
cell mcpwm_set_comparator(uint32_t duty_us, int chan) NO_PWM
cell mcpwm_timer_control(int chan) NO_PWM
#endif

cell i2c_bus_init(uint8_t glitch, gpio_num_t sda, gpio_num_t scl, uint32_t pullup) {
//    ESP_LOGI("I2C", "i2c_bus_init: glitch=%d, scl=%d, sda=%d, pullup=%d", glitch, scl, sda, pullup);
    i2c_master_bus_config_t bus_cfg = {
        .i2c_port = 0,
        .sda_io_num = sda,
        .scl_io_num = scl,
        .clk_source = I2C_CLK_SRC_DEFAULT,
        .glitch_ignore_cnt = glitch,
        .flags.enable_internal_pullup = pullup,
    };
    i2c_master_bus_handle_t bus_handle;
    esp_err_t err = i2c_new_master_bus(&bus_cfg, &bus_handle);
//    ESP_LOGI("I2C", "i2c_new_master_bus: err=%d, bus_handle=%p", err, bus_handle);
    return (err == ESP_OK) ? (cell)bus_handle : 0;
}

cell i2c_device_add(int tenbit, uint32_t speed, uint16_t addr, uint32_t wait, i2c_master_bus_handle_t bus_handle) {
//    ESP_LOGI("I2C", "i2c_device_add: 10bit=%d, speed=%lu, I2C_addr=0x%04x, wait=%lu, bus_handle=%p", 
//             tenbit, (unsigned long)speed, addr, (unsigned long)wait, (void*)bus_handle);
    i2c_device_config_t dev_cfg = {
        .dev_addr_length = (tenbit) ? I2C_ADDR_BIT_LEN_10 : I2C_ADDR_BIT_LEN_7,
        .device_address = addr,
        .scl_speed_hz = speed,
        .scl_wait_us = wait,
        .flags.disable_ack_check = 0,
    };
    i2c_master_dev_handle_t dev_handle;
    esp_err_t err = i2c_master_bus_add_device(bus_handle, &dev_cfg, &dev_handle);
    return (err == ESP_OK) ? (cell)dev_handle : 0;
}

cell i2c_master_readbyte(i2c_master_dev_handle_t handle, uint8_t reg) {
    uint8_t data_byte;
    esp_err_t err;
    err = i2c_master_transmit(handle, &reg, 1, 1000 / portTICK_PERIOD_MS);
    if (err != ESP_OK) return (cell)err;
    err = i2c_master_receive(handle, &data_byte, 1, 1000 / portTICK_PERIOD_MS);
    if (err != ESP_OK) return (cell)err;
    return (cell)data_byte;
}

cell i2c_master_readword(i2c_master_dev_handle_t handle, uint8_t reg) {
    uint8_t data_bytes[2];
    esp_err_t err;
    err = i2c_master_transmit(handle, &reg, 1, 1000 / portTICK_PERIOD_MS);
    if (err != ESP_OK) {
        ESP_LOGE("I2C", "READWORD: transmit failed: %d", err);
        ESP_LOGI("I2C", "READWORD: handle=%p, reg=0x%02x", (void*)handle, reg);
        return (cell)err;
    }
    err = i2c_master_receive(handle, data_bytes, 2, 1000 / portTICK_PERIOD_MS);
    if (err != ESP_OK) {
        ESP_LOGE("I2C", "READWORD: receive failed: %d", err);
        return (cell)err;
    }
    uint16_t result = (data_bytes[0] << 8) | data_bytes[1];
//    ESP_LOGI("I2C", "READWORD: bytes[0]=0x%02x, bytes[1]=0x%02x, result=0x%04x", data_bytes[0], data_bytes[1], result);
    return (cell)result;
}

cell i2c_master_writebyte(i2c_master_dev_handle_t handle, uint8_t reg, uint8_t value) {
//    ESP_LOGI("I2C", "i2c_master_writebyte: value=0x%02x, reg=0x%02x, dev_handle=%p", value, reg, (void*)handle);
    uint8_t buffer[2] = {reg, value};
    esp_err_t err = i2c_master_transmit(handle, buffer, 2, 1000 / portTICK_PERIOD_MS);
    if (err != ESP_OK) {
        ESP_LOGE("I2C", "i2c_master_writebyte: reg=0x%02x err=%d", reg, err);
    }
    return (cell)err;
}

cell i2c_master_writeword(i2c_master_dev_handle_t handle, uint8_t reg, uint16_t value) {
//    ESP_LOGI("I2C", "WRITEWORD: handle=%p, reg=0x%02x, value=0x%04x", (void*)handle, reg, value);
    uint8_t buffer[3];
    buffer[0] = reg;
    buffer[1] = (uint8_t)((value >> 8) & 0xFF);
    buffer[2] = (uint8_t)(value & 0xFF);
//    ESP_LOGI("I2C", "WRITEWORD: buffer[0]=0x%02x, [1]=0x%02x (MSB), [2]=0x%02x (LSB)", buffer[0], buffer[1], buffer[2]);
    esp_err_t err = i2c_master_transmit(handle, buffer, 3, 1000 / portTICK_PERIOD_MS);
//    ESP_LOGI("I2C", "WRITEWORD: transmit result: %d", err);
    return (cell)err;
}

cell i2c_write_read(i2c_master_dev_handle_t dev_handle, size_t rsize, uint8_t *rbuf, size_t wsize, uint8_t *wbuf) {
    esp_err_t err = i2c_master_transmit_receive(dev_handle, wbuf, wsize, rbuf, rsize, 1000 / portTICK_PERIOD_MS);
    if (err != ESP_OK) {
        ESP_LOGE("I2C", "i2c_write_read: dev_handle=%p, wbuf=%p[%d], rbuf=%p[%d]", (void*)dev_handle, (void*)wbuf, (int)wsize, (void*)rbuf, (int)rsize);
    }
    return (cell)err;
}

void i2c_device_del(i2c_master_dev_handle_t dev_handle, i2c_master_bus_handle_t bus_handle) {
    if (dev_handle != NULL) {
        i2c_master_bus_rm_device(dev_handle);
    }
}

void i2c_bus_del(i2c_master_bus_handle_t bus_handle) {
    if (bus_handle != NULL) {
        i2c_del_master_bus(bus_handle);
    }
}

void gpio_is_output(gpio_num_t gpio_num) {
    gpio_set_direction(gpio_num, GPIO_MODE_OUTPUT);
}

void gpio_is_output_od(gpio_num_t gpio_num) {
    gpio_set_direction(gpio_num, GPIO_MODE_OUTPUT_OD);
}

void gpio_toggle(gpio_num_t gpio_num) {
    int level = gpio_get_level(gpio_num);
    gpio_set_level(gpio_num, !level);
}

void gpio_is_input(gpio_num_t gpio_num) {
    gpio_set_pull_mode(gpio_num, GPIO_FLOATING);
    gpio_set_direction(gpio_num, GPIO_MODE_INPUT);
}

void gpio_is_input_pu(gpio_num_t gpio_num) {
    gpio_set_pull_mode(gpio_num, GPIO_PULLUP_ONLY);
    gpio_set_direction(gpio_num, GPIO_MODE_INPUT);
}

void gpio_is_input_pd(gpio_num_t gpio_num) {
    gpio_set_pull_mode(gpio_num, GPIO_PULLDOWN_ONLY);
    gpio_set_direction(gpio_num, GPIO_MODE_INPUT);
}

void gpio_mode(gpio_num_t gpio_num, gpio_mode_t direction, int pull) {
    gpio_set_direction(gpio_num, direction);
    if (pull) {
        gpio_pullup_en(gpio_num);
    } else {
        gpio_pullup_dis(gpio_num);
    }
}

cell ssid_available(cell timeout_ms, char *ssid) {
    if (!ssid || timeout_ms < 0) return -1;
    wifi_mode_t mode;
    if (esp_wifi_get_mode(&mode) != ESP_OK || mode != WIFI_MODE_STA) return -1;
    if (timeout_ms > 0) {
        wifi_scan_config_t scan_config = {
            .ssid = (uint8_t*)ssid,
            .show_hidden = 1,
            .scan_type = WIFI_SCAN_TYPE_ACTIVE,
            .scan_time = { .active = { .min = 100, .max = 300 } }
        };
        if (esp_wifi_scan_start(&scan_config, false) != ESP_OK) return -1;
        int elapsed = 0;
        while (elapsed < timeout_ms) {
            uint16_t ap_count = 0;
            if (esp_wifi_scan_get_ap_num(&ap_count) == ESP_OK && ap_count > 0) break;
            vTaskDelay(pdMS_TO_TICKS(50));
            elapsed += 50;
        }
        if (elapsed >= timeout_ms) return 0;
    }
    uint16_t ap_count = 0;
    if (esp_wifi_scan_get_ap_num(&ap_count) != ESP_OK || ap_count == 0) return 0;
    #define MAX_APS 10
    wifi_ap_record_t ap_records[MAX_APS];
    uint16_t ap_count_to_get = (ap_count < MAX_APS) ? ap_count : MAX_APS;
    if (esp_wifi_scan_get_ap_records(&ap_count_to_get, ap_records) != ESP_OK) return -1;
    for (int i = 0; i < ap_count_to_get; i++) {
        if (strncmp((char*)ap_records[i].ssid, ssid, sizeof(ap_records[i].ssid)) == 0) {
            return 1;
        }
    }
    return 0;
}

static EventGroupHandle_t wifi_event_group = NULL;
static const int WIFI_CONNECTED_BIT = BIT0;
static uint8_t last_disconnect_reason = 0;

static void wifi_event_handler(void* arg, esp_event_base_t event_base, int32_t event_id, void* event_data) {
    if (event_base != WIFI_EVENT && event_base != IP_EVENT) {
        return;
    }    
    switch (event_id) {           
        case WIFI_EVENT_STA_DISCONNECTED: {
            wifi_event_sta_disconnected_t* dis = (wifi_event_sta_disconnected_t*) event_data;
            printf("WiFi: Disconnected from AP, reason: %d\n", dis->reason);
            last_disconnect_reason = dis->reason;
            break;
        }        
        case IP_EVENT_STA_GOT_IP: {
            ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
            printf(IPSTR ", ", IP2STR(&event->ip_info.ip));
            last_disconnect_reason = 0;
            xEventGroupSetBits(wifi_event_group, WIFI_CONNECTED_BIT);
            break;
        }        
        default:
            break;
    }
}

cell wifi_is_connected(void) {
    wifi_ap_record_t ap_info;
    return (esp_wifi_sta_get_ap_info(&ap_info) == ESP_OK) ? -1 : 0;
}

#ifndef WIFI_SCAN_METHOD_FAST
#define WIFI_SCAN_METHOD_FAST       0
#endif

cell wifi_open(int auth_mode, int timeout_ms, char *password, char *ssid ) {
    if (!ssid || !password || timeout_ms < 0) return -1;    
    if (esp_netif_get_handle_from_ifkey("WIFI_STA_DEF") == NULL) {
        wifi_event_group = xEventGroupCreate();
        esp_netif_init();
        esp_event_loop_create_default();
        esp_netif_create_default_wifi_sta();        
        wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
        esp_wifi_init(&cfg);
        esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL, NULL);
        esp_event_handler_instance_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler, NULL, NULL);
    } else {
        if (wifi_event_group == NULL) {
            wifi_event_group = xEventGroupCreate();
        }
    }
    esp_wifi_set_mode(WIFI_MODE_STA);
    esp_wifi_start();
    wifi_config_t wifi_config = {0};
    strncpy((char*)wifi_config.sta.ssid, ssid, sizeof(wifi_config.sta.ssid) - 1);
    strncpy((char*)wifi_config.sta.password, password, sizeof(wifi_config.sta.password) - 1);
    wifi_config.sta.scan_method = WIFI_SCAN_METHOD_FAST;
    wifi_config.sta.sort_method = WIFI_CONNECT_AP_BY_SIGNAL;
    wifi_config.sta.threshold.rssi = -127;
    wifi_config.sta.threshold.authmode = auth_mode;
    esp_wifi_set_config(WIFI_IF_STA, &wifi_config);
    xEventGroupClearBits(wifi_event_group, WIFI_CONNECTED_BIT);
    last_disconnect_reason = 0;
    esp_wifi_connect();
    int elapsed = 0;
    while (elapsed < timeout_ms) {
        EventBits_t bits = xEventGroupGetBits(wifi_event_group);
        if (bits & WIFI_CONNECTED_BIT) {
            return 0;
        }
        if (last_disconnect_reason != 0) {
            int reason = last_disconnect_reason;
            last_disconnect_reason = 0;  // Reset for next attempt
            return reason;  // Return de reason code (positive number)
        }
        vTaskDelay(pdMS_TO_TICKS(100));
        elapsed += 100;
    }
    return -1;  
}
     
void wifi_start(void) {
    if (esp_netif_get_handle_from_ifkey("WIFI_STA_DEF") == NULL) {
        esp_netif_init();
        esp_event_loop_create_default();
        esp_netif_create_default_wifi_sta();
    }
    esp_wifi_deinit();
    vTaskDelay(100 / portTICK_PERIOD_MS);
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    if (esp_wifi_init(&cfg) == ESP_OK) {
        esp_wifi_set_mode(WIFI_MODE_STA);
        esp_wifi_start();
    } else {
        printf("WiFi: Init failed\n");
    }
}

void wifi_stop(void) {
    esp_wifi_stop();
    esp_wifi_deinit();
}


#define MAX_PAYLOAD_SIZE 1470
#define BUFFER_OVERHEAD 10  // 6 bytes MAC + 4 bytes count

static uint8_t *s_buffer = NULL;
static bool s_ready = false;
static SemaphoreHandle_t s_sem = NULL;

static void send_cb(const esp_now_send_info_t *tx_info, esp_now_send_status_t status) {
    if (s_sem) xSemaphoreGive(s_sem);
}

static void recv_cb(const esp_now_recv_info_t *recv_info, const uint8_t *data, int data_len) {
    if (s_ready || !s_buffer) return;
    memcpy(s_buffer, recv_info->src_addr, 6);
    *(uint32_t *)(s_buffer + 6) = data_len;
    if (data_len > MAX_PAYLOAD_SIZE) data_len = MAX_PAYLOAD_SIZE;
    memcpy(s_buffer + 10, data, data_len);
    s_ready = true;
}

esp_err_t esp_now_open(uint8_t channel) {
    esp_err_t r;
    if ((r = nvs_flash_init()) == ESP_ERR_NVS_NO_FREE_PAGES || r == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        r = nvs_flash_init();
    }
    if (r) return r;
    if ((r = esp_event_loop_create_default()) && r != ESP_ERR_INVALID_STATE) return r;
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    if ((r = esp_wifi_init(&cfg))) return r;
    if ((r = esp_wifi_set_mode(WIFI_MODE_STA))) return r;
    if ((r = esp_wifi_start())) return r;
    if ((r = esp_wifi_set_channel(channel, WIFI_SECOND_CHAN_NONE))) return r;
    if ((r = esp_now_init())) return r;
    esp_wifi_set_ps(WIFI_PS_NONE);
    if ((r = esp_now_register_send_cb(send_cb))) return r;
    if ((r = esp_now_register_recv_cb(recv_cb))) return r;
    if (!s_sem) s_sem = xSemaphoreCreateBinary();
    return (s_sem) ? ESP_OK : ESP_ERR_NO_MEM;
}

esp_err_t esp_now_open_receiver(uint8_t *buffer, uint8_t channel) {
    s_buffer = buffer;
    s_ready = false;
    return esp_now_open(channel);
}

bool esp_now_listen(void) {
    return s_ready;
}

uint8_t* esp_now_get_data(void) {
    return s_buffer;
}

void esp_now_release_buffer(void) {
    s_ready = false;
}

esp_err_t my_esp_now_send(uint8_t *mac, size_t len, uint8_t *data, int timeout_ms) {
    if (!s_sem) return ESP_ERR_INVALID_STATE;
    if (timeout_ms < 1) return esp_now_send(mac, data, len);
    xSemaphoreTake(s_sem, 0);
    esp_err_t r = esp_now_send(mac, data, len);
    if (r) return r;
    return (xSemaphoreTake(s_sem, pdMS_TO_TICKS(timeout_ms)) == pdTRUE) ? ESP_OK : ESP_ERR_TIMEOUT;
}

void my_esp_now_add_peer(uint8_t *mac_addr, int encrypt, uint8_t channel) {
    esp_now_peer_info_t peerInfo = {
        .channel = channel,
        .ifidx = WIFI_IF_STA,
        .encrypt = encrypt,
    };
    memcpy(peerInfo.peer_addr, mac_addr, ESP_NOW_ETH_ALEN);
    esp_now_add_peer(&peerInfo);
}

esp_err_t my_esp_now_del_peer(uint8_t *mac) {
    return esp_now_del_peer(mac);
}

static DRAM_ATTR portMUX_TYPE global_int_mux = portMUX_INITIALIZER_UNLOCKED;

void IRAM_ATTR interrupt_disable() {
    if (xPortInIsrContext()) {
        portENTER_CRITICAL_ISR(&global_int_mux);
    } else {
        portENTER_CRITICAL(&global_int_mux);
    }
}

void IRAM_ATTR interrupt_restore() {
    if (xPortInIsrContext()) {
        portEXIT_CRITICAL_ISR(&global_int_mux);
    } else {
        portEXIT_CRITICAL(&global_int_mux);
    }
}

void set_log_level(char *component, int level) {
    esp_log_level_set(component, level);
}

#define SOCKET_TAG "SOCKET"

static int client_socket(const char *host, const char *portstr, int socktype) {
    struct sockaddr_in server_addr = {0};
    int sock = -1;
    int port = atoi(portstr);
    if (port <= 0 || port > 65535) {
        ESP_LOGE(SOCKET_TAG, "Invalid port: %s", portstr);
        return -1;
    }
    sock = socket(AF_INET, socktype, 0);
    if (sock < 0) {
        ESP_LOGE(SOCKET_TAG, "socket() failed: %s", strerror(errno));
        return -1;
    }
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    if (inet_aton(host, &server_addr.sin_addr) == 0) {
        struct hostent *hp = gethostbyname(host);
        if (hp == NULL) {
            ESP_LOGE(SOCKET_TAG, "Failed to resolve host: %s", host);
            close(sock);
            return -1;
        }
        memcpy(&server_addr.sin_addr, hp->h_addr, sizeof(server_addr.sin_addr));
    }
    if (socktype == SOCK_STREAM) {
        if (connect(sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
            ESP_LOGE(SOCKET_TAG, "connect() failed: %s", strerror(errno));
            close(sock);
            return -1;
        }
        ESP_LOGD(SOCKET_TAG, "TCP connected to %s:%s", host, portstr);
    } else {
        if (bind(sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
            ESP_LOGE(SOCKET_TAG, "bind() failed: %s", strerror(errno));
            close(sock);
            return -1;
        }
        ESP_LOGD(SOCKET_TAG, "UDP bound to %s:%s", host, portstr);
    }
    return sock;
}

cell udp_client(char *host, char *portstr) {
    return client_socket(host, portstr, SOCK_DGRAM);
}

int stream_connect(char *host, char *portstr, int timeout_msecs) {
    int s = client_socket(host, portstr, SOCK_STREAM);
    int error;
    if (s < 0) return s;
    if (timeout_msecs > 0) {
        struct timeval recv_timeout;
        recv_timeout.tv_sec = timeout_msecs / 1000;
        recv_timeout.tv_usec = (timeout_msecs % 1000) * 1000;
        error = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &recv_timeout, sizeof(recv_timeout));
        if (error) {
            ESP_LOGE(SOCKET_TAG, "SO_RCVTIMEO failed: %s", strerror(errno));
            close(s);
            return -3;
        }
        error = setsockopt(s, SOL_SOCKET, SO_SNDTIMEO, &recv_timeout, sizeof(recv_timeout)); if 
        (error) {
            ESP_LOGW(SOCKET_TAG, "SO_SNDTIMEO failed (non-fatal): %s", strerror(errno));
        }
    }
    return s;
}

cell start_server(uint16_t port) {
    struct sockaddr_in addr = {0};
    int sock;
    int opt = 1;
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return -1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(sock);
        return -2;
    }
    if (listen(sock, 10) != 0) {
        close(sock);
        return -3;
    }
    return sock;
}

#include <sys/select.h>
#include <sys/time.h>
#include <errno.h>

#define SELECT_TAG "SELECT"

cell my_select(int maxfdp1, fd_set *reads, fd_set *writes, fd_set *excepts, int msecs) {
    struct timeval timeout;
    int result;
    if (msecs >= 0) {
        timeout.tv_sec = msecs / 1000;
        timeout.tv_usec = (msecs % 1000) * 1000;
    }
    if (msecs >= 0) {
        result = select(maxfdp1, reads, writes, excepts, &timeout);
    } else {
        result = select(maxfdp1, reads, writes, excepts, NULL);
    }
    if (result < 0) {
        if (errno != EINTR) {
            ESP_LOGD(SELECT_TAG, "select() failed: %s", strerror(errno));
        }
    }
    return (cell)result;
}

int try_receive(int sock, int req_buf_size, char *req_buf) {
    if (!req_buf || req_buf_size <= 0 || sock < 0) {
        return -1;
    }
    int flags = fcntl(sock, F_GETFL, 0);
    if (flags == -1) {
        return -1;
    }
    if (fcntl(sock, F_SETFL, flags | O_NONBLOCK) == -1) {
        return -1;
    }
    int len = recv(sock, req_buf, req_buf_size, 0);
    int err = errno;
    fcntl(sock, F_SETFL, flags);
    if (len < 0) {
        if (err == EAGAIN || err == EWOULDBLOCK) {
            return 0;  // No data
        }
        return -1;  // Real error
    }
    return len;
}

#define DHCP_TAG "DHCP"

cell dhcpc_status(void) {
    esp_netif_t *netif = NULL;
    esp_netif_ip_info_t ip_info;
    netif = esp_netif_get_handle_from_ifkey("WIFI_STA_DEF");
    if (netif == NULL) {
        netif = esp_netif_get_handle_from_ifkey("ETH_DEF");
    }
    if (netif == NULL) {
        ESP_LOGD(DHCP_TAG, "No network interface found");
        return 0;
    }
    if (esp_netif_get_ip_info(netif, &ip_info) != ESP_OK) {
        ESP_LOGD(DHCP_TAG, "Failed to get IP info");
        return 0;
    }
    if (ip_info.ip.addr == 0 || ip_info.ip.addr == 0xFFFFFFFF) {
        ESP_LOGD(DHCP_TAG, "No valid IP address");
        return 0;
    }
    char ip_str[16];
    esp_ip4addr_ntoa(&ip_info.ip, ip_str, sizeof(ip_str));
    return 1;
}

cell my_lwip_write(int handle, size_t len, void *adr) {
    return (cell)write(handle, adr, len);
}

int udp_sendto_func(char *host, char *portstr, size_t len, void *data) {
    struct sockaddr_in dest_addr = {0};
    int sock;
    int ret;
    int port = atoi(portstr);
    if (port <= 0 || port > 65535) return -1;
    sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) return -1;
    dest_addr.sin_family = AF_INET;
    dest_addr.sin_port = htons(port);
    if (inet_aton(host, &dest_addr.sin_addr) == 0) {
        struct hostent *hp = gethostbyname(host);
        if (hp == NULL) {
            ESP_LOGE(SOCKET_TAG, "DNS lookup failed for %s", host);
            close(sock);
            return -1;
        }
        memcpy(&dest_addr.sin_addr, hp->h_addr, sizeof(dest_addr.sin_addr));
    }
    ret = sendto(sock, data, len, 0, (struct sockaddr *)&dest_addr, sizeof(dest_addr));
    if (ret < 0) {
        ESP_LOGE(SOCKET_TAG, "sendto failed: %s (errno=%d)", strerror(errno), errno);
        ESP_LOGE(SOCKET_TAG, "  host=%s, port=%s, len=%d", host, portstr, (int)len);
    }
    close(sock);
    return ret;
}

cell my_lwip_read(int handle, size_t len, void *adr) {
    return (cell)read(handle, adr, len);
}

void init_filesystem(void) {
    esp_vfs_littlefs_conf_t conf = {
        .base_path = "/esp-32",
        .partition_label = "storage",
        .format_if_mount_failed = true,
        .dont_mount = false,
    };
    esp_err_t err = esp_vfs_littlefs_register(&conf);
    if (err == ESP_OK) {
//      printf("LittleFS at mounted at: /esp-32/\n");
    } else {
        printf("LittleFS mount failed: %s\n", esp_err_to_name(err));
        printf("Trying to format and remount...\n");
        conf.format_if_mount_failed = true;
        err = esp_vfs_littlefs_register(&conf);
        if (err == ESP_OK) {
            printf("LittleFS formatted and mounted\n");
        }
    }
}

cell my_lfs_unmount(void) {
    return esp_vfs_littlefs_unregister("storage");
}

void *open_dir(char *base_path) {
    return opendir(base_path);
}

void my_closedir(void *dir) {
    if (dir) {
        closedir((DIR *)dir);
    }
}

void *next_file(void *dir) {
    if (!dir) {
        return NULL;
    }
    return (void *)readdir((DIR *)dir);
}

cell dirent_size(void *ent, char *name) {
    struct stat statbuf;
    if (stat(name, &statbuf)) {
        return -1;
    }
    return statbuf.st_size;
}

char *dirent_name(void *ent) {
    if (!ent) {
        return NULL;
    }
    struct dirent *entry = (struct dirent *)ent;
    return entry->d_name;
}

cell rename_file(char *new, char *old) {
    return rename(old, new);
}

cell delete_file(char *name) {
    return remove(name);
}

void fs_avail(char *base_path, uint64_t *free_bytes) {
    uint64_t bytes = 0;
    if (esp_vfs_fat_info(base_path, NULL, &bytes) != ESP_OK) {
        size_t total = 0, used = 0;
        if (esp_littlefs_info("storage", &total, &used) == ESP_OK) {
            bytes = (uint64_t)(total - used);
        }
    }
    uint32_t *ptr = (uint32_t *)free_bytes;
    ptr[0] = (uint32_t)(bytes >> 32);  // MSB (high)
    ptr[1] = (uint32_t)(bytes & 0xFFFFFFFF); // LSB (low)
}

void restart(void) {
    esp_restart();
}

void IRAM_ATTR us(uint32_t us) {
    esp_rom_delay_us(us);
}

void IRAM_ATTR get_system_time(cell *tp) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    tp[0] = (cell)ts.tv_sec;
    tp[1] = (cell)(ts.tv_nsec / 1000);
}

void set_system_time(time_t sec) {
    struct timespec ts = {
        .tv_sec = sec,
        .tv_nsec = 0
    };
    clock_settime(CLOCK_REALTIME, &ts);
}

typedef struct{
    char cmem;
} RtcStruct;
RTC_DATA_ATTR RtcStruct RtcFastMem[3584];

char * rtc_fast(int offset) {
    return &RtcFastMem[offset].cmem;
}

int get_mem_size(int *buffer, uint32_t memtype) {
    buffer[0] = heap_caps_get_total_size(memtype);
    buffer[1] = heap_caps_get_free_size(memtype);
    buffer[2] = heap_caps_get_largest_free_block(memtype);
    return 0;
}

int my_spi_bus_init(int sclk, int miso, int mosi, spi_host_device_t host_id, size_t max_transfer_sz) {
    spi_bus_config_t bus_cfg = {
        .mosi_io_num = mosi,
        .miso_io_num = miso,
        .sclk_io_num = sclk,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = max_transfer_sz,
    };
    return spi_bus_initialize(host_id, &bus_cfg, SPI_DMA_CH_AUTO);
}

esp_err_t spi_device_add_master(spi_device_handle_t *handle_ptr, uint32_t flags, uint32_t queue_size, int cs_pin, uint8_t mode, uint32_t clock_speed, spi_host_device_t host_id) {
    spi_device_interface_config_t devcfg = {
        .clock_speed_hz = clock_speed,
        .mode = mode,
        .spics_io_num = cs_pin,
        .queue_size = queue_size,
        .flags = flags,
        .pre_cb = NULL,
        .post_cb = NULL,
    };
    return spi_bus_add_device(host_id, &devcfg, handle_ptr);
}

esp_err_t spi_master_data(spi_device_handle_t handle, void *recv_addr, void *send_addr, size_t len_bytes) {
    spi_transaction_t trans = {
        .length = len_bytes * 8,
        .rxlength = (recv_addr != NULL) ? len_bytes * 8 : 0,
        .tx_buffer = send_addr,
        .rx_buffer = recv_addr,
    };
    return spi_device_transmit(handle, &trans);
}

int my_spi_free(spi_host_device_t bus_handle, spi_device_handle_t dev_handle) {
    esp_err_t ret = ESP_OK;
    if (dev_handle != 0) {
        ret = spi_bus_remove_device(dev_handle);
        if (ret != ESP_OK) {
            return (cell)ret;
        }
    }
    ret = spi_bus_free(bus_handle);
    return (ret == ESP_OK) ? 0 : (cell)ret;
}

sdmmc_card_t* sd_mount(spi_host_device_t bus_handle, uint32_t speed_khz, int format_option, int cs_pin) {
    sdmmc_host_t host = SDSPI_HOST_DEFAULT();
    host.slot = bus_handle;
    host.max_freq_khz = speed_khz;
    sdspi_device_config_t slot_config = SDSPI_DEVICE_CONFIG_DEFAULT();
    slot_config.gpio_cs = cs_pin;
    slot_config.host_id = host.slot;
    esp_vfs_fat_mount_config_t mount_config = {
        .format_if_mount_failed = (format_option != 0),
        .max_files = 5,
        .allocation_unit_size = 16 * 1024,
    };
    sdmmc_card_t *card = NULL;
    esp_err_t ret = esp_vfs_fat_sdspi_mount("/sdcard", &host, &slot_config, &mount_config, &card);
    return (ret == ESP_OK) ? card : NULL;
}

esp_err_t sd_unmount(sdmmc_card_t *card_handle) {
    return esp_vfs_fat_sdcard_unmount("/sdcard", card_handle);
}

int myfsync(FILE *fileid) {
    fflush(fileid);
    return fsync(fileno(fileid));
}

cell mysetvbuf(int blksize, void *buf, int method, FILE* fp) {
    return setvbuf(fp, (char *)buf, method, blksize);
}
