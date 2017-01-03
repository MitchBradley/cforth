/*
 * Console I/O routines
 */

#include "forth.h"
#include "compiler.h"
#include "stdlib.h"
#include "driver/uart.h"

int isinteractive() {  return (1);  }
int isstandalone() {  return (1);  }

void raw_emit(unsigned char c)
{
    uart_write_bytes(0, &c, 1);
}

void emit(u_char c, cell *up)
{
    if (c == '\n')
        raw_emit('\r');
    raw_emit(c);
}

u_char key_is_avail = 0;
u_char the_key;

int key_avail(cell *up)
{
    if (key_is_avail) {
        return (cell)-1;
    }
    if(uart_read_bytes(0, &the_key, 1, 0)) {
        key_is_avail = 1;
        return (cell)-1;
    }
    return 0;
}

int key(cell *up)
{
    cell this_key;
    while (!key_avail(up)) {}
    key_is_avail = 0;
    return (cell)the_key;
}

static const char *TAG = "forth";
#define BUF_SIZE (1024)
void uart_on(void)
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
    //Set UART parameters
    uart_param_config(uart_num, &uart_config);
    //Set UART log level
//    esp_log_level_set(TAG, ESP_LOG_INFO);
    //Set UART pins,(-1: default pin, no change.)
    //For UART0, we can just use the default pins.
    //uart_set_pin(uart_num, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
    //Install UART driver( We don't need an event queue here)
    //We don't even use a buffer for sending data.
    uart_driver_install(uart_num, BUF_SIZE * 2, 0, 0, NULL, 0);
}

void init_io(int argc, char **argv, cell *up)
{
  key_is_avail = 0;
  uart_on();
}

int caccept(char *addr, cell count, cell *up)
{
    return lineedit(addr, count, up);
}

// Defines the resolution of c_puts
void output_redirect(const char *str) {
    puts(str);
}

void alerror(char *str, int len, cell *up)
{
    while (len--)
        emit((u_char)*str++, up);

    /* Sequences of calls to error() eventually end with a newline */
    V(NUM_OUT) = 0;
}

// moreinput() returns 0 when the console input stream has been closed for good
int moreinput() {  return (1);  }

char *getmem(u_cell nbytes, cell *up)
{
    return (char *)malloc(nbytes);
}

void memfree(char *ptr, cell *up)
{
    free(ptr);
}
char * memresize(char *ptr, u_cell nbytes, cell *up)
{
    return (char *)realloc(ptr, nbytes);
}
