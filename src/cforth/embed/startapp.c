// Copyright 1997 FirmWorks  All Rights Reserved

#include "forth.h"

// Implements entry points whereby an enclosing application
// can initialize and invoke the Forth application

cell *
init_forth()
{
    extern cell *prepare_builtin_dictionary(int);
    cell *up;
    up = prepare_builtin_dictionary(MAXDICT);
    return up;
}

// After Forth has been initialized, you can run a given Forth
// word with, e.g. execute_word("quit")
