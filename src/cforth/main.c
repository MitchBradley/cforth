/*
 * C Forth
 * Copyright (c) 2008 FirmWorks
 */

/*
 * This file contains the main() routine for the C Forth 93 system.
 * It is used when C Forth 93 is a self-contained application, and
 * omitted when C Forth 93 is embedded within another application.

 * To embed Forth in another application, omit this file, and in your
 * application, call init_forth(&argv, &argc) to initialize the Forth
 * environment, then call inner_interpreter() with a pointer to a
 * synthetic colon definition, along the lines of cold_def[] below,
 * that executes your application code.
 */

#include "forth.h"
#include "prims.h"

extern void exit(int);

/*
 * 'quit' is the (poorly-named) standard Forth word that clears the stacks
 * and invokes the interactive interpreter.  It is so named because executing
 * it from inside an arbitrary Forth program will cause the execution of
 * that program to cease, returning control back to the user at the Forth
 * prompt.
 */

extern cell *prepare_dictionary(int *argcp, char *(*argvp[]));

main(int argc, char **argv)
{
    int retval;
    cell *up;

    up = prepare_dictionary(&argc, &argv);
    init_io(argc, argv, up);
    retval = execute_word("quit", up);
    restoremode();
    // -1 is the return value for "bye"; map it to 0 process exit status
    exit(retval == -1 ? 0 : retval);
}
