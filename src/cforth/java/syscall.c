/*
 * C Forth 83
 * Copyright (c) 1986 by Bradley Forthware
 */

#include "forth.h"

int errno = 0;

unimplemented()
{
    errno = -1;
    return(-1);
}

why(int up)
{
    if (errno == -1)
        cprint("Unimplemented system call\n", up);
    else
        cprint("I don't know.\n", up);
}

dosyscall()  { return(unimplemented()); }
system() { return(unimplemented()); }
chdir()  { return(unimplemented()); }

void linemode() {}
void keymode() {}
void restoremode() {}

getstat() { return(unimplemented()); }
