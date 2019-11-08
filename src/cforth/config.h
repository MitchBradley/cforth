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

#include <stdint.h>

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

/*
 * Note: It is okay to define neither BSD nor SYSV.  The only result will
 * be that the word "key?" will always return false.  This is not a serious
 * problem; all of the utilities supplied with C Forth will still work.
 * The down side is that you won't be able to stop "words" by typing a key.
 */
/* Define BSD to make key? work right on 4.2BSD systems. */
/* #define BSD */

/* Define SYSV to make key? work right on System V systems */
/* #define SYSV */

#endif

#ifndef VMS
#define EXITSTATUS 0
#else
#define EXITSTATUS
/* Mods reported by Norman Smith */
#define system vms_system
#define chdir  vms_chdir
#endif

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

typedef uint8_t u_char;

/*
 * Both token_t and cell should be big enough to hold an absolute
 * address on your machine.  You will probably not need to change this,
 * assuming that you have set BITS32 appropriately.
 */
#if defined(BITS64) || defined(BITS32)
 typedef intptr_t cell;
 typedef uintptr_t u_cell;
 #ifdef T16
  typedef uint16_t token_t;
  typedef int16_t branch_t;
  typedef uint16_t unum_t;
 #else
  typedef uintptr_t token_t;
  typedef intptr_t branch_t;
  typedef uintptr_t unum_t;
 #endif
#else
 // 16-bit case, now largely uninteresting
 typedef unsigned int token_t;
 typedef int cell;
 typedef unsigned int unum_t;
 typedef int branch_t;
#endif

#if defined(BITS64)
 #define CELLBITS (64)
 typedef __int128_t double_cell_t;
 typedef __uint128_t u_double_cell_t;
#endif
#if defined(BITS32)
 #define CELLBITS (32)
 typedef long long double_cell_t;
 typedef unsigned long long u_double_cell_t;
#endif
#if defined(BITS16)
 #define CELLBITS (16)
 typedef __int32_t double_cell_t;
 typedef __uint32_t u_double_cell_t;
#endif
#ifndef CELLBITS
# error "BITS16, BITS32 or BITS64 not defined"
#endif

typedef token_t *xt_t;

#define ALIGN_BOUNDARY (sizeof(token_t))

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

#define TIBSIZE 132
#define PSSIZE 100
#define RSSIZE 100
#define CBUFSIZE 64

#define MAXVARS 0x300
#define MAXUSER (MAXVARS * sizeof(cell))

#if !defined(MAXDICT) && defined(T16)
  #define MAXDICT (0x1fffcL) /* The extent of token-space reach */
#endif

#ifndef MAXDICT
  #ifdef BITS64
    #define MAXDICT (0x80000L)
  #else
    #ifdef BITS32
      #define MAXDICT (0x60000L)
    #else
      #define MAXDICT (45000)
    #endif
  #endif
#endif

