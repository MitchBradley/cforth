// Copyright 1997 FirmWorks  All Rights Reserved

// Implements entry points whereby an enclosing application
// can initialize and invoke the Forth application

void *
init_forth()
{
    extern void *prepare_builtin_dictionary(int);
    void *up;
    up = prepare_builtin_dictionary(MAXDICT);
    title(up);
    return up;
}

// After Forth has been initialized, you can run a given Forth
// word with, e.g. execute_word("quit")
