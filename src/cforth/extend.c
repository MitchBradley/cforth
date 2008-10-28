#include "forth.h"

// Here is where you can add your own extensions.
// Add entries to the ccalls table, and create Forth entry points
// for them with ccall.

extern int strlen(const char *);

cell
example1(cell a, cell b)		// Returns sum of a and b
{
    return(a+b);
}

char *
example2(char *s) // Returns last 9 characters of string s in reverse order
{
    register char *p;
    int i;
    static char result[10];

    p = &s[strlen(s)];
    for(i = 0; i < 9  &&  p > s; i++)
        result[i] = *--p;

    result[i] = '\0';

    return (result);
}

cell ((* const ccalls[])()) = {
    (cell (*)())example1,			// Entry # 0
    (cell (*)())example2,			// Entry # 1
    // Add your own routines here
};

// Forth words to call the above routines may be created by:
//
//  system also
//  0 ccall: sum      { i.a i.b -- i.sum }
//  1 ccall: byterev  { s.in -- s.out }
//
// and could be used as follows:
//
//  5 6 sum .
//  p" hello"  byterev  count type
