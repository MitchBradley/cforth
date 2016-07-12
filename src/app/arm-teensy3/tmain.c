// Top-level routine for starting Forth

#include "forth.h"
#include "compiler.h"

#ifdef STANDALONE
void main()
#else
void cforth()
#endif
{
    cell *up;

    init_io(0, (char **)0, up);   // Perform platform-specific initialization

    up = init_forth();
    (void)execute_word("app", up);  // Call the top-level application word
//    execute_word("quit", up);  // Call the Forth text interpreter
}
