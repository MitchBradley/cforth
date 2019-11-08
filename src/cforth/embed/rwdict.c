// C Forth 2005.  Copyright (c) 2005 FirmWorks

#include "forth.h"
#include "compiler.h"

const struct header builtin_hdr = {
#include "dicthdr.h"
};

u_char variables[
sizeof((u_char []){
#  include "userarea.h"
}) > MAXUSER ? -1 : MAXUSER
] = {
#  include "userarea.h"
};

u_char dictionary[
sizeof((u_char []){
#  include "dict.h"
}) > MAXDICT ? -1 : MAXDICT
] = {
#  include "dict.h"
};

extern u_char *origin;

// dictmax is ignored because the dictionary is defined statically
cell *
prepare_builtin_dictionary(int dictmax)
{
    u_char *here;
    here = dictionary + builtin_hdr.dsize;
    *(token_t *)dictionary = 0;
    init_compiler(dictionary, dictionary+MAXDICT,
		  (token_t)(sizeof(dictionary) / sizeof(token_t)),
		  here, dictionary + MAXDICT, (cell *)variables);
    return (cell *)variables;
}
