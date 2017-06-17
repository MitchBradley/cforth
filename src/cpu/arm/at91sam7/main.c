// Top-level routine for calling the Forth interpreter
// Defines a few serial I/O interface functions and main()

static int pending_char;

int kbhit() {
    unsigned char byte;
    if (pending_char) {
        return 1;
    }
    if (dbgu_mayget(&byte)) {
        pending_char = byte+1;
        return 1;
    }
    return 0;
}

int getkey()
{
    int retval;
    if (pending_char) {
        retval = pending_char-1;
        pending_char = 0;
        return retval;
    }

    return ((int)ukey()) & 0xff;
}

main()
{
    void *up;

    init_io();
    up = init_forth();
    execute_word("run-tests", up);  // Call the top-level application word
    reset();
}
