/* malloca.c 1.2 90/03/11 */
/*
 * Getmem which cheats and statically allocates the dictionary array
 * in the bss segment.  This is good for Unix, which does not store
 * the BSS image in the program file, but bad for DOS, which does store
 * the BSS in the file, thus wasting tons of space.
 */

#include "forth.h"

char *
getmem(cell nbytes)
{
    static char dictionary[MAXDICT];

    return( dictionary );
}

void
memfree(void *ptr)
{
    free(ptr);
}

void *
memresize(void *ptr, u_cell nbytes)
{
    return( realloc(ptr, nbytes) );
}

