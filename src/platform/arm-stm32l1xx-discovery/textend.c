// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include "forth.h"

// Prototypes

cell i2c_start();
cell i2c_wait();
cell i2c_init();
cell get_msecs();
cell wfi();
cell spins();

cell ((* const ccalls[])()) = {
    C(i2c_start)    //c i2c-start { i.wr i.slave i.alen a.abuf i.dlen a.dbuf -- }
    C(i2c_wait)     //c i2c-wait  { -- i.status }
    C(i2c_init)     //c i2c-init  { -- }
    C(spins)        //c spins     { i.nspins -- }
    C(wfi)          //c wfi       { -- }
    C(get_msecs)    //c get-msecs { -- i.msecs }
};
