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
#include "dictfile.h"

SCOPE1 int
isinteractive()
{
    return 1;
}

SCOPE1 void
title()
{
    System.out.print("C/Java Forth 93 ");
    // cprint("Version %I%");
    System.out.println(" Copyright (c) 1992 by Bradley Forthware");
}

SCOPE1 int cursor;

SCOPE1 void
init_io()
{
//    input_file = new InputStreamReader(System.in);
//
    cursor = 0;
    title();
}

SCOPE1 void
emit(int c, int up)
{
    char[] ch = new char[1];
    ch[0] = (char)c;
    if ( c == '\n' || c == '\r' ) {
        V(NUM_OUT) = 0;
        V(NUM_LINE)++;
    } else
        V(NUM_OUT)++;

    cmdLine.insert(ch, 0, 1, cursor);
    cursor++;
    System.out.print((char)c);
    System.out.flush();
}

SCOPE1 void
strerror(String s, int up)
{
    System.err.print(s);
    System.err.flush();
    // Sequences of calls to error() eventually end with a newline
    V(NUM_OUT) = 0;
}

SCOPE1 void
alerror(int adr, int len, int up)
{
    while (len > 0) {
        System.err.print((char)CHARS(adr++));
        len--;
    }
    System.err.println();
    V(NUM_OUT) = 0;
}

SCOPE1 int
moreinput()
{
    return 1;
}

SCOPE1 int accept_adr;
SCOPE1 int accept_len;

SCOPE1 int
caccept(int addr, int len, int up)
{
    System.out.flush();
    accept_adr = addr;
    accept_len = len;
    return -2;
}

SCOPE1 int
finish_accept()
{
    int len;
    int c;
    int i;
    int cmdmax;

    String text = cmdLine.getString();
    cmdmax = cmdLine.size();

    System.out.println(text);

    len = cmdmax - cursor;
//    cmdLine.delete(0, len);

    if (len > accept_len)
        len = accept_len;

    // Uses the operating system's terminal driver to do the line editing
    for (i = 0; i < len; i++) {
        c = text.charAt(cursor++);
        if (c == '\n' || c == -1) {
            break;
        }
        CHARS(accept_adr + i) = c;
    }
    cursor = cmdmax;
    emit('\n', up);
    if (isinteractive() != 0) { 
        // We must do this because the terminal driver does the echoing,
        // and the 'return' that ends the line puts the cursor at column 0
        V(NUM_OUT) = 0;
    }
	// Push the string length onto the stack as accept's return value
    spush(i, up);

    return inner_interpreter(up);
}

SCOPE1 int
key()
{
    return -1;
}

SCOPE1 int key_avail() { return 0; }

SCOPE1 InputStream[] open_files = new InputStream[16];

SCOPE1 int
freadline(int f, int sp, int up)        // Returns IO result
{
    // Stack: adr len -- actual more?

    int adr = DS(sp+1);
    int len = DS(sp);
    InputStream fd = open_files[f];
    int actual;
    int c;

    DS(sp) = -1;         // Assume not end of file

    for (actual = 0; actual < len; ) {
        try {
            c = fd.read();
        }
        catch (IOException e) {
            DS(sp+1) = actual;
            return -12;
        }
        if (c == -1) {
                if (actual == 0)
                    DS(sp) = 0;
                break;
        }
        if (c == CNEWLINE) {    // Last character of an end-of-line sequence
            break;
        }
        
        // Don't store the first half of a 2-character newline sequence
        if (c == '\r')
            continue;

        CHARS(adr++) = c;
//      printf("%c", c);
        ++actual;
    }
//    printf("\n");

    DS(sp+1) = actual;
    return(0);
}

SCOPE1 int
pfclose(int f, int up)
{
    InputStream fd = open_files[f];

    if (fd != null) {
        try {
            fd.close();
        }
        catch (IOException e) {
            System.err.println("Error closing file");
        }
        open_files[f] = null;
        return 0;
    }
    return 1;
}

SCOPE1 int
pfopen(int name, int len, int mode, int up)
{
    int i;
    String fname = altostr(name, len);
    InputStream file = null;

    i = 0;
    while (open_files[i] != null)
        if (++i == 16)
            return -1;

    try {
        switch (mode) {
        case 0:  file = getClass().getResourceAsStream(fname);  break;
        default:  file = null;
        }
    }
    catch (Exception e) {
        file = null;
    }

    if (file == null)
        return -1;

    open_files[i] = file;
    return i;
}

SCOPE1 void
write_dictionary(int name, int len, int dictsize, int up, int usersize)
{
}
