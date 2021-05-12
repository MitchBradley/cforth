/*
 * Console I/O routines
 */

#include "forth.h"
#include "compiler.h"
#include "stdlib.h"

extern void uart_write_bytes(int, char *, int);
extern int uart_read_bytes(int, char *, int, int);
extern void init_uart(void);
extern void init_filesystem(void);

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

void cprint(const char *str, cell *up)
{
    while (*str)
        emit((u_char)*str++, up);
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

void init_io(int argc, char **argv, cell *up)
{
  key_is_avail = 0;
  init_uart();
  init_filesystem();
}

int caccept(char *addr, cell count, cell *up)
{
    return lineedit(addr, count, up);
}

int puts(const char *);
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
int moreinput(cell *up) {  return (1);  }

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
