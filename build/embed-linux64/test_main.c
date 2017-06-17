#include <stdio.h>

void raw_putchar(char c) { putchar(c); fflush(stdout); }
int kbhit(void) { return 0; }
int getkey(void) { return getchar(); }

main() {
  forth();
}
