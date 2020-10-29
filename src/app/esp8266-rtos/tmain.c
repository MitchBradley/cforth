// Top-level routine for starting Forth

#include "forth.h"
#include "compiler.h"

cell *callback_up;

// Defines startup routine for nodemcu-firmware
void forth()
{
    init_io(0, (char **)0, (cell *)callback_up);   // Perform platform-specific initialization
    callback_up = (void *)init_forth();
    execute_word("app", callback_up);  // Call the top-level application word
}
