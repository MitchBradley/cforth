// Interfaces between ESP32/FreeRTOS and Forth

typedef int cell;

#include "freertos/FreeRTOS.h"
#include "esp_system.h"
#include "nvs_flash.h"
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

#include <driver/gpio.h>
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
