/* mallocl.c 1.3 92/11/27 */
/*
 * Getmem which uses the C library malloc.
 */

char *
getmem(unsigned int nbytes)
{
    extern void *malloc();

    return( malloc(nbytes) );
}

void
memfree(char *ptr)
{
    free(ptr);
}

char *
memresize(char *ptr, unsigned int nbytes)
{
    extern char *realloc();

    return( realloc(ptr, nbytes) );
}
