#include "forth.h"
#include "compiler.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static cell variables[MAXVARS];

static int
is_readable(char *name)
{
    FILE *fd;
    if ((fd = fopen(name, "rb")) == NULL)
	    return 0;
    (void)fclose(fd);
    return 1;
}

static int
read_dictionary(char *name, u_char *dictbase, cell *up)
{
    FILE *fd;
    struct header file_hdr;

    if ((fd = fopen(name, "rb")) == NULL)
        fatal("Can't open dictionary file\n", up);

    if (fread((char *)&file_hdr, 1, sizeof(file_hdr), fd) != sizeof(file_hdr))
        fatal("Can't read header\n", up);

    if (file_hdr.magic != MAGIC)
        fatal("Bad magic number in dictionary file\n", up);

#ifndef RELOCATE
    if (file_hdr.dstart != 0)
        fatal("Remake the dictionary file\n", up);
#endif

    if (fread((char *)dictbase, 1, (int)file_hdr.dsize, fd)
        != (unsigned int)file_hdr.dsize)
        fatal("Can't read dictionary image\n", up);

    if (fread((char *)up, 1, (int)file_hdr.usize, fd)
        != (unsigned int)file_hdr.usize)
        fatal("Can't read user area image\n", up);

#ifdef RELOCATE
    {
        unsigned int rbytes, rbits;
        register unsigned int i;
        cell *tp;
        cell *origin = (cell *)V(TORIGIN);
        cell offset = (cell)V(TORIGIN) - file_hdr.entry;

        rbits = file_hdr.dsize/sizeof(cell);
        rbytes = (rbits + 7) >> 3;
        if (fread((char *)relmap, 1, (int)rbytes, fd) != rbytes)
            fatal("Can't read dictionary relocation map\n", up);
        if (offset != 0) {
            for (i = 0; i < rbits; i++) {
                if (relmap[i>>3] & bit[i&7]) {
                    tp = &origin[i];
                    *tp += offset;
                }
            }
        }
        rbits = file_hdr.usize/sizeof(cell);
        rbytes = (rbits + 7) >> 3;
        if (fread((char *)urelmap, 1, (int)rbytes, fd) != rbytes)
            fatal("Can't read data relocation map\n", up);
        if (offset != 0) {
            for (i = 0; i < rbits; i++) {
                if ((relmap[i>>3] & bit[i&7])
                && ((token_t)up[i] >= MAXPRIM)) {
                    tp = &up[i];
                    *tp += offset;
                }
            }
        }
    }
#endif

    (void)fclose(fd);

    return (file_hdr.dsize);
}

void
write_dictionary(char *name, int len, char *dict, int dictsize, cell *up, int usersize)
{
    FILE *fd;
    struct header file_hdr;
    char cstrbuf[512];

    if ((fd = fopen(altocstr(name, len, cstrbuf, 512), "wb")) == NULL)
        fatal("Can't create dictionary file\n", up);

    file_hdr.magic = MAGIC;
    file_hdr.serial = 0;
    file_hdr.dstart = 0;
    file_hdr.dsize = dictsize;
    file_hdr.ustart = 0;
    file_hdr.usize = usersize;
    file_hdr.entry = 0;
    file_hdr.res1 = 0;

    if (fwrite((char *)&file_hdr, 1, sizeof(file_hdr), fd) != sizeof(file_hdr))
        fatal("Can't write header\n", up);

    if (fwrite(dict, 1, dictsize, fd) != dictsize)
        fatal("Can't write dictionary image\n", up);

    if (fwrite((char *)up, 1, usersize, fd) != usersize)
        fatal("Can't write user area image\n", up);

    (void)fclose(fd);
}

// Initialize the Forth environment.  This must be called once, prior to
// calling inner_interpreter() the first time.

cell *
prepare_dictionary(int *argcp, char *(*argvp[]))
{
    u_char *origin;
    u_char *here;
    u_char *xlimit;
    int dict_size;
    char *extension;

    char *dictionary_file = "";

    // Allocate space for the Forth dictionary and read its initial contents
    origin = aln_alloc(MAXDICT, variables);

    xlimit = &origin[MAXDICT];
    if(*argcp < 2
       || (extension = strrchr((*argvp)[1],'.')) == NULL
       || strcmp(extension, ".dic") != 0 ) {
	dictionary_file = is_readable("app.dic") ? "app.dic" : DEFAULT_EXE;
    } else {
        dictionary_file = (*argvp)[1];
        *argcp -= 1;
        *argvp += 1;
    }

    dict_size = read_dictionary(dictionary_file, origin, variables);
    here = &origin[dict_size];

    *(token_t *)origin = 0;
    init_compiler(origin, xlimit,
		  (token_t)(MAXDICT / sizeof(token_t)),
		  here, xlimit, variables);
    return variables;
}

#ifdef notdef
static int
move_dictionary()
{
    if (builtin_hdr.magic != MAGIC)
        return(0);

    memcpy((char *)V(TORIGIN), dict, builtin_hdr.dsize);

    V(DP) = (cell)((u_char *)V(TORIGIN) + builtin_hdr.dsize);

    memcpy((char *)variable, dict+builtin_hdr.dsize, builtin_hdr.usize);

    return(1);
}
#endif

void
fatal(char *str, cell *up)
{
    alerror(str, strlen(str), up);
    (void)exit(1);
}
