/*
 * C Forth
 * Copyright (c) 2008 FirmWorks
 */

#include "forth.h"
#include "compiler.h"

int unimp = 0;

int unimplemented()
{
    unimp = 1;
    return(-1);
}

void prerror(const char *s, cell *up)
{
    cprint(s, up);
    if (unimp) {
        cprint("Unimplemented syscall\n", up);
        unimp = 0;
    } else {
        cprint("I don't know.\n", up);
    }
}

cell dosyscall()  { return(unimplemented()); }
int system() { return(unimplemented()); }
int chdir()  { return(unimplemented()); }

void linemode() {}
void keymode() {}
void restoremode() {}

int getstat() { return(unimplemented()); }
