// Top-level routine for starting Forth

main()
{
    void *up;

    init_io();   // Perform platform-specific initialization

    up = (void *)init_forth();
    execute_word("app", up);  // Call the top-level application word
//    execute_word("quit", up);  // Call the Forth text interpreter
}
