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

SCOPE1 Reader input_file;
SCOPE1 int interact;

SCOPE1 int
isinteractive()
{
    return interact;
}

SCOPE1 void
title()
{
    System.out.print("C/Java Forth 93 ");
    // cprint("Version %I%");
    System.out.println(" Copyright (c) 1992 by Bradley Forthware");
}

SCOPE1 void
init_io()
{
    if (gargs_index >= gargs.length) {
        input_file = new InputStreamReader(System.in);
        interact = 1;
        title();
    } else {
        input_file = open_next_file();
    }
}

SCOPE1 void
emit(int c, int up)
{
    if ( c == '\n' || c == '\r' ) {
        V(NUM_OUT) = 0;
        V(NUM_LINE)++;
    } else
        V(NUM_OUT)++;
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
nextchar()
{
    try {
        return (int) input_file.read();
    }
    catch (IOException e) {
        return -1;
    }
}

SCOPE1 int
moreinput()
{
    return 1;
}

SCOPE1 int
caccept(int addr, int count, int up)
{
    int c;
    int p;
    
    // Uses the operating system's terminal driver to do the line editing
    for (p = addr; count > 0; count--) {
        c = nextchar();
        if (c == '\n' || c == -1) {
            break;
        }
        CHARS(p++) = c;
    }
    if (isinteractive() != 0) { 
        // We must do this because the terminal driver does the echoing,
        // and the 'return' that ends the line puts the cursor at column 0
        V(NUM_OUT) = 0;
    }

    return p - addr;
}

SCOPE1 void
name_input(String filename, int up)
{
    Reader file;
    try {
        file = new FileReader(filename);
        interact = 0;
        input_file = file;
    }
    catch (FileNotFoundException e) {
        System.err.println("Can't open " + filename);
    }
}

SCOPE1 int
key()
{
    try {
        return System.in.read();
    }
    catch (IOException e) {
        System.exit(1);
    }
    return -1;
}

SCOPE1 int key_avail() { return 0; }

SCOPE1 Reader
open_next_file()
{
    Reader file;
    String arg;

    while (gargs_index < gargs.length) {
        arg = gargs[gargs_index++];
        if ( arg == "-" ) {
            file = new InputStreamReader(System.in);
            interact = 1;
            return file;
        }
        if ( arg == "-s" ) {
            // XXX Check that there is a next string
            file = new StringReader(gargs[gargs_index++]);
            interact = 0;
            return file;
        }
        try {
            file = new FileReader(arg);
            interact = 0;
            return file;
        }
        catch (FileNotFoundException e) {
            System.err.println("Can't open " + arg);
        }
    }
    interact = 0;
    return (Reader) null;
}

SCOPE1 Object[] open_files = new Object[16];

SCOPE1 int
freadline(int f, int sp, int up)        // Returns IO result
{
    // Stack: adr len -- actual more?

    int adr = DS(sp+1);
    int len = DS(sp);
    Reader fd = (Reader)open_files[f];
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
    Closeable fd = (Closeable)open_files[f];

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
    Object file = null;

    i = 0;
    while (open_files[i] != null)
        if (++i == 16)
            return -1;

        switch (mode) {
        case 0:  
            try { file = new FileReader(fname); }
            catch (FileNotFoundException e) { }
            break;
        case 1:
            try { file = new FileWriter(fname); }
            catch (IOException e) { }
            break;
        case 2:
            try { file = new RandomAccessFile(fname, "rw"); }
            catch (FileNotFoundException e) { }
            break;
        case 3:
            try { file = new FileWriter(fname, true); }
            catch (IOException e) { }
            break;
        default:  file = null; break;
        }
    open_files[i] = file;
    return i;
}

SCOPE1 void
write_dictionary(int name, int len, int dictsize, int up, int usersize)
{
    DataOutputStream fd;
    String fname = altostr(name, len);

    try {
        fd = new DataOutputStream(new FileOutputStream(fname));

        fd.writeInt(MAGIC);
        fd.writeInt(0);
        fd.writeInt(0);
        fd.writeInt(dictsize);
        fd.writeInt(up);
        fd.writeInt(V(NUM_USER));
        fd.writeInt(0);
        fd.writeInt(0);

        for (int i=0; i < dictsize; i++)
            fd.writeInt(DATA(i));

        for (int i=0; i < V(NUM_USER); i++)
            fd.writeInt(V(i));

        fd.close();
    }
    catch (IOException e) {
        System.err.println("Error writing file " + fname);
    }
}
