// Interfaces between ESP32/FreeRTOS and Forth

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
