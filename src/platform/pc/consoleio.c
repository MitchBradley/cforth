// Character I/O

#include "io.h"

void raw_putchar(char c)
{
    // send the character to the console output device
    while ((inb(0x3fd) & 0x20) == 0)
        ;
    outb(c, 0x3f8);
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
