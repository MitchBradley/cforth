// Top-level routine for starting Forth

#include "forth.h"
#include "compiler.h"

// Defines startup routine
void forth(void)
{
    cell *up;
    init_io(0, (char **)0, (cell *)up);   // Perform platform-specific initialization

    up = (void *)init_forth();
    execute_word("app", up);  // Call the top-level application word
}
