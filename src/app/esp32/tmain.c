// Top-level routine for starting Forth

#include "forth.h"
#include "esp_system.h"
#include "nvs_flash.h"


// Defines startup routine for nodemcu-firmware
void app_main(void)
{
    nvs_flash_init();

    cell *up;
    init_io(0, (char **)0, (cell *)up);   // Perform platform-specific initialization
    up = (void *)init_forth();
    execute_word("app", up);  // Call the top-level application word
}
