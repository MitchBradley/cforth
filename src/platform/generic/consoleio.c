// Character I/O stubs

void tx(char c)
{
    // send the character to the console output device
}

void putchar(char c)
{
    if (c == '\n')
        tx('\r');
    tx(c);
}

int kbhit() {
    // return 1 if a character is available, 0 if not
    return 0;
}

int getchar()
{
    // return the next character from the console input device
    return 'a';
}
