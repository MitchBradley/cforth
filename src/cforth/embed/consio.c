/*
 * Stub I/O subroutines for C Forth 93, supporting only console I/O.
 *
 * Exported definitions:
 *
 * emit(char);                  Output a character
 * n = key_avail();             How many characters can be read?
 * error(s);                    Print a string on the error stream
 * char = key();                Get the next input character
 */

#include "forth.h"
#include "compiler.h"

int kbhit(void);
int getkey(void);
int raw_putchar(int c);

int isinteractive() {  return (1);  }

void emit(u_char c, cell *up)
{
    if (c == '\n')
        raw_putchar('\r');
    raw_putchar(c);
}

void cprint(const char *str, cell *up)
{
    while (*str)
        emit((u_char)*str++, up);
}

void title(cell *up)
{
    cprint("CForth by Mitch Bradley\n", up);
}

int caccept(char *addr, cell count, cell *up)
{
    return lineedit(addr, count, up);
}

void alerror(char *str, int len, cell *up)
{
    while (len--)
        emit((u_char)*str++, up);
}

int moreinput(cell *up) {    return (1);  }

int key() {  keymode();  return(getkey());  }

int key_avail() {  return kbhit();  }

void read_dictionary(char *name, cell *up) {  FTHERROR("No file I/O\n");  }

void write_dictionary(char *name, int len, char *dict, int dictsize,
                      cell *up, int usersize)
{
    FTHERROR("No file I/O\n");
}

cell pfopen(char *name, int len, int mode, cell *up)  {  return (0);  }
cell pfcreate(char *name, int len, int mode, cell *up)  {  return (0);  }

cell pfclose(cell fd, cell *up) {  return (0);  }

cell freadline(cell f, cell *sp, cell *up)        /* Returns IO result */
{
    sp[0] = 0;
    sp[1] = 0;
    return (NOFILEIO);
}

cell
pfread(cell *sp, cell len, void *fid, cell *up)  // Returns IO result, actual in *sp
{
    sp[0] = 0;
    return (NOFILEIO);
}

cell
pfwrite(void *adr, cell len, void *fid, cell *up)
{
    return (NOFILEIO);
}

cell
pfseek(void *fid, u_cell high, u_cell low, cell *up)
{
    return (NOFILEIO);
}

cell
pfposition(void *fid, u_cell *high, u_cell *low, cell *up)
{
    *high = *low = 0;
    return (NOFILEIO);
}
cell pfflush(cell f, cell *up) { return (NOFILEIO); }
void pfmarkinput(void *fp, cell *up) { }
void pfprint_input_stack(void) { }
cell pfsize(cell f, u_cell *high, u_cell *low, cell *up) { return (NOFILEIO); }

void clear_log(cell *up) { }
void start_logging(cell *up) { }
void stop_logging(cell *up) { }
cell log_extent(cell *log_base, cell *up) { *log_base = 0; return 0; }

int isstandalone() { return 1; }
