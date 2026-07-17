/*
 * Console I/O routines
 */
#include "forth.h"
#include "compiler.h"
#include "stdlib.h"
#include "driver/uart.h"

extern void init_uart(void);
extern void init_filesystem(void);

static unsigned char input_buffer[8];
static int input_len = 0;
static int input_pos = 0;
static int last_key = 0;
static int last_key_avail = 0;

static void refill_buffer(void)
{
    if (input_pos >= input_len) {
        input_len = uart_read_bytes(UART_NUM_0, input_buffer, sizeof(input_buffer), 0);
        input_pos = 0;
    }
}

static int data_available(void)
{
    refill_buffer();
    return (input_len > 0);
}

int isinteractive(void) { return 1; }
int isstandalone(void) { return 1; }

void raw_emit(unsigned char c)
{
    uart_write_bytes(UART_NUM_0, (const char*)&c, 1);
}

void emit(u_char c, cell *up)
{
    if (c == '\n')
        raw_emit('\r');
    raw_emit(c);
}

void cprint(const char *str, cell *up)
{
    while (*str)
        emit((u_char)*str++, up);
}

int key_avail(cell *up)
{
    if (last_key_avail) {
        return -1;
    }
    if (data_available()) {
        last_key = input_buffer[input_pos];
        last_key_avail = 1;
        return -1;
    }
    return 0;
}

int key(cell *up)
{
    while (!key_avail(up)) {}
    last_key_avail = 0;
    int result = last_key;
    input_pos++;
    if (input_pos >= input_len) {
        input_len = 0;
        input_pos = 0;
    }
    return result;
}

int scankey(cell *up)
{
    while (!data_available()) {}
    int code = 0;
    for (int i = 0; i < input_len; i++) {
        code = (code << 8) | input_buffer[i];
    }
    // Reset buffer
    input_len = 0;
    input_pos = 0;
    last_key_avail = 0;
    last_key = 0;
    return code;
}

void init_io(int argc, char **argv, cell *up)
{
    input_len = 0;
    input_pos = 0;
    last_key_avail = 0;
    last_key = 0;
    init_uart();
    init_filesystem();
}

int caccept(char *addr, cell count, cell *up)
{
    return lineedit(addr, count, up);
}

int puts(const char *);
void output_redirect(const char *str) { puts(str); }

void alerror(char *str, int len, cell *up)
{
    while (len--)
        emit((u_char)*str++, up);
    V(NUM_OUT) = 0;
}

int moreinput(cell *up) { return 1; }

char *getmem(u_cell nbytes, cell *up)
{
    return (char *)malloc(nbytes);
}

void memfree(char *ptr, cell *up)
{
    free(ptr);
}

char *memresize(char *ptr, u_cell nbytes, cell *up)
{
    return (char *)realloc(ptr, nbytes);
}
