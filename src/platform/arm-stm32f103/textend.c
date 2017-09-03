// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include "forth.h"

// Prototypes

cell get_msecs();
cell wfi();
cell spins();

cell ((* const ccalls[])()) = {
    C(spins)        //c spins     { i.nspins -- }
    C(wfi)          //c wfi       { -- }
    C(get_msecs)    //c get-msecs { -- i.msecs }
};
