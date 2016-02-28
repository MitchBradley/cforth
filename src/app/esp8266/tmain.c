// Top-level routine for starting Forth

void *callback_up;

void lua_main()
{
    init_io();   // Perform platform-specific initialization

    callback_up = (void *)init_forth();
    execute_word("app", callback_up);  // Call the top-level application word

    //execute_word("quit", up);  // Call the Forth text interpreter
}
