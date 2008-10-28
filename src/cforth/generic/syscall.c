// C Forth 83
// Copyright (c) 1986 by Bradley Forthware

#include "forth.h"

// const int errno = 0;

perror(char *s) { }

dosyscall()  { return(-1); }
system() { return(-1); }
chdir()  { return(-1); }

void linemode() {}
void keymode() {}
void restoremode() {}

filetruncate() { return(-1); }
getstat() { return(-1); }
