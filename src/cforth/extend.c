#include "forth.h"

// Here is where you can add your own extensions.
// Add entries to the ccalls table, and create Forth entry points
// for them with ccall.

cell
example1(cell a, cell b)		// Returns sum of a and b
{
    return(a+b);
}

char *
example2(char *s) // Returns last 9 characters of string s in reverse order
{
    char *p;
    int i;
    static char result[10];

    for(p=s; *p; p++)
	;
    for(i = 0; i < 9  &&  p > s; i++)
        result[i] = *--p;

    result[i] = '\0';

    return (result);
}

cell ((* const ccalls[])()) = {
  C(example1)	//c sum { i.a i.b -- i.sum }
  C(example2)	//c byterev { a.in -- a.out }
  // Add your own routines here
};
