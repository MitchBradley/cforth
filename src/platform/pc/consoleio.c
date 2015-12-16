// Character I/O

#include "io.h"

void tx(char c)
{
    // send the character to the console output device
    while ((inb(0x3fd) & 0x20) == 0)
        ;
    outb(c, 0x3f8);
}

void putchar(char c)
{
    if (c == '\n')
        tx('\r');
    tx(c);
}

int kbhit() {
    // return 1 if a character is available, 0 if not
    return (inb(0x3fd) & 1) != 0;
}

int getkey()
{
    // return the next character from the console input device
    while (!kbhit())
        ;
    return inb(0x3f8);
}
