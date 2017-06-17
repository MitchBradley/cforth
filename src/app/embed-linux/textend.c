// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include "forth.h"

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

// Prototypes
//int msticks(void);

cell ((* const ccalls[])()) = {
	C(build_date_adr)       //c 'build-date     { -- a.value }
	C(version_adr)          //c 'version        { -- a.value }
  //	C(msticks)               //c get-msecs  { -- i.ms }
};
