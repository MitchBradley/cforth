#include "forth.h"
#include "dictfile.h"
#include <stdio.h>

int variables[MAXVARS];
int dictionary[MAXDICT];

// Initialize the Forth environment.  This must be called once, prior to
// calling inner_interpreter() the first time.

int
prepare_dictionary(int *argcp, char *(*argvp[]))
{
    int here;
    int xlimit;

    char *dictionary_file = "";
    extern char *strrchr(const char *s, int c);

    // Allocate space for the Forth dictionary and read its initial contents
    word_dict = aln_alloc(MAXDICT);

    xlimit = MAXDICT;
    if(*argcp < 2
    ||  strcmp(strrchr((*argvp)[1],'.'), ".dic") != 0 ) {
        dictionary_file = DEFAULT_EXE;
    } else {
        dictionary_file = (*argvp)[1];
        *argcp -= 1;
        *argvp += 1;
    }

    here = read_dictionary(dictionary_file, variables);

    return init_compiler(here, xlimit, variables);
}

int read_int(FILE *fd)
{
    int r;
    r = fgetc(fd);
    r <<= 8;
    r += fgetc(fd);
    r <<= 8;
    r += fgetc(fd);
    r <<= 8;
    r += fgetc(fd);
    return r;
}

void write_int(int r, FILE *fd)
{
    fputc(r>>24, fd);
    fputc(r>>16, fd);
    fputc(r>>8, fd);
    fputc(r, fd);
}

int
read_dictionary(char *name, int *up)
{
    FILE *fd;
    int here;
    int usize;
    int i;
    int upnum;

    if ((fd = fopen(name, "rb")) == NULL)
        fatal("Can't open dictionary file\n", up);

    if (read_int(fd) != MAGIC)
        fatal("Bad magic number in dictionary file\n", up);

    (void)read_int(fd);
    (void)read_int(fd);
    here = read_int(fd);
    upnum = read_int(fd);
    usize = read_int(fd);
    (void)read_int(fd);
    (void)read_int(fd);

    for (i = 0; i < here; i++)
        DATA(i) = read_int(fd);

    for (i = 0; i < usize; i++)
        up[i] = read_int(fd);

    (void)fclose(fd);

    return here;
}

void
write_dictionary(int name, int len, int dictsize, int up, int usersize)
{
    FILE *fd;
    char cstrbuf[512];
    int i;

    if ((fd = fopen(altostr(name, len, cstrbuf, 512), "wb")) == NULL)
        fatal("Can't create dictionary file\n", up);

    write_int(MAGIC, fd);
    write_int(0, fd);
    write_int(0, fd);
    write_int(dictsize, fd);
    write_int(up, fd);
    write_int(usersize, fd);
    write_int(0, fd);
    write_int(0, fd);

    for (i=0; i<dictsize; i++)
        write_int(DATA(i), fd);

    for (i=0; i<usersize; i++)
        write_int(V(i), fd);

    (void)fclose(fd);
}

fatal(char *str, int up)
    
{
    extern void exit(int);
    strerror(str, up);
    exit(1);
}
