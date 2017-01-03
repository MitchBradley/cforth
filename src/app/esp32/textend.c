// Forth interfaces to platform-specific C routines
// See "ccalls" below.

#include "forth.h"
#include "freertos/FreeRTOS.h"

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

void ms(cell msecs)
{
    vTaskDelay(msecs/ portTICK_PERIOD_MS);
}

extern void software_reset(void);

cell ((* const ccalls[])()) = {
  C(build_date_adr)   //c 'build-date     { -- a.value }
  C(version_adr)      //c 'version        { -- a.value }
  C(ms)               //c ms              { i.ms -- }
  C(software_reset)   //c restart         { -- }
};
