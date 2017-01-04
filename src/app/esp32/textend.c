// Forth interfaces to platform-specific C routines
// See "ccalls" below.

#include "forth.h"

extern cell *callback_up;

cell version_adr(void)
{
    extern char version[];
    return (cell)version;
}

cell build_date_adr(void)
{
    extern char build_date[];
    return (cell)build_date;
}

// Many of the routines cited below are defined either directly
// in the ESP32 SDK or in sdk_build/main/interface.c .  It is best
// to avoid putting the definition of ESP-specific routines in
// this file, because doing so typically requires including a
// lot of .h files here, and that introduces a dependency on the
// SDK configurator, which greatly complicates the Makefile
// dependencies for the CForth portion of the build.  We avoid that
// by just referring to the names of the routines we want to include
// in the ccalls[] table, with fake call signatures "void xxx(void)".
// sdk_build/main/interface.c is compiled after the SDK configurator
// has run, so it can include whatever it needs.

extern void software_reset(void);
extern void ms(void);

cell ((* const ccalls[])()) = {
  C(build_date_adr)   //c 'build-date     { -- a.value }
  C(version_adr)      //c 'version        { -- a.value }
  C(ms)               //c ms              { i.ms -- }
  C(software_reset)   //c restart         { -- }
};
