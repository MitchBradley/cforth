// Top-level routine for starting Forth

#include "forth.h"

cell *callback_up;

// Defines startup routine for nodemcu-firmware
void lua_main()
{
    init_io(0, (char **)0, (cell *)callback_up);   // Perform platform-specific initialization

    callback_up = (void *)init_forth();
    execute_word("app", callback_up);  // Call the top-level application word

    //execute_word("quit", up);  // Call the Forth text interpreter
}
