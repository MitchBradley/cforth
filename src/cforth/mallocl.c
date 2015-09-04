/* mallocl.c 1.3 92/11/27 */
/*
 * Getmem which uses the C library malloc.
 */

#include <stdlib.h>

char *
getmem(unsigned int nbytes)
{
    return( calloc(nbytes, 1) );
}

void
memfree(char *ptr)
{
    free(ptr);
}

char *
memresize(char *ptr, unsigned int nbytes)
{
    return( realloc(ptr, nbytes) );
}
