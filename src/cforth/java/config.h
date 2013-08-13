/* config.h 1.7 93/11/03 */

/*
 * This file contains definitions which configure C Forth 83 for specific
 * processors, operating systems, compilers, and memory models.
 *
 * IMPORTANT NOTE: The preferred place to set the basic configuration
 * parameters (the OS name and the number of bits) is in the Makefile
 * for the particular machine.  However, some C development systems
 * don't have "make", and some C compilers don't allow defines (-D)
 * on the command line.  Consequently, it may be necessary to edit this
 * file to enable the appropriate #defines.
 */

/*
 * Select the operating system.  Usually, this is set by the Makefile.
 */
/* #define UNIX */
/* #define WIN32 */

#ifdef WIN32
#define inline __inline
#endif

/*
 * If ALLOCDICT is defined, the space for the Forth dictionary will
 * be dynamically allocated at startup time.  Otherwise, the dictionary
 * will be a static array in the BSS section of the program.
 * On a system where the BSS does not take up space in the program
 * file (e.g. Unix), it is often better to leave ALLOCDICT undefined.
 * On a system where the BSS occupies file space (e.g. DOS), it is
 * often better to define ALLOCDICT.
 */
/* #define ALLOCDICT */

#ifdef UNIX

/* Define SIGNALS to catch Unix signals (keyboard interrupts, errors, etc) */
/* If left undefined, signals will cause the Forth process to terminate */
#define SIGNALS

#endif

#define EXITSTATUS 0

#define INIT_FILENAME  "init.x"

/*
 * DEFAULT_EXE is the name of the default dictionary file.
 * This file is created by the build procedure after the extensions are
 * loaded.  New dictionary files are produced by the SAVE-FORTH command.
 *
 * You can add a path specification to this if you wish,
 * so that forth can be started from any working directory.
 */

#define	DEFAULT_EXE "forth.dic"

#define cell int
#ifdef T16
#else
#endif

/*
 * SNEWLINE is the end-of-line sequence for the operating system's files.
 * CNEWLINE is the LAST character in the end-of-line sequence
 */
#ifdef UNIX
#define SNEWLINE "\n"	/* Unix */
#define CNEWLINE '\n'
#endif

#ifdef MAC
#define SNEWLINE "\r"	/* MAC, OS-9, UNIFLEX, ... */
#define CNEWLINE '\r'
#endif

#ifndef SNEWLINE
#define SNEWLINE "\r\n"	/* MS-DOS, RT-11, VMS? */
#define CNEWLINE '\n'
#endif

#define READ_MODE   0
#define WRITE_MODE  1
#define MODIFY_MODE 2
#define CREATE_MODIFY_MODE 3

#define TIBSIZE 132
#define PSSIZE 100
#define RSSIZE 100
#define CBUFSIZE 64

#define MAXVARS 0x200
#define MAXUSER MAXVARS*1

#ifndef MAXDICT
#define MAXDICT 20000
#endif
