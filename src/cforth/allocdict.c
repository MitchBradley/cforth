#include "forth.h"

u_char *
allocate_dictionary(cell needed)
{
    u_char dictionary;

    if ( (dictionary = aln_alloc((u_cell)needed)) == (u_char *)0 )
        fatal("Can't allocate memory for the dictionary\n");

#ifdef RELOCATE
    nrelbytes = (needed + 7) >> 3;
    if ( (relmap = aln_alloc(nrelbytes)) == (u_char *)0 )
fatal("Can't allocate memory for the dictionary relocation map\n");
    fill(relmap, nrelbytes, (u_char)0);

    nurelbytes = (MAXUSER + 7) >> 3;
    if ( (urelmap = aln_alloc(nurelbytes)) == (u_char *)0 )
fatal("Can't allocate memory for the data relocation map\n");
    fill(urelmap, nurelbytes, (u_char)0);
#endif

    return dictionary;
}
