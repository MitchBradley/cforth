// Character I/O
#include "forth.h"

extern uart_tx_one_char(unsigned char, unsigned char);

void raw_putchar(unsigned char c)
{
  uart_tx_one_char(0, c);
}

int putchar(int c)
{
    if (c == '\n')
        raw_putchar('\r');
    raw_putchar(c);
}

u_char key_is_avail = 0;
u_char the_key;

enum {
  NONE,
  KEYWAIT,
  ACCEPTWAIT,
} input_wait = NONE;

cell *last_up;

cell grabkey(void)
{
    if (key_is_avail) {
        key_is_avail = 0;
        return (cell)the_key;
    }
    if (uart_getc(&the_key)) {
        return (cell)the_key;
    }
    return -1;
}

int key_avail(cell *up)
{
    if (key_is_avail) {
        return (cell)-1;
    }
    if (uart_getc(&the_key)) {
        key_is_avail = 1;
        return (cell)-1;
    }
    return 0;
}

int key(cell *up)
{
    cell this_key;
    if ((this_key = grabkey()) >= 0) {
        return this_key;
    }
    last_up = up;
    input_wait = KEYWAIT;
    return -2;
}

void init_io(int argc, char **argv, cell *up) {  input_wait = NONE;  key_is_avail = 0; }

int caccept(char *addr, cell count, cell *up)
{
    last_up = up;
    lineedit_start(addr, count, up);
    input_wait = ACCEPTWAIT;
    return -2;
}

void lua_handle_input(int force)
{
    cell *up = last_up;
    cell this_key;

    switch (input_wait) {
        case NONE:
            break;
        case KEYWAIT:
            if (uart_getc(&the_key)) {
                input_wait = NONE;
                spush((cell)the_key, up);
                inner_interpreter(up);
            }
            break;
        case ACCEPTWAIT:
            do {
                if ((this_key = grabkey()) < 0) {
                    return;
                }
            } while (lineedit_step(this_key, up) == 0);

            input_wait = NONE;
            spush(lineedit_finish(up), up);
            inner_interpreter(up);
            break;
    }
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

void output_redirect(const char *str) {
    uart0_sendStr(str);
}

void lua_gpio_unref(unsigned pin) { }
