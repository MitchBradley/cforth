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
    extern void free(void *);

    free(ptr);
}

char *
memresize(char *ptr, unsigned int nbytes)
{
    extern void *realloc(void *, unsigned int);

    return( realloc(ptr, nbytes) );
}
