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

#define _POSIX_C_SOURCE 1

#include <setjmp.h>
#include <signal.h>

#ifdef WIN32
#define sigsetjmp(jb,s) setjmp(jb)
#define siglongjmp(jb,v) longjmp(jb,v)
#define sigjmp_buf jmp_buf
#endif

sigjmp_buf jmp_buffer;
// jmp_buf jmp_buffer;
void signal_handler(int sig) {
//    longjmp(jmp_buffer, sig);
     siglongjmp(jmp_buffer, sig);
}

main(int argc, char **argv)
{
    int retval;
    cell *up;
    int caught;

    up = prepare_dictionary(&argc, &argv);
    init_io(argc, argv, up);
    (void)signal(SIGFPE, signal_handler);
    (void)signal(SIGILL, signal_handler);
    (void)signal(SIGSEGV, signal_handler);
    if ((caught = sigsetjmp(jmp_buffer, 1)) != 0) {
//    if ((caught = setjmp(jmp_buffer)) != 0) {
	switch (caught)
	{
	case SIGFPE:  FTHERROR("Numeric exception\n");   break;
	case SIGILL:  FTHERROR("Illegal instruction\n"); break;
	case SIGSEGV: FTHERROR("Address exception\n");   break;
	}
	(void)signal(caught, signal_handler);
    }
    retval = execute_word("quit", up);
    restoremode();
    // -1 is the return value for "bye"; map it to 0 process exit status
    exit(retval == -1 ? 0 : retval);
}
