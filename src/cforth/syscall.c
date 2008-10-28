/*
 * C Forth
 * Copyright (c) 2008 FirmWorks
 */

#include "forth.h"

int errno = 0;

unimplemented()
{
    errno = -1;
    return(-1);
}

perror(s)
    char *s;
{
    cprint(s);
    if (errno == -1)
	cprint("Unimplemented system call\n");
    else
	cprint("I don't know.\n");
}

dosyscall()  { return(unimplemented()); }
system() { return(unimplemented()); }
chdir()  { return(unimplemented()); }

void linemode() {}
void keymode() {}
void restoremode() {}

getstat() { return(unimplemented()); }
