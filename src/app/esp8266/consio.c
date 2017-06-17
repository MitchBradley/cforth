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
int isstandalone() {  return (1);  }

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
    cprint("C Forth 2005.  Copyright (c) 1997-2005 by FirmWorks\n", up);
}
