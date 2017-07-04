// Top-level routine for starting Forth

main()
{
    void *up;

    init_uart();
    init_io();   // Perform platform-specific initialization

    up = (void *)init_forth();
    execute_word("app", up);  // Call the top-level application word
    restart(); // On bye, restart rather than hang
}
