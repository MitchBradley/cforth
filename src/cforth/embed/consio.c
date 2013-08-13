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

int isinteractive() {  return (1);  }

void emit(u_char c, cell *up)
{
    if ( c == '\n' || c == '\r' ) {
        V(NUM_OUT) = 0;
        V(NUM_LINE)++;
    } else
        V(NUM_OUT)++;
    (void)putchar((char)c);
}

void cprint(char *str, cell *up)
{
    while (*str)
        emit((u_char)*str++, up);
}

void title(cell *up)
{
    cprint("C Forth 2005.  Copyright (c) 1997-2005 by FirmWorks\n", up);
}

int caccept(char *addr, cell count, cell *up)
{
    return lineedit(addr, count, up);
}

void alerror(char *str, int len, cell *up)
{
    while (len--)
        emit((u_char)*str++, up);

    /* Sequences of calls to error() eventually end with a newline */
    V(NUM_OUT) = 0;
}

int moreinput() {    return (1);  }

int key() {  keymode();  return(getkey());  }

int key_avail() {  return kbhit();  }

void read_dictionary(char *name, cell *up) {  FTHERROR("No file I/O\n");  }

void write_dictionary(char *name, int len, char *dict, int dictsize,
                 char *user, int usersize, cell *up)
{
    FTHERROR("No file I/O\n");
}

cell pfopen(char *name, int mode, cell *up)  {  return (0);  }
cell pfcreate(char *name, int mode, cell *up)  {  return (0);  }

cell pfclose(cell fd, cell *up) {  return (0);  }

cell freadline(cell f, cell *sp, cell *up)        /* Returns IO result */
{
    sp[0] = 0;
    sp[1] = 0;
    return (READFAIL);
}

cell
pfread(cell *sp, cell len, void *fid, cell *up)  // Returns IO result, actual in *sp
{
    sp[0] = 0;
    return (READFAIL);
}

cell
pfwrite(cell *sp, cell len, void *fid, cell *up)  // Returns IO result, actual in *sp
{
    sp[0] = 0;
    return (WRITEFAIL);
}
