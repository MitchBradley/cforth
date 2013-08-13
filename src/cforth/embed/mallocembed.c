// Getmem for a deeply-embedded environment with limited memory

#include "forth.h"
#include "compiler.h"

char * 
getmem(u_cell nbytes, cell *up)
{
    return( (char *)(V(LIMIT) -= nbytes) );
}

void memfree(char *ptr, cell *up) { }
char * memresize(char *ptr, u_cell nbytes, cell *up)  {  return ((char *)0);  }
