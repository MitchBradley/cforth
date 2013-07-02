// C Forth 2005.  Copyright (c) 2005 FirmWorks

#include "forth.h"
#include "compiler.h"

const struct header builtin_hdr = {
#include "dicthdr.h"
};

u_char variables[MAXUSER] = {
#include "userarea.h"
};

u_char dictionary[MAXDICT] = {
#include "dict.h"
};

// dictmax is ignored because the dictionary is defined statically
cell *
prepare_builtin_dictionary(int dictmax)
{
    u_char *here;
    here = dictionary + builtin_hdr.dsize;
    init_compiler(dictionary, dictionary+MAXDICT, 0xfffe, here, dictionary + MAXDICT, (cell *)variables);
    return (cell *)variables;
}
