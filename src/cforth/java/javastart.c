#include "forth.h"
#include "dictfile.h"

import java.io.*;

public class forth {

SCOPE1 String[] gargs;
SCOPE1 int gargs_index;

SCOPE1 int up;
SCOPE1 int[] word_dict;

public static void main(String[] args) {
    forth in = new forth(args);
    in.execute_word("quit");
}

public forth(String[] args) {
    gargs = args;
    gargs_index = 0;

    up = prepare_dictionary();
    init_io();
}

SCOPE1 int
prepare_dictionary()
{
    int here;
    int xlimit;
    int[] variables;

    word_dict = new int[MAXDICT];
    variables = new int[MAXVARS];

    String dictionary_file = "";

    xlimit = MAXDICT;
    gargs_index = 1;

    if ( gargs_index < gargs.length  &&  gargs[gargs_index].endsWith(".dic") ) {
        dictionary_file = gargs[gargs_index];
        ++gargs_index;
    } else {
        dictionary_file = DEFAULT_EXE;
    }

    here = read_dictionary(dictionary_file, variables);

    if (here == 0)
        return 0;

    return init_compiler(here, xlimit, variables);
}

SCOPE1 int
read_dictionary(String fname, IntArray variables)
{
    DataInputStream fd;
    int here;
    int usize;

    try {
        fd = new DataInputStream(new FileInputStream(fname));
    }
    catch (FileNotFoundException e) {
        System.err.println("Can't open dictionary file " + fname);
        return 0;
    }

    try {
        if (fd.readInt() != MAGIC) {
            System.err.println("Bad magic number in dictionary file " + fname);
            return 0;
        }

        fd.readInt();  // Unused field
        fd.readInt();  // Unused field
         
        here  = fd.readInt();
        up    = fd.readInt();
        usize = fd.readInt();

        fd.readInt();  // Unused field
        fd.readInt();  // Unused field

        for (int i = 0; i < here; i++)
            DATA(i) = fd.readInt();

        for (int i = 0; i < usize; i++)
            variables[i] = fd.readInt();

        fd.close();
    }
    catch (IOException e) {
        return 0;
    }

    return here;
}

// public

