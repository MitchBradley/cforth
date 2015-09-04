/*
 * C Forth
 * Copyright (c) 2008 FirmWorks
 */

#include "forth.h"
#include "compiler.h"

int errno = 0;

int unimplemented()
{
    errno = -1;
    return(-1);
}

void prerror(const char *s, cell *up)
{
    cprint(s, up);
    if (errno == -1)
        cprint("Unimplemented system call\n", up);
    else
        cprint("I don't know.\n", up);
}

cell dosyscall()  { return(unimplemented()); }
int system() { return(unimplemented()); }
int chdir()  { return(unimplemented()); }

void linemode() {}
void keymode() {}
void restoremode() {}

int getstat() { return(unimplemented()); }
