// I/O subroutines for C Forth 93.
// This code mostly uses C standard I/O, so it should work on most systems.
//
// Exported definitions:
//
// init_io(argc,argv);		Initialize io system
// emit(char, up);			Output a character
// n = key_avail();		How many characters can be read?
// error(s, up);			Print a string on the error stream
// n = caccept(addr, count);	Collect a line of input
// char = key();		Get the next input character
// name_input(filename);		    

#include "forth.h"
#include <stdio.h>

extern int key();
extern void exit();
extern FILE *fopen();

FILE *input_file;
FILE *output_file;
FILE *open_next_file();

int gargc;
char **gargv;

int isinteractive()
{
    return (input_file == stdin);
}

void title(int up)
{
    cprint("C Forth 93 ", up);
    // cprint("Version %I%");
    cprint(" Copyright (c) 1992 by Bradley Forthware\n", up);
}

void init_io(int argc, char **argv, int up)
{
    gargc = argc; gargv = argv;

    output_file = stdout;

    if (gargc <= 1) {
        input_file = stdin;
        title(up);
    } else {
        input_file = open_next_file();
    }
    if (input_file == (FILE *)0) {
        ERROR("No input stream\n");
        exit(1);
    }
}

void emit(char c, int up)
{
    if ( c == '\n' || c == '\r' ) {
        V(NUM_OUT) = 0;
        V(NUM_LINE)++;
    } else
        V(NUM_OUT)++;
    if (output_file)
        (void)putc((char)c, output_file);
}

void cprint(const char *str, int up)
{
    while (*str)
        emit(*str++, up);
    (void)fflush(output_file);
}

void strerror(char *s, int up)
{
    (void)fputs(s, stderr);
    (void)fflush(stderr);
    // Sequences of calls to error() eventually end with a newline
    V(NUM_OUT) = 0;
}

void alerror(int adr, int len, int up)
{
    char cstrbuf[32];

    (void)strerror(altostr(adr, len, cstrbuf, 32), up);
}

#define STRINGINPUT (FILE *) -1
char *strptr;

int
nextchar()
{
    register int c;

    if ( input_file == STRINGINPUT ) {
        if( (c = *strptr) != '\0') {
            strptr++;
            return (c);
        }
        return (EOF);
    }

    return(getc(input_file));
}

int
moreinput()
{
    if ( input_file == STRINGINPUT )
        return (*strptr != '\0');

    return (!feof(input_file));
}

int
caccept(int addr, cell count, int up)
{
    int c;
    int p;
    
    if (isinteractive()) {
        linemode();
    }

    // Uses the operating system's terminal driver to do the line editing
    for (p = addr; count > 0; count--) {
        c = nextchar();
        if (c == '\n' || c == EOF) {
            break;
        }
        CHARS(p++) = c;
    }
    if (isinteractive()) {
        // We must do this because the terminal driver does the echoing,
        // and the 'return' that ends the line puts the cursor at column 0
        V(NUM_OUT) = 0;
    }

    return ((cell)(p - addr));
}

name_input(char *filename, int up)
{
    FILE *file;

    if ((file = fopen(filename, "r")) == (FILE *)0) {
        file_error("Can't open ", filename, up);
    } else {
        input_file = file;
    }
}

file_error(char *str, char *filename, int up)
{
    extern int strlen(const char *);

    strerror(str, up);
    strerror(filename, up);
    ERROR("\n");
}

int
key()
{
    keymode();
    return(getc(stdin));
}

int key_avail() { return 0; }

FILE *
open_next_file(int up)
{
    register FILE * file;

    while (--gargc > 0) {
        if ( (*++gargv)[0]=='-' ) {
            if ((*gargv)[1]=='\0') {
                return(stdin);
            } else if ((*gargv)[1] == 's') {
                char *p;

                ++gargv; --gargc;
                strptr = *gargv;
                return(STRINGINPUT);
            } else {
                file_error("Unknown flag ",*gargv, up);
            }
        }
        else {
            if ((file = fopen(*gargv, "r")) == (FILE *)0) {
                file_error("Can't open ",*gargv, up);
                continue;
            } else {
                return(file);
            }
        }
    }
    return((FILE *)0);
}

cell
freadline(cell f, int sp, int up)        // Returns IO result
{
    // Stack: adr len -- actual more?

    int adr = DS(sp+1);
    cell len = DS(sp);

    cell actual;
    int c;

    DS(sp) = -1;         // Assume not end of file

    for (actual = 0; actual < len; ) {
        if ((c = getc((FILE *)f)) == EOF) {
            if (actual == 0)
                DS(sp) = 0;

            if (ferror((FILE *)f)) {
                DS(sp+1) = actual;
                return(-12);
            }
            break;
        }
        if (c == CNEWLINE) {    // Last character of an end-of-line sequence
            break;
        }
        
        // Don't store the first half of a 2-character newline sequence
        if (c == SNEWLINE[0])
            continue;

        CHARS(adr++) = c;
//      printf("%c", c);
        ++actual;
    }
//    printf("\n");


    DS(sp+1) = actual;
    return(0);
}

cell
pfclose(cell f)
{
    return( (cell)fclose((FILE *)f) );
}

cell
pfopen(int name, int len, int mode)
{
    char cstrbuf[512];
    char *modes[] = { "rb", "wb", "rb+", "wb+"};

    if (mode > 3)
        return 0;

    return( (cell)fopen(altostr(name, len, cstrbuf, 512), modes[mode]) );
}
