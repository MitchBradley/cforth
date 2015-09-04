// C Forth 83
// Copyright (c) 1986 by Bradley Forthware

#include "forth.h"

// const int errno = 0;

void prerror(const char *s, cell *up) { }

cell dosyscall()  { return(-1); }
int system() { return(-1); }
int  chdir()  { return(-1); }

void linemode() {}
void keymode() {}
void restoremode() {}

int filetruncate() { return(-1); }
int getstat() { return(-1); }
